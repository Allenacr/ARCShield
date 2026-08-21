import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { openCase } from "../api";
import { Stamp } from "../components/Stamp";

const ARCHIVED_DOCKETS = [
  {
    handle: "marigold.bakery.pdx",
    url: "https://www.instagram.com/marigold.bakery.pdx/",
    name: "Marigold Artisan Bakery",
    category: "Food & Beverage · Retail",
    summary: "Artisan sourdough bakery. Features luxury aesthetic packaging but runs heavy discount promotional copy.",
    flag: "Contradiction Flagged",
    flagTone: "red" as const,
    confidence: "94%",
    evidenceCount: "4 findings · 11 refs",
  },
  {
    handle: "ironclad.studio",
    url: "https://www.instagram.com/ironclad.studio/",
    name: "Ironclad Strength & Motion",
    category: "Health & Fitness · Studio",
    summary: "High-intensity athletic training facility. Contains adversarial prompt injection patterns in bio & captions.",
    flag: "Injection Defended",
    flagTone: "warn" as const,
    confidence: "88%",
    evidenceCount: "3 findings · PII Redacted",
  },
  {
    handle: "northline.agency",
    url: "https://www.instagram.com/northline.agency/",
    name: "Northline Growth Studio",
    category: "Professional Services · B2B",
    summary: "Full-cycle B2B performance marketing agency with verified client outcomes and multi-service offerings.",
    flag: "Verified Pattern",
    flagTone: "ok" as const,
    confidence: "96%",
    evidenceCount: "5 findings · 14 refs",
  },
];

