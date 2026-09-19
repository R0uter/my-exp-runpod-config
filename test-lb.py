#!/usr/bin/env python3
"""Probe a RunPod load-balancer endpoint.

Reads LLM_KEY from .env (never printed). Endpoint id from argv, else ENDPOINT_ID, else z7rmwbm5ac8cow.

  python3 test-lb.py
  python3 test-lb.py z7rmwbm5ac8cow
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEFAULT_ID = "z7rmwbm5ac8cow"


def load_env() -> dict[str, str]:
    env = dict(os.environ)
    p = ROOT / ".env"
    if not p.exists():
        return env
    for line in p.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        env.setdefault(k, v.strip().strip('"').strip("'"))
    return env


def hit(base: str, key: str, path: str, data: dict | None = None, timeout: float = 30):
    headers = {"Authorization": "Bearer " + key}
    body = None
    method = "GET"
    if data is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(data).encode()
        method = "POST"
    req = urllib.request.Request(base + path, data=body, headers=headers, method=method)
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()[:1500].decode("utf-8", "replace")
            return r.status, raw, round(time.time() - t0, 2)
    except urllib.error.HTTPError as e:
        return e.code, e.read()[:800].decode("utf-8", "replace"), round(time.time() - t0, 2)
    except Exception as e:
        return type(e).__name__, str(e)[:200], round(time.time() - t0, 2)


def main() -> int:
    env = load_env()
    key = env.get("LLM_KEY") or ""
    if not key:
        print("missing LLM_KEY in .env", file=sys.stderr)
        return 2
    eid = (sys.argv[1] if len(sys.argv) > 1 else "") or env.get("ENDPOINT_ID") or DEFAULT_ID
    base = f"https://{eid}.api.runpod.ai"
    print("endpoint", eid)
    print("base", base)
    print("key_len", len(key))

    req = urllib.request.Request(base + "/ping")
    try:
        urllib.request.urlopen(req, timeout=8)
        print("NOAUTH /ping unexpected success")
    except urllib.error.HTTPError as e:
        print("NOAUTH /ping", e.code)
    except Exception as e:
        print("NOAUTH /ping", type(e).__name__)

    probes = [
        ("GET /ping", "/ping", None, 20),
        ("GET /health", "/health", None, 20),
        ("GET /v1/models", "/v1/models", None, 30),
        ("GET /lora-adapters", "/lora-adapters", None, 20),
        (
            "POST /v1/chat/completions",
            "/v1/chat/completions",
            {
                "messages": [{"role": "user", "content": "Say hello in one sentence."}],
                "max_tokens": 24,
                "temperature": 0,
            },
            90,
        ),
    ]
    for name, path, data, timeout in probes:
        code, body, sec = hit(base, key, path, data, timeout)
        print(f"{name} {code} t={sec}s")
        print(body[:400])
        print("---")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
