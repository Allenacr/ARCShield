import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { getCase } from "../api";
import type { CaseRecord } from "../types";
import { Stamp } from "../components/Stamp";
import { Confidence } from "../components/Confidence";

// Stagger helper for section reveals
const sectionReveal = (i: number) => ({
  initial: { opacity: 0, y: 16 } as const,
  animate: { opacity: 1, y: 0 } as const,
  transition: { delay: 0.15 + i * 0.1, duration: 0.45, ease: [0.22, 1, 0.36, 1] as number[] },
});

export function Dossier() {
  const { caseId } = useParams();
  const [record, setRecord] = useState<CaseRecord | null>(null);
  const [showJson, setShowJson] = useState(false);

  useEffect(() => {
    if (!caseId) return;
    getCase(caseId).then(setRecord);
  }, [caseId]);

  if (!record) {
    return (
      <div className="stage">
        <motion.p
          className="lede"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        >
          No case opened. Submit a profile to begin.
        </motion.p>
      </div>
    );
  }

  if (!record.approved || !record.dossier) {
    return (
      <div className="stage">
        <motion.p
          className="lede"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          This file is still open. Approve the case on the corkboard first.
        </motion.p>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.3 }}
        >
          <Link className="btn-label" to={`/case/${record.id}`}>
            ← Return to board
          </Link>
        </motion.div>
      </div>
    );
  }

  const d = record.dossier;
  const services = (d.service_tags as string[]) || [];
  const themes = (d.content_themes as string[]) || [];

  return (
    <div className="stage">
      <motion.div
        className="dossier"
        initial={{ opacity: 0, y: 28, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
      >
        {/* ── Section 1: Header ──────────────────────────────── */}
        <motion.div className="dossier-section" {...sectionReveal(0)}>
          <div className="row" style={{ justifyContent: "space-between" }}>
            <p className="label" style={{ margin: 0 }}>
              Case file — findings
            </p>
            <Stamp label="Case closed" tone="ok" impact />
          </div>
          <h1 className="display" style={{ fontSize: 52, margin: "8px 0 0", lineHeight: 1 }}>
            Case {record.case_number}
          </h1>
          <p className="mono" style={{ color: "var(--muted)", fontSize: 13 }}>
            @{record.handle}
          </p>
        </motion.div>

        <motion.hr
          className="section-divider"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.3, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          style={{ transformOrigin: "left" }}
        />

        {/* ── Section 2: Summary ─────────────────────────────── */}
        <motion.div className="dossier-section" {...sectionReveal(1)}>
          <p className="label">Working description</p>
          <p>{String(d.business_description || record.description)}</p>
          <p className="label">Business category</p>
          <p className="section-title" style={{ fontSize: 22 }}>
            {String(d.category)}
          </p>
        </motion.div>

        {/* ── Section 3: Confidence ──────────────────────────── */}
        <motion.div className="dossier-section" {...sectionReveal(2)}>
          <Confidence
            value={Number(d.overall_confidence || 0)}
            agree={4}
            evidence={record.findings.reduce((n, f) => n + f.evidence.length, 0)}
            contradictions={record.contradictions.length}
            animate
          />
        </motion.div>

        <motion.hr
          className="section-divider"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.5, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          style={{ transformOrigin: "left" }}
        />

        {/* ── Section 4: Tags & Themes ───────────────────────── */}
        <motion.div className="dossier-section" {...sectionReveal(3)}>
          <p className="label">Primary services</p>
          <p>{services.length ? services.join(" · ") : "—"}</p>
          <p className="label">Content themes</p>
          <p>{themes.length ? themes.join(" · ") : "—"}</p>
          <p className="label">Audience</p>
          <p>{String(d.target_audience || "—")}</p>
        </motion.div>

        {/* ── Section 5: Contradictions ──────────────────────── */}
        {record.contradictions.length > 0 && (
          <motion.div className="dossier-section" {...sectionReveal(4)}>
            <motion.hr
              className="section-divider"
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ delay: 0.65, duration: 0.4 }}
              style={{ transformOrigin: "left" }}
            />
            <p className="label" style={{ color: "var(--coral)" }}>Contradictions flagged</p>
            <div className="notice">
              {record.contradictions.map((c) => (
                <motion.div
                  key={c.left + c.right}
                  initial={{ opacity: 0, x: -6 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.7, duration: 0.3 }}
                >
                  {c.left} ↔ {c.right}: {c.note}
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}

        <motion.hr
          className="section-divider"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.75, duration: 0.4 }}
          style={{ transformOrigin: "left" }}
        />

        {/* ── Section 6: Chain of Custody (typewriter-style) ── */}
        <motion.div className="dossier-section" {...sectionReveal(5)}>
          <h2 className="label">Chain of custody</h2>
          <ul style={{ paddingLeft: 18 }}>
            {record.audit.map((a, i) => (
              <motion.li
                key={i}
                className="log-line"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.85 + i * 0.05, duration: 0.3 }}
              >
                <span className="log-time">{a.ts.slice(11, 23)}</span> {a.actor} / {a.action} —{" "}
                {a.detail}
              </motion.li>
            ))}
          </ul>
        </motion.div>

        {/* ── Section 7: Actions (sticky bottom) ─────────────── */}
        <motion.div className="dossier-actions" {...sectionReveal(6)}>
          <div className="row">
            <motion.button
              className="btn-primary"
              onClick={() => setShowJson((v) => !v)}
              whileHover={{ scale: 1.02, y: -2 }}
              whileTap={{ scale: 0.96, y: 2 }}
            >
              <span>{showJson ? "Hide machine copy" : "Machine JSON"}</span>
              <span aria-hidden>→</span>
            </motion.button>
            <a
              className="btn-label"
              href={`/api/cases/${record.id}/export.json`}
              target="_blank"
              rel="noreferrer"
            >
              Integration payload
            </a>
            <Link className="btn-label" to={`/case/${record.id}`}>
              ← Reopen board
            </Link>
          </div>
        </motion.div>

        {/* ── JSON Block ─────────────────────────────────────── */}
        {showJson && (
          <motion.pre
            className="json-block"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          >
            {JSON.stringify(d, null, 2)}
          </motion.pre>
        )}
      </motion.div>
    </div>
  );
}
