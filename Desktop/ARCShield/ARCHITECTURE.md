# Bidirectional Transaction Guard — Architecture

Companion to `PRD.md`. This document covers system structure, data model, feature engineering, scoring, ledger semantics, security, deployment and the build order.

---

## 1. System overview

```
┌──────────────────────┐
│ Synthetic World      │   users, accounts, devices, sessions,
│ Generator            │   merchants, complaints, seeded fraud rings
└──────────┬───────────┘
           │ transactions + account events
           ▼
┌──────────────────────┐
│ Ingestion API        │   validate → persist → emit for scoring
│ (FastAPI)            │
└──────────┬───────────┘
           │
   ┌───────┴────────┐
   ▼                ▼
┌────────────┐  ┌────────────┐
│ Outgoing   │  │ Incoming   │   direction-specific feature builders
│ Features   │  │ Features   │
└─────┬──────┘  └─────┬──────┘
      └────────┬───────┘
               ▼
      ┌──────────────────┐
      │ Graph Service    │   NetworkX; compact features only
      └────────┬─────────┘
               ▼
      ┌──────────────────┐        ┌──────────────────┐
      │ ML Risk Model    │───────▶│ SHAP Explainer   │
      │ XGBoost/LightGBM │        └────────┬─────────┘
      └────────┬─────────┘                 │
               │      ┌──────────────────┐ │
               │      │ Deterministic    │ │
               │      │ Rule Engine      │ │
               │      └────────┬─────────┘ │
               └───────┬───────┴───────────┘
                       ▼
              ┌──────────────────┐
              │ Risk Fusion      │  band + ordered reason codes
              └────────┬─────────┘
                       ▼
        ALLOW      CHALLENGE        HIGH
          │            │              │
          │            ▼              ▼
          │      Mobile prompt   Hold / Quarantine
          │                           │
          │                           ▼
          │                      Case creation
          └────────────┬──────────────┘
                       ▼
        ┌────────────────────────────────┐
        │ Supabase: Postgres, Auth, RLS, │
        │ audit triggers, Realtime       │
        └───────┬───────────────┬────────┘
                ▼               ▼
      React analyst        Flutter app
        dashboard          (FCM push)
```

Two independent services sit beside the main pipeline: the **Inter-bank Intelligence Service** (hashed indicator exchange, F-28) and the **Federated Coordinator** (F-29).

---

## 2. Components

| Component | Technology | Responsibility |
|---|---|---|
| World generator | Python | Produces the entire simulated economy, including labelled fraud |
| Ingestion + scoring API | FastAPI | One synchronous scoring endpoint plus action endpoints |
| Feature builders | Python | Direction-specific feature vectors from history and events |
| Graph service | NetworkX | Maintains the entity graph, extracts compact features, returns subgraphs as evidence |
| Risk model | XGBoost or LightGBM | Single gradient-boosted classifier over all feature families |
| Explainer | SHAP (TreeExplainer) | Per-prediction feature contributions |
| Rule engine | Python | Velocity, structuring, coercion, pass-through, quarantine conditions, refund bait |
| Fusion engine | Python | Combines model probability, rule fires and hard overrides into a band and ordered reason codes |
| Ledger service | Postgres functions | Available / held / total balance; all balance changes are transactional |
| Data platform | Supabase | Postgres, Auth, RLS, audit triggers, Realtime |
| Analyst UI | React + TypeScript | Alert feed, investigation, graph view, counterfactual slider, cases, monitoring |
| User app | Flutter + FCM | Alerts, coercion prompts, quarantine actions |
| Intelligence service | FastAPI | Salted-hash indicator exchange between three virtual banks |
| Federated coordinator | Python | Collects, averages and redistributes local model parameters |

---

## 3. Why the generator comes first

Every distinctive feature in this system needs sender identity, recipient identity, device, session, location, beneficiary history and complaint records. The commonly used public card-fraud dataset is PCA-anonymised numeric columns with none of that. Building on it would make most of this document unimplementable.

The generator must produce:

