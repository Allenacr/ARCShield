import type { CaseRecord } from "./types";

const base = "";

export async function fetchDemos() {
  const res = await fetch(`${base}/api/demos`);
  if (!res.ok) throw new Error("Cannot reach Sleuth backend");
  return res.json() as Promise<{ handles: string[]; note: string; retention: string }>;
}

export async function openCase(url: string, reveal_pii = false) {
  const res = await fetch(`${base}/api/cases`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url, reveal_pii, retention: "ephemeral" }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.detail || "Intake failed");
  return data as { case: CaseRecord; demos?: string[] };
}

export async function getCase(id: string) {
  const res = await fetch(`${base}/api/cases/${id}`);
  if (!res.ok) throw new Error("Unknown case");
  return res.json() as Promise<CaseRecord>;
}

export async function approveCase(id: string) {
  const res = await fetch(`${base}/api/cases/${id}/approve`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ approved: true }),
  });
  if (!res.ok) throw new Error("Approval rejected");
  return res.json() as Promise<{ case: CaseRecord; dossier: Record<string, unknown> }>;
}

export function streamCase(id: string, onEvent: (e: MessageEvent) => void) {
  const es = new EventSource(`${base}/api/cases/${id}/stream`);
  es.onmessage = (e) => {
    onEvent(e);
    try {
      const data = JSON.parse(e.data) as { type?: string };
      if (data.type === "done") es.close();
    } catch {
      /* ignore malformed frames */
    }
  };
  es.onerror = () => {
    /* closed streams look like errors; avoid reconnect storms */
    es.close();
  };
  return es;
}
