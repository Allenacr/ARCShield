import { motion } from "framer-motion";
import type { Finding } from "../types";
import { Confidence } from "./Confidence";
import { SLOTS } from "../layoutSlots";

function agentLabel(agent: string) {
  return agent.replaceAll("_", " ").replace("investigator", "").trim();
}

export function PinCard({
  finding,
  index,
  onWhy,
  lit,
  dim,
}: {
  finding: Finding;
  index: number;
  onWhy: (f: Finding) => void;
  lit?: boolean;
  dim?: boolean;
}) {
  const slot = SLOTS[index % SLOTS.length];
  const contradicted = finding.flags.includes("contradiction");
  const injection = finding.flags.includes("injection");
  return (
    <motion.article
      className={
        "pin-card is-finding" +
        (lit ? " lit" : "") +
        (dim ? " dim" : "") +
        (contradicted && !lit ? " contradicted" : "")
      }
      layoutId={`finding-${finding.id}`}
      initial={{ y: -80, opacity: 0, scale: 0.88, rotate: -2 }}
      animate={{
        y: lit ? -4 : 0,
        opacity: 1,
        scale: 1,
        rotate: contradicted ? slot.r - 1.2 : slot.r,
      }}
      transition={{
        type: "spring",
        stiffness: 180,
        damping: 16,
        mass: 0.8,
        delay: index * 0.1,
      }}
      whileHover={{
        y: -8,
        scale: 1.03,
        boxShadow: "0 22px 44px rgba(16, 8, 24, 0.28), 4px 6px 0 rgba(255, 77, 109, 0.4)",
        transition: { type: "spring", stiffness: 300, damping: 18 },
      }}
      style={{ left: `${slot.x}%`, top: `${slot.y}%` }}
    >
      <motion.span
        className="pin-head"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{
          type: "spring",
          stiffness: 400,
          damping: 12,
          delay: index * 0.1 + 0.15,
        }}
      />
      <div className="label">
        {injection ? "× Flagged" : contradicted ? "× Contradicted" : "✓ Confirmed finding"}
      </div>
      <div className="mono" style={{ fontSize: 11, color: "var(--muted)", marginTop: 4 }}>
        {finding.id.toUpperCase()} · {agentLabel(finding.agent).toUpperCase()}
      </div>
      <h3 className="finding-title">{finding.title}</h3>
      <p className="finding-body">{finding.statement}</p>
      <Confidence
        value={finding.confidence}
        evidence={finding.evidence.length}
        contradictions={finding.contradicted_by.length}
        animate
      />
      <div className="row" style={{ marginTop: 12 }}>
        <motion.button
          className={"btn-why" + (lit ? " active" : "")}
          onClick={() => onWhy(finding)}
          whileHover={{ x: 3 }}
          whileTap={{ scale: 0.95 }}
        >
          Why? <span aria-hidden>⟶</span>
        </motion.button>
      </div>
    </motion.article>
  );
}