- **A population.** Accounts with archetypes: salaried, student, small merchant, retiree, gig worker. Each archetype implies an inflow rhythm, a transaction size distribution, active hours and a merchant mix.
- **A device and session layer.** Devices bound to accounts, occasionally shared legitimately (family), and deliberately shared illegitimately by fraud rings.
- **Normal traffic.** Months of it, so rolling baselines are meaningful and cold-start is a real condition to handle rather than a hidden assumption.
- **Seeded fraud, labelled at the event level:** an account-takeover chain, an APP/manipulation case, a structuring attempt, a mule ring with fan-in/fan-out and pass-through, a dormant account reactivated as a mule, a refund-bait pair.
- **A complaint store.** Victim complaints naming accounts, devices and identifiers, so complaint proximity has something to path toward.

Labels must be at event level, not transaction level, or F-02 and F-12 cannot be trained or evaluated.

Make the generator deterministic under a seed. Reproducible demos matter more than variety.

---

## 4. Data model

Core tables:

```
users                accounts             devices
sessions             identifiers          merchants
beneficiaries        beneficiary_trust
transactions         account_events
graph_entities       graph_edges
risk_scores          risk_reasons
alerts               user_actions
quarantine_holds     ledger_entries
complaints           flagged_entities
cases                case_evidence
audit_logs           model_versions
user_feedback        bank_intelligence
federated_rounds
```

Key relationships:

```
accounts ──┬── transactions (as sender_account / receiver_account)
           ├── devices, sessions, beneficiaries
           ├── account_events
           ├── alerts, quarantine_holds
           └── cases

transactions ──┬── risk_scores ── risk_reasons
               ├── ledger_entries
               └── case (nullable)

cases ──┬── case_evidence (transaction, subgraph snapshot, events, user actions)
        └── audit_logs
```

Modelling decisions worth locking now:

- `risk_band`, `transaction_status`, `case_status`, `direction` and `role` are Postgres **enums**, not free text.
- `transactions` carries `updated_at`, maintained by trigger.
- `risk_reasons` is a child table with an ordinal, so reason order is data rather than presentation logic.
- `ledger_entries` is append-only and double-entry. Balances are derived or maintained transactionally, never patched by application code.
- `audit_logs` is insert-only, enforced by RLS and by revoking update and delete.
- Model features live apart from simulator metadata. Anything the simulator knows that a real bank could not know must never reach the feature vector. This is the single easiest way to accidentally build a model that scores 99% and means nothing.

---

## 5. Feature engineering

Feature families, all computed from data a bank could plausibly hold:

**Transaction:** amount, log amount, hour, day of week, channel, merchant category, direction.

**Behaviour (rolling per account):** amount z-score against 7d and 30d, hour-of-day likelihood, location novelty, device novelty, recipient novelty, velocity against normal velocity, merchant-category novelty.

**Temporal / sequence (window over `account_events`):** `new_device_before_transfer`, `credential_change_before_transfer`, `new_beneficiary_before_transfer`, `failed_auth_before_success`, `escalating_amounts`, `rapid_sequence`, `events_in_last_10m`.

**Graph:** `hops_to_flagged_account`, `shared_device_count`, `shared_identifier_count`, `connected_flagged_accounts`, `component_size`, `counterparty_degree_24h`.

**Device and session:** `device_known`, `device_age_days`, `device_account_count`, `session_anomaly_score`.

**Incoming-specific:** `sender_seen_before`, `relationship_age_days`, `incoming_to_outgoing_seconds`, `pass_through_ratio`, `fan_in_ratio`, `fan_out_ratio`, `inflow_concentration`, `dormancy_break_score`, `inflow_vs_normal_ratio`, `complaint_proximity_hops`.

Two rules that prevent quiet failure:

1. **Point-in-time correctness.** Every rolling feature is computed using only data that existed before the transaction timestamp. A single leak here inflates every metric and is invisible until someone asks.
2. **Cold start is a first-class path.** New accounts have no baseline. Fall back to archetype-level priors and mark `baseline_confidence` as a feature so the model can learn to weight drift signals less when the baseline is thin.

---

## 6. Scoring

**One model, not five.** A single gradient-boosted classifier over all feature families, trained on event-level labels. Direction is a feature, and separate feature builders handle the asymmetry. Two additional models exist only as separate concerns: the federated simulation (F-29) and, optionally, an unsupervised anomaly score used as an input feature rather than a competing verdict.

**Rules stay deterministic.** Velocity, structuring, coercion answers, pass-through thresholds and refund bait are rules, not learned patterns. They are explainable by construction, they cannot be degraded by a bad training run, and some of them encode policy rather than statistics.

