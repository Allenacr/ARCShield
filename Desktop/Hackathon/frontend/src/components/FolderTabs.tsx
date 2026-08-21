import { NavLink, useLocation } from "react-router-dom";
import { motion } from "framer-motion";

const tabVariants = {
  initial: { x: 0 },
  hover: { x: -2, transition: { type: "spring", stiffness: 400, damping: 20 } },
  active: { x: -4, transition: { type: "spring", stiffness: 300, damping: 22 } },
};

export function FolderTabs() {
  const { pathname } = useLocation();
  const caseId = pathname.match(/\/case\/([^/]+)/)?.[1];
  const onBoard = Boolean(caseId) && !pathname.includes("dossier");
  const onDossier = pathname.includes("dossier");
  return (
    <nav className="tabs" aria-label="Case folders">
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1, duration: 0.4 }}
      >
        <NavLink to="/" end className={({ isActive }) => "tab" + (isActive ? " active" : "")}>
          <motion.span variants={tabVariants} whileHover="hover">
            Intake
          </motion.span>
        </NavLink>
      </motion.div>
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.18, duration: 0.4 }}
      >
        <NavLink to={caseId ? `/case/${caseId}` : "/"} className={"tab" + (onBoard ? " active" : "")}>
          <motion.span variants={tabVariants} whileHover="hover">
            Board
          </motion.span>
        </NavLink>
      </motion.div>
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.26, duration: 0.4 }}
      >
        <NavLink
          to={caseId ? `/case/${caseId}/dossier` : "/"}
          className={"tab" + (onDossier ? " active" : "")}
        >
          <motion.span variants={tabVariants} whileHover="hover">
            Dossier
          </motion.span>
        </NavLink>
      </motion.div>
      <span className="tabs-watermark">CLASSIFIED</span>
    </nav>
  );
}