export function Intake() {
  const nav = useNavigate();
  const [url, setUrl] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [heroReady, setHeroReady] = useState(false);

  // Typewriter effect for hero title
  const heroFull = "Sleuth";
  const [heroText, setHeroText] = useState("");

  useEffect(() => {
    let i = 0;
    const interval = setInterval(() => {
      i++;
      setHeroText(heroFull.slice(0, i));
      if (i >= heroFull.length) {
        clearInterval(interval);
        setTimeout(() => setHeroReady(true), 200);
      }
    }, 110);
    return () => clearInterval(interval);
  }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!url.trim()) return;
    setBusy(true);
    setError("");
    try {
      const { case: c } = await openCase(url);
      if (c.status === "rejected") {
        setError(`No archived case file for @${c.handle}. Live scrape is disabled in this build.`);
        setBusy(false);
        return;
      }
      nav(`/case/${c.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Intake failed");
      setBusy(false);
    }
  }

  function selectDocket(docketUrl: string) {
    setUrl(docketUrl);
    setError("");
  }

  return (
    <div className="stage">
      <div className="intake-container">
        {/* Top Header Section */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", flexWrap: "wrap", gap: 16 }}>
          <div>
            <motion.p
              className="label"
              style={{ margin: 0 }}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4 }}
            >
              Bureau of Profile Intelligence · Autonomous Investigation System
            </motion.p>
            <motion.h1
              className="display hero"
              style={{ fontSize: 76, margin: "4px 0 0", lineHeight: 0.95 }}
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            >
              {heroText}
              {!heroReady && <span className="hero-cursor" />}
            </motion.h1>
          </div>

          <motion.div
            className="row"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3, duration: 0.5 }}
          >
            <Stamp label="Deterministic Sanitization" tone="ok" />
            <Stamp label="PII Guarded" />
            <Stamp label="Gated Approval" tone="warn" />
          </motion.div>
        </div>

        <motion.p
          className="lede"
          style={{ marginTop: 12, marginBottom: 0 }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.5 }}
        >
          Paste any public Instagram business profile. Four specialized autonomous agents dissect bio, visual aesthetics, audience sentiment, and content themes. The Chief Investigator resolves contradictions and scores confidence before anything is finalized.
        </motion.p>

        <motion.hr
          className="rule"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.25, duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          style={{ transformOrigin: "left" }}
        />

        {/* ── Full-Width Responsive Two-Column Grid ───────────────── */}
        <div className="intake-grid">
          {/* Left Column: Case File Intake Form */}
          <motion.div
            className="intake-left"
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="folder">
              <p className="label" style={{ marginTop: 4 }}>
                Target Intake
              </p>
              <h2 className="display" style={{ fontSize: 28, margin: "6px 0 10px" }}>
                Initiate New Investigation
              </h2>
              <p className="serif-reading" style={{ fontSize: 14, margin: "0 0 18px" }}>
                Enter an Instagram URL or account handle. Untrusted text is strictly sanitized against prompt injection and scrubbed of raw PII prior to multi-agent synthesis.
              </p>

              <form onSubmit={submit}>
                <label className="label" style={{ display: "block", margin: "14px 0 6px" }}>
                  Target Instagram URL / Handle
                </label>
                <input
                  className="field"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="https://www.instagram.com/marigold.bakery.pdx/"
                  autoFocus
                />

                {error && (
                  <motion.p
                    className="notice"
                    role="alert"
                    style={{ marginTop: 14 }}
                    initial={{ opacity: 0, x: -8 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    {error}
                  </motion.p>
                )}

                <div className="row" style={{ marginTop: 24, justifyContent: "space-between" }}>
                  <motion.button
                    className="btn-primary"
                    disabled={busy || !url.trim()}
                    type="submit"
                    whileHover={!busy && url.trim() ? { scale: 1.02, y: -2 } : {}}
                    whileTap={!busy && url.trim() ? { scale: 0.96, y: 2 } : {}}
                  >
                    <span>{busy ? "Opening Case File…" : "Open Investigation"}</span>
                    <motion.span
                      aria-hidden
                      animate={busy ? { x: [0, 5, 0] } : {}}
                      transition={busy ? { repeat: Infinity, duration: 1 } : {}}
                    >
                      →
                    </motion.span>
                  </motion.button>

                  <span className="mono" style={{ fontSize: 11, color: "var(--muted)" }}>
                    Ephemeral Memory · Auto-Purge
                  </span>
                </div>
              </form>

              {/* Bottom Pipeline Security Notes */}
              <div style={{ marginTop: 28, paddingTop: 18, borderTop: "1px dashed rgba(32, 16, 66, 0.15)" }}>
                <p className="label" style={{ marginBottom: 8 }}>
                  Safety & Privacy Protocol
                </p>
                <div className="pipeline-grid">
                  <div className="pipeline-feature">
                    <h4>Injection Shield</h4>
                    <p>Heuristic + boundary pattern defense on untrusted captions</p>
                  </div>
                  <div className="pipeline-feature">
                    <h4>PII Scrubbing</h4>
                    <p>Automated redacting of emails & phone numbers with audit trail</p>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Right Column: Archived Case Vault & Interactive Dockets */}
          <motion.div
            className="intake-right"
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="vault-panel">
              <div className="vault-header">
                <div>
                  <p className="label" style={{ margin: 0 }}>
                    Evidence Archive
                  </p>
                  <h3 className="display" style={{ fontSize: 20, margin: "2px 0 0" }}>
                    Select Archived Case Docket
                  </h3>
                </div>
                <span className="mono" style={{ fontSize: 11, color: "var(--gold-deep)", fontWeight: 600 }}>
                  3 Pre-Analyzed Targets
                </span>
              </div>

              <p className="serif-reading" style={{ fontSize: 13, margin: "0 0 16px" }}>
                Click any docket below to load its target URL into the investigator intake.
              </p>

              <div className="dockets-stack">
                {ARCHIVED_DOCKETS.map((docket, i) => {
                  const isSelected = url.trim() === docket.url;
                  return (
                    <motion.div
                      key={docket.handle}
                      className={"docket-card" + (isSelected ? " selected" : "")}
                      onClick={() => selectDocket(docket.url)}
                      initial={{ opacity: 0, x: 16 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.45 + i * 0.08, duration: 0.4 }}
                      whileHover={{ scale: 1.015 }}
                      whileTap={{ scale: 0.985 }}
                    >
                      <div className="docket-title-row">
                        <div>
                          <span className="docket-handle">@{docket.handle}</span>
                          <span style={{ fontSize: 13, color: "var(--muted)", marginLeft: 6 }}>
                            ({docket.name})
                          </span>
                        </div>
                        <Stamp label={docket.flag} tone={docket.flagTone} />
                      </div>

                      <p className="docket-desc">{docket.summary}</p>

                      <div className="docket-footer">
                        <span>{docket.category}</span>
                        <span>
                          Confidence: <strong style={{ color: "var(--indigo)" }}>{docket.confidence}</strong> · {docket.evidenceCount}
                        </span>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            </div>

            {/* Investigator Agent Breakdown */}
            <div className="vault-panel" style={{ padding: "18px 22px" }}>
              <p className="label" style={{ margin: "0 0 8px" }}>
                4 Specialized Autonomous Agents
              </p>
              <div className="pipeline-grid">
                <div className="pipeline-feature">
                  <h4>Profile Agent</h4>
                  <p>Handles, bio intent, domain authority & contact vectors</p>
                </div>
                <div className="pipeline-feature">
                  <h4>Visual Agent</h4>
                  <p>Aesthetic clustering, luxury vs discount palettes & imagery</p>
                </div>
                <div className="pipeline-feature">
                  <h4>Content Agent</h4>
                  <p>Semantic themes, offer frequencies & copywriting tone</p>
                </div>
                <div className="pipeline-feature">
                  <h4>Audience Agent</h4>
                  <p>Demographic alignment, comment signals & positioning</p>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
