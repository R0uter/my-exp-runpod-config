# orcabonsai-27b-200k

llama-server behind a tiny Perl LB router (`GET /ping` + `/health`, proxy everything else). Not vLLM/FastAPI.

## Image

`ghcr.io/letechlead/orcabonsai-27b-serving@sha256:45ebd198fe02fd8f62b04bf728beee771221dbe26b6ce1533b7a90e7cd0ed3b2`

## Template for Load Balancer

- name: `orcabonsai-27b-200k-lb`
- id: `tlfsr6ujse`
- port: `8080`
- health: `GET /ping` (204 while llama loads, 200 after)

Create a **new** load-balancer endpoint from this template in the console. Do not convert `zey2nnrdthsweh`.

## Cached model

```
https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf:main
```

`--model-reference` form. Resolved snapshot we used:

```
https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf:6ed5e12bf84b7a63069882c91dd9e9218647d17b
```

File: `Ternary-Bonsai-2-27B-PQ2_0.gguf`

Auth: `Authorization: Bearer $LLM_KEY`

```bash
python3 test-lb.py                  # HTTP probes (.env LLM_KEY)
./test-lb-status.sh                 # runpodctl get + health
LOGS=1 ./test-lb-status.sh          # include logs
```
