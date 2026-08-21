export type EvidenceRef = {
  kind: string;
  locator: string;
  excerpt: string;
  post_id?: string | null;
};

export type Finding = {
  id: string;
  agent: string;
  title: string;
  statement: string;
  tags: string[];
  confidence: number;
  evidence: EvidenceRef[];
  flags: string[];
  contradicted_by: string[];
};

export type CaseRecord = {
  id: string;
  case_number: string;
  status: string;
  handle: string;
  url: string;
  source: string;
  retention: string;
  pii_redacted: boolean;
  injection_flags: { field: string; locator: string; pattern: string; excerpt: string }[];
  pii_hits: { kind: string; locator: string; redacted: string }[];
  findings: Finding[];
  category?: string | null;
  description?: string | null;
  service_tags: string[];
  content_themes: string[];
  audience?: string | null;
  contradictions: { left: string; right: string; note: string }[];
  overall_confidence?: number | null;
  audit: { ts: string; actor: string; action: string; detail: string; data_accessed: string[] }[];
  sanitized_preview: Record<string, unknown>;
  approved: boolean;
  dossier?: Record<string, unknown> | null;
};

export type StreamEvent = {
  type: string;
  status?: string;
  line?: string;
  agent?: string;
  state?: string;
  findings?: Finding[];
  contradictions?: { left: string; right: string; note: string }[];
  overall_confidence?: number;
  count?: number;
};
