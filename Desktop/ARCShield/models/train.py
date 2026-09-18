"""
ARCShield: XGBoost / LightGBM Training Pipeline
Trains the Bidirectional Transaction Guard risk model on synthetic labeled data.

Usage:
    python -m models.train --output models/artifacts/bgt_risk_model.json
"""

import os
import json
import numpy as np
from datetime import datetime, timezone
from typing import Dict, Any, List, Tuple

# Feature columns used by the model (must match pipeline.py output)
FEATURE_COLUMNS = [
    # Outgoing features
    "amount_zscore",
    "device_novelty",
    "recipient_novelty",
    "new_device_before_transfer",
    "credential_change_before_transfer",
    "escalating_amounts",
    "urgent_request",
    "safe_account_claim",
    "threshold_avoidance_score",
    # Incoming features
    "direction_incoming",
    "sender_seen_before",
    "pass_through_ratio",
    "fan_in_ratio",
    "fan_out_ratio",
    "dormancy_break_score",
    "inflow_vs_normal_ratio",
    # Graph features
    "complaint_proximity_hops",
    "shared_device_count",
    "connected_flagged_accounts",
    "component_size",
]


def generate_synthetic_training_data(n_samples: int = 10000, fraud_ratio: float = 0.08) -> Tuple[np.ndarray, np.ndarray]:
    """
    Generates synthetic training data matching the feature schema.
    In production, this would pull from the /generator output + Supabase.
    
    Returns:
        X: Feature matrix (n_samples, n_features)
        y: Binary labels (0 = legitimate, 1 = fraud)
    """
    np.random.seed(42)
    n_fraud = int(n_samples * fraud_ratio)
    n_legit = n_samples - n_fraud

    # --- Legitimate transactions ---
    legit = np.zeros((n_legit, len(FEATURE_COLUMNS)))
    legit[:, 0] = np.random.normal(0.0, 0.5, n_legit)       # amount_zscore: small deviations
    legit[:, 1] = np.random.binomial(1, 0.05, n_legit)       # device_novelty: rarely new
    legit[:, 2] = np.random.binomial(1, 0.10, n_legit)       # recipient_novelty
    legit[:, 3] = np.zeros(n_legit)                           # new_device_before_transfer
    legit[:, 4] = np.zeros(n_legit)                           # credential_change
    legit[:, 5] = np.zeros(n_legit)                           # escalating_amounts
    legit[:, 6] = np.zeros(n_legit)                           # urgent_request
    legit[:, 7] = np.zeros(n_legit)                           # safe_account_claim
    legit[:, 8] = np.random.uniform(0.0, 0.1, n_legit)       # threshold_avoidance
    legit[:, 9] = np.random.binomial(1, 0.5, n_legit)        # direction_incoming
    legit[:, 10] = np.ones(n_legit)                           # sender_seen_before: known
    legit[:, 11] = np.random.uniform(0.0, 0.1, n_legit)      # pass_through_ratio
    legit[:, 12] = np.random.uniform(0.0, 0.2, n_legit)      # fan_in_ratio
    legit[:, 13] = np.random.uniform(0.0, 0.2, n_legit)      # fan_out_ratio
    legit[:, 14] = np.zeros(n_legit)                          # dormancy_break
    legit[:, 15] = np.random.uniform(0.8, 1.2, n_legit)      # inflow_vs_normal
    legit[:, 16] = np.full(n_legit, 99)                       # complaint_proximity: far
    legit[:, 17] = np.zeros(n_legit)                          # shared_device_count
    legit[:, 18] = np.zeros(n_legit)                          # connected_flagged
    legit[:, 19] = np.random.randint(1, 5, n_legit)           # component_size: small

    # --- Fraudulent transactions ---
    fraud = np.zeros((n_fraud, len(FEATURE_COLUMNS)))
    fraud[:, 0] = np.random.normal(3.0, 1.5, n_fraud)        # amount_zscore: large deviations
    fraud[:, 1] = np.random.binomial(1, 0.65, n_fraud)        # device_novelty: often new
    fraud[:, 2] = np.random.binomial(1, 0.70, n_fraud)        # recipient_novelty
    fraud[:, 3] = np.random.binomial(1, 0.45, n_fraud)        # new_device_before_transfer
    fraud[:, 4] = np.random.binomial(1, 0.35, n_fraud)        # credential_change
    fraud[:, 5] = np.random.binomial(1, 0.40, n_fraud)        # escalating_amounts
    fraud[:, 6] = np.random.binomial(1, 0.50, n_fraud)        # urgent_request
    fraud[:, 7] = np.random.binomial(1, 0.30, n_fraud)        # safe_account_claim
    fraud[:, 8] = np.random.uniform(0.5, 1.0, n_fraud)        # threshold_avoidance
    fraud[:, 9] = np.random.binomial(1, 0.6, n_fraud)         # direction_incoming
    fraud[:, 10] = np.random.binomial(1, 0.15, n_fraud)       # sender_seen_before: usually NOT
    fraud[:, 11] = np.random.uniform(0.6, 1.0, n_fraud)       # pass_through_ratio: high
    fraud[:, 12] = np.random.uniform(0.5, 1.0, n_fraud)       # fan_in_ratio: high
    fraud[:, 13] = np.random.uniform(0.5, 1.0, n_fraud)       # fan_out_ratio: high
    fraud[:, 14] = np.random.binomial(1, 0.40, n_fraud)       # dormancy_break
    fraud[:, 15] = np.random.uniform(3.0, 10.0, n_fraud)      # inflow_vs_normal: spike
    fraud[:, 16] = np.random.choice([1, 2, 3], n_fraud, p=[0.4, 0.35, 0.25])  # complaint hops
    fraud[:, 17] = np.random.randint(1, 4, n_fraud)           # shared_device_count
    fraud[:, 18] = np.random.randint(1, 5, n_fraud)           # connected_flagged
    fraud[:, 19] = np.random.randint(10, 50, n_fraud)         # component_size: large clusters

    X = np.vstack([legit, fraud])
    y = np.concatenate([np.zeros(n_legit), np.ones(n_fraud)])

    # Shuffle
    idx = np.random.permutation(len(y))
    return X[idx], y[idx]


