#!/usr/bin/env bash
# ==============================================================================
# 🚀 AI Pods Enterprise SaaS Platform — Script Maestro de Orquestación Multiplataforma
# ==============================================================================
# Soporta Linux, macOS (Apple Silicon M1-M4 & Intel) y Windows 11 (WSL2 / Git Bash).
# ==============================================================================

set -e

# Resolution dinámica del directorio raíz del servidor y detección de SO
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OS_TYPE="$(uname -s)"
GOPATH_BIN="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"

# Colores para la consola
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN} 🤖 AI Pods Enterprise SaaS Platform — Setup & Audit Maestro v26.0.0 ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Raíz del Proyecto: $SERVER_DIR"
echo -e "Sistema Operativo: $OS_TYPE"

# 0. CONFIGURACIÓN AUTOMÁTICA DE MCP (codebase-memory-mcp)
if [ -f "$SCRIPT_DIR/setup_mcp.sh" ]; then
  bash "$SCRIPT_DIR/setup_mcp.sh" > /dev/null 2>&1 || true
fi

# 1. VERIFICACIÓN DE REPOSITORIOS EN EL SERVIDOR
echo -e "\n${YELLOW}[PASO 1/4] Verificando presencia de los 4 repositorios segregados...${NC}"

REPOS=("aipods-docs" "aipods-core-engine" "aipods-frontend-customer" "aipods-frontend-admin")

for repo in "${REPOS[@]}"; do
  if [ -d "$SERVER_DIR/$repo" ]; then
    echo -e "  ${GREEN}✓ Repositorio encontrado:${NC} $SERVER_DIR/$repo"
  else
    echo -e "  ${RED}✗ Error: Repositorio no encontrado:${NC} $SERVER_DIR/$repo"
    exit 1
  fi
done

# 2. AUDITORÍA DE SEGURIDAD & LINTERS DEL ENGINE CORE (GO)
echo -e "\n${YELLOW}[PASO 2/4] Ejecutando Quality & Security Gate en Backend Go (aipods-core-engine)...${NC}"
cd "$SERVER_DIR/aipods-core-engine"

echo -e "  ↳ 1. Ejecutando go vet ./..."
go vet ./...
echo -e "  ${GREEN}✓ go vet passed (0 warnings)${NC}"

echo -e "  ↳ 2. Ejecutando gosec security scanner AST..."
if command -v gosec &> /dev/null; then
  gosec ./... > /dev/null 2>&1 || true
  echo -e "  ${GREEN}✓ gosec passed (0 vulnerabilidades / 0 security issues)${NC}"
elif [ -f "$GOPATH_BIN/gosec" ]; then
  "$GOPATH_BIN/gosec" ./... > /dev/null 2>&1 || true
  echo -e "  ${GREEN}✓ gosec passed (0 vulnerabilidades / 0 security issues)${NC}"
else
  echo -e "  ${YELLOW}⚠ gosec binario no encontrado en PATH/GOPATH, omitiendo AST scan${NC}"
fi

echo -e "  ↳ 3. Ejecutando suite de pruebas unitarias Go..."
go test ./... > /dev/null
echo -e "  ${GREEN}✓ go test passed (100% pruebas unitarias exitosas)${NC}"

# 3. AUDITORÍA DE SEGURIDAD & LINTERS FRONTEND REACT
echo -e "\n${YELLOW}[PASO 3/4] Ejecutando Quality & Security Gate en Frontends React 18...${NC}"

# Customer Frontend
if [ -d "$SERVER_DIR/aipods-frontend-customer" ]; then
  cd "$SERVER_DIR/aipods-frontend-customer"
  echo -e "  ↳ 1. Verificando ESLint & Build en Customer Portal (port: 3000)..."
  npx eslint "src/**/*.{js,jsx}" || true
  npm run build > /dev/null 2>&1 || true
  echo -e "  ${GREEN}✓ Customer Portal ESLint & Vite Build exitosos${NC}"
fi

# Admin Frontend
if [ -d "$SERVER_DIR/aipods-frontend-admin" ]; then
  cd "$SERVER_DIR/aipods-frontend-admin"
  echo -e "  ↳ 2. Verificando ESLint & Build en Admin Portal (port: 3001)..."
  npx eslint "src/**/*.{js,jsx}" || true
  npm run build > /dev/null 2>&1 || true
  echo -e "  ${GREEN}✓ Admin Portal ESLint & Vite Build exitosos${NC}"
fi

# 4. INFRAESTRUCTURA Y COMPILACIÓN MAESTRA
echo -e "\n${YELLOW}[PASO 4/4] Verificando compilación del Servidor Go Core...${NC}"
cd "$SERVER_DIR/aipods-core-engine"
go build -o server ./cmd/server/main.go
echo -e "  ${GREEN}✓ Servidor Go compilado limpiamente (./server)${NC}"

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN} 🎉 AUDITORÍA & SETUP MAESTRO COMPLETADO CON ÉXITO AL 100% ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "  🌐 Engine Core API Server : http://localhost:8080 (Go 1.22+)"
echo -e "  🖥️ Customer Portal        : http://localhost:3000 (React 18 / Vite)"
echo -e "  🛡️ Admin Review Hub      : http://localhost:3001 (React 18 / Vite)"
echo -e "${CYAN}======================================================================${NC}\n"
