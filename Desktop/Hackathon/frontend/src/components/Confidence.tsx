import { useEffect, useState } from "react";
import { motion } from "framer-motion";

export function Confidence({
  value,
  agree,
  evidence,
  contradictions,
  animate: shouldAnimate,
}: {
  value: number;
  agree?: number;
  evidence?: number;
  contradictions?: number;
  animate?: boolean;
}) {
  const pct = Math.round(value * 100);
  const [displayPct, setDisplayPct] = useState(shouldAnimate ? 0 : pct);

  useEffect(() => {
    if (!shouldAnimate) {
      setDisplayPct(pct);
      return;
    }
    let frame: number;
    const start = performance.now();
    const duration = 800;
    const step = (now: number) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      setDisplayPct(Math.round(eased * pct));
      if (progress < 1) frame = requestAnimationFrame(step);
    };
    frame = requestAnimationFrame(step);
    return () => cancelAnimationFrame(frame);
  }, [pct, shouldAnimate]);

  return (
    <div className="confidence">
      <div className="label">Confidence</div>
      <div
        className={"track" + (shouldAnimate ? " animated" : "")}
        aria-label={`Confidence ${pct} percent`}
      >
        <motion.span
          className="dot"
          initial={shouldAnimate ? { left: "0%", scale: 0 } : false}
          animate={{ left: `calc(${pct}% - 4px)`, scale: 1 }}
          transition={
            shouldAnimate
              ? { type: "spring", stiffness: 140, damping: 18, delay: 0.3 }
              : { duration: 0.3 }
          }
        />
      </div>
      <div className={"meta" + (shouldAnimate ? " counter" : "")}>{displayPct}%</div>
      {(agree != null || evidence != null) && (
        <div className="meta">
          {agree != null ? `${agree} investigators agree · ` : ""}
          {evidence != null ? `${evidence} evidence items · ` : ""}
          {contradictions != null ? `${contradictions} contradictions` : ""}
        </div>
      )}
    </div>
  );
}
