from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import HTTPException, Request


class TokenBucketLimiter:
    def __init__(self, rate: float, burst: int) -> None:
        self.rate = rate
        self.burst = burst
        self.tokens: dict[str, float] = defaultdict(lambda: float(burst))
        self.updated: dict[str, float] = defaultdict(time.monotonic)
        self.lock = Lock()
        self.failures: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str) -> None:
        now = time.monotonic()
        with self.lock:
            elapsed = now - self.updated[key]
            self.tokens[key] = min(self.burst, self.tokens[key] + elapsed * self.rate)
            self.updated[key] = now
            recent = self.failures[key]
            while recent and now - recent[0] > 60:
                recent.popleft()
            if len(recent) >= 8:
                raise HTTPException(status_code=503, detail="Circuit open — extraction paused")
            if self.tokens[key] < 1:
                raise HTTPException(status_code=429, detail="Rate limited")
            self.tokens[key] -= 1

    def record_failure(self, key: str) -> None:
        with self.lock:
            self.failures[key].append(time.monotonic())


limiter = TokenBucketLimiter(rate=4, burst=20)


async def limit_request(request: Request) -> None:
    host = request.client.host if request.client else "unknown"
    limiter.check(host)
