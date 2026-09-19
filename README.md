# orcabonsai-27b-200k

RunPod serverless serving for Ternary-Bonsai-2-27B GGUF.

## Image

`ghcr.io/letechlead/orcabonsai-27b-serving@sha256:45ebd198fe02fd8f62b04bf728beee771221dbe26b6ce1533b7a90e7cd0ed3b2`

## Template

- name: `orcabonsai-27b-200k`
- id: `p8gbv4cgo8`

## Endpoint

- name: `orcabonsai-27b-200k`
- id: `t2n1os1fnkdc5n`
- GPU: NVIDIA A40 (`gpuIds` also lists NVIDIA RTX A6000)
- workers min/max: 0 / 1
- flashboot: true
- idle timeout: 300s
- execution timeout: 600s
- scalerType: `QUEUE_DELAY` (Queue, not Load Balancer)
- health: https://api.runpod.ai/v2/t2n1os1fnkdc5n/health
- run: https://api.runpod.ai/v2/t2n1os1fnkdc5n/run
- runsync: https://api.runpod.ai/v2/t2n1os1fnkdc5n/runsync
