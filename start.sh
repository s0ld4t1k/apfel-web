#!/bin/zsh

set -e

PORT=8765
FM_PORT=11434

cd "$(dirname "$0")"

FM_PID=""
WEB_PID=""

cleanup() {
    echo ""
    echo "Stopping..."

    if [[ -n "$WEB_PID" ]]; then
        kill "$WEB_PID" 2>/dev/null || true
    fi

    if [[ -n "$FM_PID" ]]; then
        kill "$FM_PID" 2>/dev/null || true
    fi

    echo "Stopped."
    exit 0
}

trap cleanup INT TERM EXIT

echo "======================================"
echo "        FM WEB CHAT"
echo "======================================"
echo ""

# Check if fm is already running
if curl -s --max-time 1 \
    "http://127.0.0.1:${FM_PORT}/v1/models" \
    >/dev/null 2>&1; then

    echo "✓ fm is already running"

else

    echo "Starting fm..."

    fm --serve \
        --port "$FM_PORT" \
        --host 127.0.0.1 \
        --cors \
        --allowed-origins "http://127.0.0.1:${PORT}" &

    FM_PID=$!

    echo "fm PID: $FM_PID"

    echo "Waiting for fm..."

    for i in {1..30}; do
        if curl -s --max-time 1 \
            "http://127.0.0.1:${FM_PORT}/v1/models" \
            >/dev/null 2>&1; then
            break
        fi

        sleep 0.5
    done

    if ! curl -s --max-time 1 \
        "http://127.0.0.1:${FM_PORT}/v1/models" \
        >/dev/null 2>&1; then

        echo "ERROR: fm failed to start"
        exit 1
    fi

    echo "✓ fm is ready"
fi

echo ""
echo "Starting web UI..."

python3 -m http.server "$PORT" \
    --bind 127.0.0.1 &

WEB_PID=$!

sleep 0.5

echo ""
echo "======================================"
echo "✓ FM:    http://127.0.0.1:${FM_PORT}"
echo "✓ WEB:   http://127.0.0.1:${PORT}"
echo "======================================"
echo ""
echo "Open:"
echo "http://127.0.0.1:${PORT}"
echo ""
echo "Press Ctrl+C to stop everything."
echo ""

wait "$WEB_PID"
