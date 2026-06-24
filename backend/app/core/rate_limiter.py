"""Zero-dependency IP-based Token Bucket Rate Limiter for FastAPI."""

import time
from collections import defaultdict
from fastapi import Request, HTTPException, status


class RateLimiter:
    """Token-bucket rate limiter that checks client IP address."""

    def __init__(self, requests_per_minute: int = 100):
        self.requests_per_minute = requests_per_minute
        self.tokens = defaultdict(lambda: float(requests_per_minute))
        self.last_updated = defaultdict(time.time)

    def __call__(self, request: Request):
        import os
        if os.environ.get("TESTING") == "1":
            return

        # Fallback to local if client is empty (e.g. testing or CLI)
        client_ip = "127.0.0.1"

        if request.client and request.client.host:
            client_ip = request.client.host

        now = time.time()
        elapsed = now - self.last_updated[client_ip]
        self.last_updated[client_ip] = now

        # Add tokens based on elapsed time (fraction of rate per second)
        fill_rate = self.requests_per_minute / 60.0
        self.tokens[client_ip] = min(
            float(self.requests_per_minute),
            self.tokens[client_ip] + elapsed * fill_rate
        )

        if self.tokens[client_ip] < 1.0:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Please slow down."
            )

        self.tokens[client_ip] -= 1.0
