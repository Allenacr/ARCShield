import { motion } from "framer-motion";

const randomRot = () => -3 + Math.random() * 6; // ±3° randomization

export function Stamp({
  label,
  tone = "red",
  impact,
}: {
  label: string;
  tone?: "red" | "ok" | "warn";
  impact?: boolean;
}) {
  const cls = tone === "ok" ? " ok" : tone === "warn" ? " warn" : "";
  const rot = randomRot();
  return (
    <motion.span
      className={"stamp" + cls}
      style={{ "--stamp-rot": `${rot}deg` } as React.CSSProperties}
      initial={
        impact
          ? { scale: 1.5, opacity: 0, rotate: rot - 8, filter: "blur(2px)" }
          : { scale: 1, opacity: 1, rotate: rot }
      }
      animate={{ scale: 1, opacity: 1, rotate: rot, filter: "blur(0px)" }}
      transition={
        impact
          ? {
              duration: 0.45,
              ease: [0.2, 0.8, 0.2, 1],
              scale: { type: "spring", stiffness: 350, damping: 18, mass: 0.6 },
            }
          : { duration: 0.2 }
      }
    >
      {label}
    </motion.span>
  );
}
