import { motion } from "framer-motion";
import type { Finding } from "../types";
import { SLOTS } from "../layoutSlots";

export function Strings({
  findings,
  highlightIds,
}: {
  findings: Finding[];
  highlightIds?: Set<string>;
}) {
  const indexOf = new Map(findings.map((f, i) => [f.id, i]));
  const edges: { a: number; b: number; key: string; hot: boolean }[] = [];
  for (const f of findings) {
    for (const other of f.contradicted_by) {
      const a = indexOf.get(f.id);
      const b = indexOf.get(other);
      if (a == null || b == null || a >= b) continue;
      const hot = Boolean(highlightIds?.has(f.id) || highlightIds?.has(other));
      edges.push({ a, b, key: `${f.id}-${other}`, hot });
    }
  }
  const hasHighlight = highlightIds && highlightIds.size > 0;
  return (
    <svg
      className={hasHighlight ? "strings-svg glowing" : "strings-svg"}
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none" }}
      aria-hidden
    >
      {edges.map((e, i) => {
        const A = SLOTS[e.a % SLOTS.length];
        const B = SLOTS[e.b % SLOTS.length];
        const len = Math.sqrt(
          Math.pow((B.x - A.x) * 10, 2) + Math.pow((B.y - A.y) * 10, 2)
        );
        const dashLen = Math.max(len * 3, 500);
        return (
          <motion.line
            key={e.key}
            x1={`${A.x + 10}%`}
            y1={`${A.y + 5}%`}
            x2={`${B.x + 10}%`}
            y2={`${B.y + 5}%`}
            stroke="#FF4D6D"
            strokeWidth={e.hot ? 2.8 : 1.6}
            opacity={hasHighlight && !e.hot ? 0.15 : 0.95}
            strokeDasharray={dashLen}
            initial={{ strokeDashoffset: dashLen }}
            animate={{ strokeDashoffset: 0 }}
            transition={{
              duration: 0.9,
              delay: 0.12 * i,
              ease: [0.16, 1, 0.3, 1],
            }}
            filter={e.hot ? "drop-shadow(0 0 4px rgba(255, 77, 109, 0.6))" : "none"}
          />
        );
      })}
    </svg>
  );
}