def train_model(output_dir: str = "models/artifacts"):
    """
    Train the XGBoost risk model and save artifacts.
    Falls back to a simple logistic baseline if XGBoost is not installed.
    """
    os.makedirs(output_dir, exist_ok=True)
    X, y = generate_synthetic_training_data(n_samples=10000)

    print(f"Training data: {X.shape[0]} samples, {X.shape[1]} features")
    print(f"Fraud ratio: {y.mean():.2%}")

    model_type = "xgboost"
    model = None
    metrics = {}

    try:
        import xgboost as xgb
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import (
            classification_report,
            precision_recall_curve,
            auc,
        )

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        dtrain = xgb.DMatrix(X_train, label=y_train, feature_names=FEATURE_COLUMNS)
        dtest = xgb.DMatrix(X_test, label=y_test, feature_names=FEATURE_COLUMNS)

        params = {
            "objective": "binary:logistic",
            "eval_metric": ["logloss", "aucpr"],
            "max_depth": 6,
            "learning_rate": 0.1,
            "subsample": 0.8,
            "colsample_bytree": 0.8,
            "min_child_weight": 3,
            "scale_pos_weight": (1 - y_train.mean()) / y_train.mean(),
            "seed": 42,
        }

        model = xgb.train(
            params,
            dtrain,
            num_boost_round=200,
            evals=[(dtrain, "train"), (dtest, "eval")],
            early_stopping_rounds=20,
            verbose_eval=25,
        )

        # Save XGBoost model
        model_path = os.path.join(output_dir, "bgt_risk_model.json")
        model.save_model(model_path)
        print(f"\n✅ Model saved to: {model_path}")

        # Evaluation
        y_pred_proba = model.predict(dtest)
        precision, recall, _ = precision_recall_curve(y_test, y_pred_proba)
        pr_auc = auc(recall, precision)

        y_pred = (y_pred_proba >= 0.5).astype(int)
        report = classification_report(y_test, y_pred, output_dict=True)

        metrics = {
            "pr_auc": round(pr_auc, 4),
            "precision_fraud": round(report["1.0"]["precision"], 4),
            "recall_fraud": round(report["1.0"]["recall"], 4),
            "f1_fraud": round(report["1.0"]["f1-score"], 4),
            "fp_rate_normal": round(1 - report["0.0"]["precision"], 4),
        }

        print(f"\n📊 PR-AUC: {pr_auc:.4f}")
        print(f"   Fraud Precision: {metrics['precision_fraud']:.4f}")
        print(f"   Fraud Recall: {metrics['recall_fraud']:.4f}")
        print(f"   FP Rate on Normal: {metrics['fp_rate_normal']:.4f}")

    except ImportError:
        print("[WARN] xgboost/sklearn not installed. Training with logistic baseline.")
        model_type = "logistic_baseline"

        # Simple logistic regression fallback
        weights = np.zeros(len(FEATURE_COLUMNS))
        weights[0] = 0.15   # amount_zscore
        weights[1] = 0.18   # device_novelty
        weights[3] = 0.25   # new_device_before
        weights[7] = 0.45   # safe_account_claim
        weights[8] = 0.35   # threshold_avoidance
        weights[11] = 0.30  # pass_through_ratio

        baseline = {"weights": weights.tolist(), "feature_names": FEATURE_COLUMNS}
        baseline_path = os.path.join(output_dir, "bgt_risk_baseline.json")
        with open(baseline_path, "w") as f:
            json.dump(baseline, f, indent=2)
        print(f"✅ Baseline model saved to: {baseline_path}")

        metrics = {"model_type": "logistic_baseline", "note": "Install xgboost for full training."}

    # Save training metadata
    metadata = {
        "model_version": "bgt-risk-1.4.0",
        "model_type": model_type,
        "feature_columns": FEATURE_COLUMNS,
        "n_features": len(FEATURE_COLUMNS),
        "n_training_samples": int(X.shape[0]),
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "metrics": metrics,
    }
    metadata_path = os.path.join(output_dir, "training_metadata.json")
    with open(metadata_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"📄 Metadata saved to: {metadata_path}")

    return metadata


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Train ARCShield risk model")
    parser.add_argument("--output", default="models/artifacts", help="Output directory")
    parser.add_argument("--samples", type=int, default=10000, help="Number of training samples")
    args = parser.parse_args()
    train_model(output_dir=args.output)
