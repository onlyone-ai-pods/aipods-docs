#!/usr/bin/env bash
# ==============================================================================
# 🚀 AI Pods Enterprise SaaS Platform — Local Stack Launcher with Disown
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$SERVER_DIR/logs_local"
mkdir -p "$LOG_DIR"

echo "Iniciando servicios locales de AI Pods Platform desde $SERVER_DIR..."

# 1. Start Engine Backend (Go)
cd "$SERVER_DIR/aipods-core-engine"
go build -o server ./cmd/server/main.go
pkill -f "$SERVER_DIR/aipods-core-engine/server" || true
nohup ./server > "$LOG_DIR/engine.log" 2>&1 &
disown

# 2. Start Customer Frontend (React 18)
if [ -d "$SERVER_DIR/aipods-frontend-customer" ]; then
  cd "$SERVER_DIR/aipods-frontend-customer"
  pkill -f "vite --port 3000" || true
  nohup npx vite --port 3000 --host > "$LOG_DIR/customer_frontend.log" 2>&1 &
  disown
fi

# 3. Start Admin Frontend (React 18)
if [ -d "$SERVER_DIR/aipods-frontend-admin" ]; then
  cd "$SERVER_DIR/aipods-frontend-admin"
  pkill -f "vite --port 3001" || true
  nohup npx vite --port 3001 --host > "$LOG_DIR/admin_frontend.log" 2>&1 &
  disown
fi

echo "🟢 Servidores locales iniciados con éxito en segundo plano."
echo "   - Engine API Server : http://localhost:8080"
echo "   - Customer Portal   : http://localhost:3000"
echo "   - Admin Hub         : http://localhost:3001"
echo "   - Logs guardados en : $LOG_DIR/"
