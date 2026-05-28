#!/bin/bash
# init.sh - Turtle Investment Framework environment setup
# For WorkBuddy / Hermes Agent + DeepSeek V4 Flash
# Supports both macOS (Claude legacy) and Windows (WorkBuddy managed Python)

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "=== Turtle Investment Framework - Environment Setup ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# 1. Python environment (venv)
VENV_DIR="$PROJECT_ROOT/.venv"

echo "[1/5] Setting up Python environment..."

# --- WorkBuddy Managed Python (Windows) ---
WB_PYTHON="/c/Users/harry/.workbuddy/binaries/python/versions/3.13.12/python.exe"
if [ -f "$WB_PYTHON" ]; then
    echo "  Found WorkBuddy managed Python 3.13"
    PYTHON_SYS="$WB_PYTHON"
# --- Fallback: system Python ---
else
    echo "  WorkBuddy managed Python not found, searching system..."
    PYTHON_SYS=""
    for candidate in python3 python3.13 python3.12 python3.11 python3.10 \
                     /opt/homebrew/bin/python3 /opt/homebrew/bin/python3.13 \
                     /usr/bin/python3 python; do
        BIN="$(command -v "$candidate" 2>/dev/null || echo "$candidate")"
        if [ -x "$BIN" ]; then
            MAJOR=$($BIN -c 'import sys; print(sys.version_info.major)' 2>/dev/null || echo 0)
            MINOR=$($BIN -c 'import sys; print(sys.version_info.minor)' 2>/dev/null || echo 0)
            if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 10 ]; then
                PYTHON_SYS="$BIN"
                break
            fi
        fi
    done
fi

if [ -z "$PYTHON_SYS" ]; then
    echo "  ERROR: No Python >= 3.10 found on this system"
    exit 1
fi
PY_VER=$($PYTHON_SYS -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "  Python: $PY_VER ($PYTHON_SYS)"

if [ ! -f "$VENV_DIR/bin/python" ] && [ ! -f "$VENV_DIR/Scripts/python.exe" ]; then
    echo "  Creating venv at $VENV_DIR ..."
    $PYTHON_SYS -m venv "$VENV_DIR"
    VENV_JUST_CREATED=1
else
    VENV_JUST_CREATED=0
fi

# Set PATH for venv (cross-platform)
if [ -f "$VENV_DIR/Scripts/python.exe" ]; then
    export PATH="$VENV_DIR/Scripts:$PATH"
    VENV_PYTHON="$VENV_DIR/Scripts/python.exe"
else
    export PATH="$VENV_DIR/bin:$PATH"
    VENV_PYTHON="$VENV_DIR/bin/python"
fi
echo "  Using: $VENV_PYTHON"

# 2. Install dependencies
echo "[2/5] Installing Python dependencies..."
if [ "$VENV_JUST_CREATED" -eq 1 ] || [ "$1" = "--force-install" ]; then
    $VENV_PYTHON -m pip install -q -r requirements.txt
    echo "  Dependencies installed."
else
    echo "  Skipped (venv exists). Use 'bash init.sh --force-install' to reinstall."
fi

# 3. Verify Tushare token
echo "[3/5] Checking Tushare token..."
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    echo "  Loaded .env file"
fi
if [ -z "$TUSHARE_TOKEN" ]; then
    echo "  WARNING: TUSHARE_TOKEN not set"
    echo "  cp .env.sample .env && edit .env"
    echo "  Tests requiring live API will be skipped"
else
    echo "  TUSHARE_TOKEN: set (${#TUSHARE_TOKEN} chars)"
fi

# Check DeepSeek API key
if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "  WARNING: DEEPSEEK_API_KEY not set (needed for LLM analysis)"
    echo "  Set it in .env file"
else
    echo "  DEEPSEEK_API_KEY: set (${#DEEPSEEK_API_KEY} chars)"
fi

# 4. Create output directory
echo "[4/5] Ensuring output directory..."
mkdir -p output

# 5. Run basic tests (mock-mode, no token needed)
echo "[5/5] Running verification tests..."
$VENV_PYTHON -m pytest tests/ -x -q --tb=short 2>&1 | tail -5

echo ""
echo "=== Setup complete ==="
echo "Usage:"
echo "  python scripts/tushare_collector.py --code 600887.SH --output output/data_pack_market.md"
echo "  python scripts/valuation_engine.py --code 600887.SH --output-dir output/"
