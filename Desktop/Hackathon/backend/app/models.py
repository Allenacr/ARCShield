from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class ContactInfo(BaseModel):
    email: str | None = None
    phone: str | None = None
    address_hint: str | None = None


class PostRecord(BaseModel):
    id: str
    timestamp: str
    media_type: str
    caption: str
    likes: int = 0
    comments: int = 0
    visual_tags: list[str] = Field(default_factory=list)


class NormalizedProfile(BaseModel):
    handle: str
    url: str
    display_name: str
    category_hint: str | None = None
    is_business: bool = True
    followers: int = 0
    following: int = 0
    posts_count: int = 0
    bio: str = ""
    website: str | None = None
    contact: ContactInfo = Field(default_factory=ContactInfo)
    highlights: list[str] = Field(default_factory=list)
    posts: list[PostRecord] = Field(default_factory=list)
    source: Literal["demo", "graph_api"] = "demo"


class EvidenceRef(BaseModel):
    kind: Literal["bio", "caption", "visual", "metric", "highlight"]
    locator: str
    excerpt: str
    post_id: str | None = None


class Finding(BaseModel):
    id: str
    agent: str
    title: str
    statement: str
    tags: list[str] = Field(default_factory=list)
    confidence: float = Field(ge=0, le=1)
    evidence: list[EvidenceRef] = Field(default_factory=list)
    flags: list[str] = Field(default_factory=list)
    contradicted_by: list[str] = Field(default_factory=list)


class InjectionFlag(BaseModel):
    field: str
    locator: str
    pattern: str
    excerpt: str


class PiiHit(BaseModel):
    kind: Literal["email", "phone"]
    locator: str
    redacted: str


class AuditEvent(BaseModel):
    ts: str
    actor: str
    action: str
    detail: str
    data_accessed: list[str] = Field(default_factory=list)


class OpenCaseRequest(BaseModel):
    url: str
    retention: Literal["ephemeral"] = "ephemeral"
    reveal_pii: bool = False


class ApproveRequest(BaseModel):
    approved: bool = True
    note: str | None = None


class CaseRecord(BaseModel):
    id: str
    case_number: str
    status: Literal[
        "intake",
        "sanitizing",
        "investigating",
        "synthesis",
        "awaiting_approval",
        "closed",
        "rejected",
    ]
    handle: str
    url: str
    source: Literal["demo", "graph_api"]
    retention: str
    pii_redacted: bool
    injection_flags: list[InjectionFlag] = Field(default_factory=list)
    pii_hits: list[PiiHit] = Field(default_factory=list)
    findings: list[Finding] = Field(default_factory=list)
    category: str | None = None
    description: str | None = None
    service_tags: list[str] = Field(default_factory=list)
    content_themes: list[str] = Field(default_factory=list)
    audience: str | None = None
    contradictions: list[dict[str, Any]] = Field(default_factory=list)
    overall_confidence: float | None = None
    audit: list[AuditEvent] = Field(default_factory=list)
    sanitized_preview: dict[str, Any] = Field(default_factory=dict)
    approved: bool = False
    dossier: dict[str, Any] | None = None