**Fusion.** The fusion engine takes the model probability, the set of fired rules and any hard overrides, and produces a band plus an ordered reason list. Hard overrides exist: a coercion answer of "safe account" plus an unknown high-value recipient escalates regardless of model output. Reason ordering is by contribution magnitude for model reasons and by severity for rule reasons, model and rule reasons interleaved by severity.

**API contract.** The scoring endpoint returns structured codes, not prose:

```json
{
  "transaction_id": "…",
  "direction": "INCOMING",
  "risk_score": 91,
  "risk_band": "HIGH",
  "recommended_action": "QUARANTINE",
  "model_version": "bgt-risk-1.4.0",
  "reason_codes": [
    "UNKNOWN_SENDER",
    "COMPLAINT_PROXIMITY_2_HOPS",
    "HIGH_PASS_THROUGH_RISK",
    "FAN_IN_PATTERN",
    "UNUSUAL_INFLOW"
  ],
  "shap_top": [["complaint_proximity_hops", 0.31], ["sender_seen_before", 0.22]]
}
```

The frontend owns the translation from code to sentence. This keeps explanations consistent across surfaces and keeps a language model out of the decision path entirely.

**Counterfactual slider.** A separate endpoint that accepts one overridden field, rebuilds the feature vector with that override, re-runs the model and returns the new score. It is a controlled re-run, not an explanation method. SHAP explains what happened; the slider answers what-if. Cache the base feature vector so the round trip stays fast enough to feel like a slider.

---

## 7. Ledger and quarantine semantics

The mechanism the whole product rests on. Get it exactly right.

Every account has:

```
total_balance      = sum of ledger entries
held_balance       = sum of active quarantine holds
available_balance  = total_balance - held_balance
```

Every outgoing transfer asserts `available_balance >= amount` inside the same transaction that writes the ledger entry. Not before it, not in application code.

Placing a hold:

```
BEGIN
  assert transaction.status = 'COMPLETED' and direction = 'INCOMING'
  assert caller owns the receiving account
  insert quarantine_holds (transaction, amount, expires_at = now() + 24h)
  update transactions.status = 'HELD'
  insert audit_logs (action='QUARANTINE', actor, timestamp, transaction)
  insert cases (status='OPEN') and case_evidence
COMMIT
```

Release paths: expiry after 24 hours, user recognition of the sender, or analyst resolution. Each writes its own audit row. A hold is never deleted; it is closed with a reason.

The evidence record (F-16) is assembled from existing rows: receipt time, alert time, action time, spend-after-receipt computed from the ledger, reason codes and the sender subgraph snapshot taken at scoring time. Snapshot the subgraph — do not recompute it later, because the graph moves.

---

## 8. Security

The project is about financial data, so RLS is a real boundary, not documentation.

| Role | Access |
|---|---|
| Account holder | Own transactions, alerts, holds. May act only on own account |
| Analyst | Assigned cases and their evidence; no raw customer identifiers outside assigned scope |
| Admin | Models, rules, thresholds; no ability to alter audit logs |
| Virtual bank | Own raw data only; cross-bank access limited to hashed indicators |

Additional requirements: audit tables reject update and delete; service-role keys never reach the client; the scoring service authenticates to the database with a limited role; every state-changing endpoint verifies ownership server-side rather than trusting a client-supplied account id.

---

## 9. Inter-bank intelligence and federated learning

**Hashed indicator exchange (F-28).** Each virtual bank computes `SHA-256(salt || identifier)` for devices, accounts and UPI handles, and publishes only the hash plus a coarse risk indicator and a timestamp. The coordinator counts institutions per hash. A hash seen at multiple banks with adverse indicators yields a cross-bank signal that feeds back as a feature.

Be honest about the limit: a shared salt makes hashed identifiers linkable across institutions by construction, and an unsalted hash of a short identifier space is brute-forceable. This is a privacy-preserving *pattern* demonstration, not a proof of anonymity. Saying this before a judge asks is worth more than the feature itself.

**Federated simulation (F-29).** Each bank trains locally on its own partition. Only parameter updates go to the coordinator, which averages them and redistributes. Demonstrate with a handful of rounds and a visible metric curve. Partition the data non-identically across banks, or the demonstration shows nothing interesting.

