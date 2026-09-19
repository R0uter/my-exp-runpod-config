#!/bin/sh
set -eu
cat > /tmp/proxy.pl <<'ENDPERL'
#!/usr/bin/perl
# ponytail: reverse proxy + GET /ping|/health for RunPod LB. Not FastAPI/vLLM.
use strict;
use warnings;
use IO::Socket::INET;

my $listen = $ENV{PORT} || 8080;
my $up_port = $ENV{LLAMA_PORT} || 8081;
my $up_host = "127.0.0.1";

sub llama_ok {
    my $s = IO::Socket::INET->new(
        PeerHost => $up_host,
        PeerPort => $up_port,
        Proto    => "tcp",
        Timeout  => 1,
    ) or return 0;
    $s->autoflush(1);
    print $s "GET /health HTTP/1.0\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n";
    my $buf = "";
    while (my $line = <$s>) {
        $buf .= $line;
        last if $buf =~ /\r\n\r\n/;
    }
    close $s;
    return $buf =~ m{HTTP/1\.[01] 200};
}

sub reply_ping {
    my ($c) = @_;
    if (llama_ok()) {
        my $body = '{"status":"healthy"}';
        my $n    = length $body;
        print $c "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $n\r\nConnection: close\r\n\r\n$body";
    }
    else {
        print $c "HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n";
    }
}

sub read_request {
    my ($c) = @_;
    my $hdr = "";
    while (1) {
        my $line = <$c>;
        return unless defined $line;
        $hdr .= $line;
        last if $hdr =~ /\r\n\r\n/;
    }
    my $cl = 0;
    $cl = $1 if $hdr =~ /Content-Length:\s*(\d+)/i;
    my $body = "";
    my $got  = 0;
    while ($got < $cl) {
        my $n = read($c, my $chunk, $cl - $got);
        last unless $n;
        $body .= $chunk;
        $got  += $n;
    }
    return ($hdr, $body);
}

sub proxy {
    my ($c, $hdr, $body) = @_;
    my $up = IO::Socket::INET->new(
        PeerHost => $up_host,
        PeerPort => $up_port,
        Proto    => "tcp",
        Timeout  => 60,
    );
    unless ($up) {
        print $c "HTTP/1.1 502 Bad Gateway\r\nContent-Length: 16\r\nConnection: close\r\n\r\nllama not ready\n";
        return;
    }
    $up->autoflush(1);
    $c->autoflush(1);
    print $up $hdr;
    print $up $body if length $body;
    my $buf;
    while (1) {
        my $n = sysread($up, $buf, 65536);
        last unless $n;
        syswrite($c, $buf, $n) or last;
    }
    close $up;
}

my $srv = IO::Socket::INET->new(
    LocalPort => $listen,
    Proto     => "tcp",
    ReuseAddr => 1,
    Listen    => 32,
) or die "listen $listen: $!";

print STDERR "lb-router on :$listen -> $up_host:$up_port\n";

while (my $c = $srv->accept()) {
    $c->autoflush(1);
    my ($hdr, $body) = read_request($c);
    unless ($hdr) {
        close $c;
        next;
    }
    my $path = "/";
    $path = $2 if $hdr =~ /^(\S+)\s+(\S+)/;
    $path =~ s/\?.*//;
    if ($path eq "/ping" || $path eq "/health") {
        reply_ping($c);
    }
    else {
        proxy($c, $hdr, $body);
    }
    close $c;
}
ENDPERL
chmod +x /tmp/proxy.pl
SCRIPT_DIR=/tmp
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
