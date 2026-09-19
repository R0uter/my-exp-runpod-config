#!/bin/sh
set -eu

MODEL_FILE="${MODEL_FILE:-Ternary-Bonsai-2-27B-PQ2_0.gguf}"
BONSAI_ALPHA="${BONSAI_ALPHA:-1.0}"
BONSAI_CTX="${BONSAI_CTX:-200000}"
BONSAI_KV_TYPE="${BONSAI_KV_TYPE:-q8_0}"
PORT="${PORT:-8080}"
LLAMA_PORT="${LLAMA_PORT:-8081}"

MODEL_PATH=""
for d in \
  /runpod-volume \
  /runpod-volume/huggingface-cache \
  /runpod/model-store \
  /models \
  /workspace \
  /opt/models
do
  [ -d "$d" ] || continue
  if [ -f "$d/$MODEL_FILE" ]; then
    MODEL_PATH="$d/$MODEL_FILE"
    break
  fi
  found=$(find "$d" -name "$MODEL_FILE" -type f 2>/dev/null | head -n 1 || true)
  if [ -n "$found" ]; then
    MODEL_PATH="$found"
    break
  fi
done

if [ -z "$MODEL_PATH" ]; then
  echo "FATAL: $MODEL_FILE not found" >&2
  exit 1
fi

# proxy.pl next to this script in the image/repo; template boot extracts both.
SCRIPT_DIR=$(dirname "$0")
if [ ! -f "$SCRIPT_DIR/proxy.pl" ]; then
  SCRIPT_DIR=/tmp
fi

echo "Using model $MODEL_PATH ctx=$BONSAI_CTX llama=:$LLAMA_PORT lb=:$PORT"

# ponytail: llama on 8081; PORT 8080 is the LB contract (GET /ping).
/usr/local/bin/llama-server \
  -m "$MODEL_PATH" \
  --lora-scaled "/app/gguf/bonsai-abliterate-lora.gguf:${BONSAI_ALPHA}" \
  --host 127.0.0.1 \
  --port "$LLAMA_PORT" \
  --n-gpu-layers 99 \
  --flash-attn on \
  --ctx-size "$BONSAI_CTX" \
  --cache-type-k "$BONSAI_KV_TYPE" \
  --cache-type-v "$BONSAI_KV_TYPE" \
  --batch-size 2048 \
  --ubatch-size 1024 \
  --parallel 1 \
  --jinja \
  --temp 1.0 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  --repeat-penalty 1.0 \
  --metrics &

export PORT LLAMA_PORT
exec perl "$SCRIPT_DIR/proxy.pl"