---

## 10. Request flow

Incoming transaction:

```
POST /transactions
  → validate
  → persist transaction + ledger entry
  → build direction-specific features (point-in-time)
  → update graph, extract graph features
  → model predict + SHAP
  → rule engine
  → fusion → band + reason codes
  → persist risk_score + risk_reasons
  → create alert if band > LOW
  → Supabase Realtime → analyst dashboard
  → FCM → Flutter app
```

User taps Hold:

```
POST /quarantine
  → authenticate, verify ownership
  → verify transaction is incoming and completed
  → open hold, move value available → held
  → write audit event
  → open case, attach evidence + subgraph snapshot
  → Realtime update to dashboard
```

---

## 11. Deployment

| Layer | Target |
|---|---|
| Analyst frontend | Vercel |
| Backend services | Render (Docker) |
| Database, auth, realtime | Supabase |
| Mobile | Android APK, Firebase project for FCM |
| Source and CI | GitHub Actions |

Operational notes: free web services sleep after inactivity and take roughly a minute to wake, so warm the backend before any demo and quote only warm latency. Keep the generator, training and evaluation as a separate offline job with a versioned model artifact; the scoring service loads a `model_version` and never trains in-process. Seed the database ahead of the demo — never live.

---

## 12. Repository layout

```
/generator        synthetic world, seeded scenarios, deterministic seeds
/features         feature builders, shared between training and serving
/models           training, evaluation, SHAP, model registry
/graph            NetworkX service, feature extraction, subgraph snapshots
/api              FastAPI: ingestion, scoring, actions, counterfactual
/rules            deterministic rule engine and thresholds
/db               schema, enums, RLS policies, triggers, migrations
/federated        virtual banks, coordinator, hashed indicator service
/dashboard        React + TypeScript analyst UI
/app              Flutter user app
/docs             PRD, architecture, demo script, evaluation results
```

The `/features` package is imported by both training and serving. Two implementations of the same feature drifting apart is the most common way a system like this quietly breaks.

---

## 13. Build order

1. **Generator.** Population, devices, sessions, normal traffic, seeded scenarios, complaints. Event-level labels. Deterministic seed.
2. **Schema.** Tables, enums, ledger with double-entry, audit triggers, RLS policies. Load the generated world.
3. **Feature builders.** Outgoing and incoming, point-in-time correct, shared package, with cold-start fallbacks.
4. **Graph service.** Entity graph, compact feature extraction, shortest-path to flagged entities, subgraph snapshots.
5. **Model.** Train, evaluate on held-out seeded scenarios, wire SHAP, version the artifact.
6. **Rules and fusion.** Deterministic rules, hard overrides, reason-code ordering.
7. **Scoring API.** Single endpoint, measured latency, structured response.
8. **Ledger and quarantine.** Held balance, transactional holds, release paths, audit chain, case creation.
9. **Realtime and push.** Supabase Realtime to the dashboard, FCM to the app.
10. **Analyst dashboard.** Alert feed, investigation view, graph view, counterfactual slider, cases, monitoring.
11. **Flutter app.** Alerts, coercion prompts, quarantine actions, balance split display.
12. **Trust ladder.** Beneficiary trust levels, ₹1 test workflow, observation window, release.
13. **Inter-bank intelligence.** Three virtual banks, hashed indicator exchange, cross-bank feature.
14. **Federated simulation.** Local training, aggregation, rounds, metric curve.
15. **Feedback loop and monitoring.** Analyst labels, retraining path, drift and latency panels.
16. **Deploy and seed.** Everything running and warm before it is shown.

Steps 1 through 8 are the product. Steps 9 through 16 are what make it a platform. Nothing after step 8 is worth starting before step 8 is solid.

---

## 14. Evaluation

Do not report accuracy on an imbalanced fraud set; it is meaningless and a knowledgeable reviewer will say so.

Report: precision and recall at the operating threshold, precision-recall AUC, per-scenario recall (each seeded scenario type detected or not), alert volume per thousand transactions, and warm latency percentiles. Any rebalancing such as SMOTE is applied after the train/test split and only to the training fold.

The most persuasive number is not a model metric. It is the false-positive rate on normal traffic, because it answers the question a judge actually has: *would this thing drive a real customer insane?*
