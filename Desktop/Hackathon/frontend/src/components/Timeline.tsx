import { useEffect, useRef } from "react";
import { AnimatePresence, motion } from "framer-motion";

function stampTime(i: number) {
  const base = new Date();
  base.setSeconds(base.getSeconds() - Math.max(0, 8 - i));
  return base.toISOString().slice(11, 23);
}

export function Timeline({ lines, investigating }: { lines: string[]; investigating?: boolean }) {
  const endRef = useRef<HTMLLIElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to latest entry
  useEffect(() => {
    if (endRef.current) {
      endRef.current.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }, [lines.length]);

  return (
    <div className="timeline-container" ref={containerRef}>
      <ol style={{ listStyle: "none", padding: 0, margin: 0 }}>
        <AnimatePresence initial={false}>
          {lines.map((line, i) => (
            <motion.li
              className="log-line"
              key={`${i}-${line}`}
              initial={{ opacity: 0, x: -8, height: 0 }}
              animate={{ opacity: 1, x: 0, height: "auto" }}
              transition={{
                duration: 0.3,
                ease: [0.22, 1, 0.36, 1],
                height: { duration: 0.2 },
              }}
              ref={i === lines.length - 1 ? endRef : undefined}
            >
              <span className="log-time">{stampTime(i)}</span>
              <br />
              {line}
              {i === lines.length - 1 && investigating && <span className="log-cursor" />}
            </motion.li>
          ))}
        </AnimatePresence>
        {investigating && (
          <motion.li
            className="log-line"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            style={{ marginTop: 6, color: "var(--muted)" }}
          >
            <span className="investigating-dot" />
            Gathering evidence…
          </motion.li>
        )}
      </ol>
    </div>
  );
}
