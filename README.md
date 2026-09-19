# orcabonsai-27b-200k

RunPod serverless serving for Ternary-Bonsai-2-27B GGUF (llama-server HTTP, ctx 200000).

## Image

`ghcr.io/letechlead/orcabonsai-27b-serving@sha256:45ebd198fe02fd8f62b04bf728beee771221dbe26b6ce1533b7a90e7cd0ed3b2`

## Template

- name: `orcabonsai-27b-200k`
- id: `p8gbv4cgo8`
- HTTP port: `8080`
- Health: `GET /health` (llama-server; not `/ping`)

## Endpoint

Queue endpoint `t2n1os1fnkdc5n` was deleted. `runpodctl` cannot create a load-balancer endpoint. Create one in the console from this template (Endpoint Type = Load Balancer).
