import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { getCase, streamCase, approveCase } from "../api";
import type { CaseRecord, Finding, StreamEvent } from "../types";
import { PinCard } from "../components/PinCard";
import { Strings } from "../components/Strings";
import { Timeline } from "../components/Timeline";
import { Stamp } from "../components/Stamp";
import { Confidence } from "../components/Confidence";

function applyRecord(c: CaseRecord, setRecord: (c: CaseRecord) => void, setPins: (f: Finding[]) => void) {
  setRecord(c);
  if (c.findings.length) {
    setPins(c.findings.filter((f) => f.agent !== "chief_investigator"));
  }
}

export function Investigation() {
  const { caseId } = useParams();
  const nav = useNavigate();
  const [record, setRecord] = useState<CaseRecord | null>(null);
  const [pins, setPins] = useState<Finding[]>([]);
  const [lines, setLines] = useState<string[]>(["Intake complete. Dispatching investigators."]);
  const [why, setWhy] = useState<Finding | null>(null);
  const [closing, setClosing] = useState(false);
  const [showStampOverlay, setShowStampOverlay] = useState(false);
  const done = useRef(false);

  useEffect(() => {
    if (!caseId) return;
    done.current = false;
    let es: EventSource | undefined;
    let timer: number | undefined;

    const pull = () =>
      getCase(caseId).then((c) => {
        applyRecord(c, setRecord, setPins);
        if (c.status === "awaiting_approval" || c.status === "closed" || c.status === "rejected") {
          done.current = true;
          if (timer) window.clearInterval(timer);
        }
      });

    pull();
    timer = window.setInterval(() => {
      if (!done.current) pull();
    }, 450);

    es = streamCase(caseId, (msg) => {
      const ev = JSON.parse(msg.data) as StreamEvent;
      if (ev.line) {
        setLines((prev) => (prev.includes(ev.line!) ? prev : [...prev, ev.line!]));
      }
      if (ev.type === "agent" && ev.findings) {
        setPins((prev) => {
          const ids = new Set(prev.map((p) => p.id));
          return [...prev, ...ev.findings!.filter((f) => !ids.has(f.id))];
        });
      }
      if (ev.type === "done") {
        done.current = true;
        es?.close();
        if (timer) window.clearInterval(timer);
        pull();
      }
    });

    return () => {
      es?.close();
      if (timer) window.clearInterval(timer);
    };
  }, [caseId]);

  const boardFindings = useMemo(
    () => pins.filter((f) => f.agent !== "chief_investigator"),
    [pins]
  );

  const litIds = useMemo(() => {
    if (!why) return new Set<string>();
    return new Set([why.id, ...why.contradicted_by]);
  }, [why]);

  const evidenceCount = boardFindings.reduce((n, f) => n + f.evidence.length, 0);
  const isInvestigating = record ? !done.current : false;
  const isAwaitingApproval = record?.status === "awaiting_approval";

  async function closeCase() {
    if (!caseId) return;
    setClosing(true);
    // Show the stamp overlay
    setShowStampOverlay(true);
    await approveCase(caseId);
    window.setTimeout(() => nav(`/case/${caseId}/dossier`), 1200);
  }

  if (!record) {
    return (
      <div className="stage">
        <motion.p
          className="lede shimmer-text"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.4 }}
        >
          Gathering the jacket…
        </motion.p>
      </div>
    );
  }

  return (
    <div className="stage">
      {/* ── Sticky Case Header ─────────────────────────────── */}
      <motion.div
        className="sticky-header"
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
      >
        <div className="row" style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <motion.p
              className="label"
              style={{ margin: 0 }}
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1, duration: 0.35 }}
            >
              Case {record.case_number}
            </motion.p>
            <motion.h1
              className="display"
              style={{ margin: "2px 0 0", fontSize: 52, lineHeight: 1 }}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15, duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
            >
              @{record.handle}
            </motion.h1>
          </div>
          <motion.div
            className="row"
            initial={{ opacity: 0, x: 12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2, duration: 0.4 }}
          >
            {record.injection_flags.length > 0 && (
              <Stamp label={`⚠ Review · ${record.injection_flags.length}`} tone="warn" impact />
            )}
            {record.pii_redacted && <Stamp label="PII barred" />}
            <Stamp
              label={record.status.replaceAll("_", " ")}
              tone={record.status === "awaiting_approval" ? "ok" : "red"}
              impact
            />
          </motion.div>
        </div>
        <motion.hr
          className="rule"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.3, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          style={{ transformOrigin: "left" }}
        />
      </motion.div>

      {/* ── Main Board + Sidebar Layout ────────────────────── */}
      <div style={{ display: "grid", gridTemplateColumns: "minmax(0,1fr) 300px", gap: 22 }}>
        {/* Corkboard */}
        <motion.div
          className="corkboard"
          id="board"
          initial={{ scale: 0.92, opacity: 0 }}
          animate={
            closing
              ? { scale: 0.94, opacity: 0.25, filter: "blur(6px)" }
              : { scale: 1, opacity: 1, filter: "blur(0px)" }
          }
          transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
        >
          <Strings findings={boardFindings} highlightIds={why ? litIds : undefined} />
          {boardFindings.map((f, i) => (
            <PinCard
              key={f.id}
              finding={f}
              index={i}
              onWhy={(next) => setWhy(why?.id === next.id ? null : next)}
              lit={why ? litIds.has(f.id) : false}
              dim={Boolean(why) && !litIds.has(f.id)}
            />
          ))}
        </motion.div>

        {/* Sidebar */}
        <motion.aside
          className="aside"
          initial={{ opacity: 0, x: 16 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.25, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
        >
          {/* Investigation Log */}
          <p className="label">Investigation log</p>
          <Timeline lines={lines} investigating={isInvestigating} />

          {/* Section divider */}
          <hr className="section-divider" />

          {/* Approval Gate */}
          <div className={"gate" + (isAwaitingApproval ? " glowing" : "")}>
            <h3>{isAwaitingApproval ? "Ready for approval" : "Awaiting approval"}</h3>
            <p className="gate-stat">{boardFindings.length} findings</p>
            <p className="gate-stat">{evidenceCount} evidence references</p>
            <p className="gate-stat">{record.pii_hits.length} PII fields redacted</p>

            {record.overall_confidence != null && (
              <Confidence value={record.overall_confidence} animate />
            )}

            <p className="lede" style={{ fontSize: 13, marginTop: 10 }}>
              Export stays locked until you approve.
            </p>
            <motion.button
              className="btn-primary"
              style={{ marginTop: 12, minWidth: "100%" }}
              disabled={record.status !== "awaiting_approval" || closing}
              onClick={closeCase}
              whileHover={isAwaitingApproval && !closing ? { scale: 1.02, y: -2 } : {}}
              whileTap={isAwaitingApproval && !closing ? { scale: 0.96, y: 2 } : {}}
            >
              <span>{closing ? "Closing file…" : "Approve & export"}</span>
              <motion.span
                aria-hidden
                animate={closing ? { rotate: [0, 360] } : {}}
                transition={closing ? { repeat: Infinity, duration: 1, ease: "linear" } : {}}
              >
                ✓
              </motion.span>
            </motion.button>
          </div>

          {/* Return link */}
          <p>
            <Link to="/" className="btn-label" style={{ marginTop: 12, display: "inline-flex" }}>
              ← Return to intake
            </Link>
          </p>
        </motion.aside>
      </div>

      {/* ── Evidence Side Panel ─────────────────────────────── */}
      <AnimatePresence>
        {why && (
          <>
            <motion.div
              className="evidence-overlay"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.25 }}
              onClick={() => setWhy(null)}
            />
            <motion.div
              className="evidence-panel"
              initial={{ x: "100%", opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: "100%", opacity: 0 }}
              transition={{ type: "spring", stiffness: 260, damping: 28 }}
            >
              <div className="row" style={{ justifyContent: "space-between", marginBottom: 18 }}>
                <div>
                  <p className="label" style={{ margin: 0 }}>
                    Why this finding
                  </p>
                  <p className="mono" style={{ margin: "4px 0 0", fontSize: 12 }}>
                    {why.id.toUpperCase()}
                  </p>
                </div>
                <motion.button
                  className="btn-label"
                  onClick={() => setWhy(null)}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  Close ✕
                </motion.button>
              </div>

              <h3 className="finding-title" style={{ fontSize: 18 }}>{why.title}</h3>
              <p className="finding-body" style={{ WebkitLineClamp: "unset" as any, marginBottom: 16 }}>
                {why.statement}
              </p>

              <hr className="section-divider" />
              <p className="label">Source evidence</p>

              <ul style={{ paddingLeft: 18 }}>
                {why.evidence.map((e, i) => (
                  <motion.li
                    key={e.locator}
                    style={{ marginBottom: 14 }}
                    initial={{ opacity: 0, x: 10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 + i * 0.06, duration: 0.3 }}
                  >
                    <div className="mono" style={{ fontSize: 11, color: "var(--muted)" }}>
                      {e.kind.toUpperCase()} · {e.locator.toUpperCase()}
                      {e.post_id ? ` · POST ${e.post_id}` : ""}
                    </div>
                    <div className="evidence-excerpt">"{e.excerpt}"</div>
                  </motion.li>
                ))}
              </ul>

              {why.contradicted_by.length > 0 && (
                <>
                  <hr className="section-divider" />
                  <p className="label" style={{ color: "var(--coral)" }}>
                    Contradicted by: {why.contradicted_by.join(", ")}
                  </p>
                </>
              )}
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* ── Case Closed Stamp Overlay ──────────────────────── */}
      <AnimatePresence>
        {showStampOverlay && (
          <motion.div
            className="stamp-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
          >
            <motion.div
              className="stamp-overlay-text"
              initial={{ scale: 2.5, opacity: 0, rotate: -20 }}
              animate={{ scale: 1, opacity: 0.85, rotate: -12 }}
              transition={{
                type: "spring",
                stiffness: 200,
                damping: 14,
                mass: 0.8,
              }}
            >
              Case Closed
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
