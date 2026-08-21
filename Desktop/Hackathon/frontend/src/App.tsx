import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { FolderTabs } from "./components/FolderTabs";
import { Intake } from "./pages/Intake";
import { Investigation } from "./pages/Investigation";
import { Dossier } from "./pages/Dossier";

export default function App() {
  const location = useLocation();
  return (
    <div className="shell">
      <FolderTabs />
      <AnimatePresence mode="wait">
        <motion.div
          className="page"
          key={location.pathname}
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
        >
          <Routes location={location}>
            <Route path="/" element={<Intake />} />
            <Route path="/case/:caseId" element={<Investigation />} />
            <Route path="/case/:caseId/dossier" element={<Dossier />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
