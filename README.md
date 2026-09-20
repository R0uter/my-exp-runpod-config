# orcabonsai-27b-200k

llama-server behind a Perl LB router (`GET /ping` + `/health`, proxy everything else). Not vLLM/FastAPI.

Works. Call the load-balancer URL with Bearer auth.

## Live

- endpoint: `zbvtollsf5emjd` (`orcabonsai-27b-200k-img`)
- image: `ghcr.io/r0uter/orcabonsai-27b-runpod@sha256:30c56c9031de55cf1df78b3794309536a6e36da130a400baf534f2803ff34aa4`
- template: `2f3h0nxlqq` (console clone; start-cmd empty — boot is image `ENTRYPOINT /lb-boot.sh`)
- port `8080`, ctx `200000`, LoRA alpha `1.0`, min CUDA `13.1`

## API

```
https://zbvtollsf5emjd.api.runpod.ai/v1/chat/completions
Authorization: Bearer <LLM_KEY>
```

Do **not** use `https://api.runpod.ai/v2/<id>/openai/v1`.

```bash
python3 test-lb.py                  # HTTP probes (.env LLM_KEY)
./test-lb-status.sh                 # runpodctl get + health
LOGS=1 ./test-lb-status.sh          # include logs
```

## Model (RunPod cache)

```
https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf:main
```

File: `Ternary-Bonsai-2-27B-PQ2_0.gguf`

## Rebuild

```bash
docker build --platform linux/amd64 -t ghcr.io/r0uter/orcabonsai-27b-runpod .
```

Keep template start-cmd empty. Console LB deploy strips it; the baked ENTRYPOINT still runs.
