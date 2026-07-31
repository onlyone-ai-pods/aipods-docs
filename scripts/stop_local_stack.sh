#!/usr/bin/env bash
# ==============================================================================
# 🛑 AI Pods Enterprise SaaS Platform — Script de Detención del Entorno Local
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN} 🛑 Deteniendo todos los servicios locales de AI Pods Enterprise ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Detener Backend Core Engine (Go) en Puerto 8080
echo -e "\n${YELLOW}[1/3] Deteniendo Motor Core Go (Backend REST API en port 8080)...${NC}"
fuser -k 8080/tcp || true
pkill -f "$SERVER_DIR/aipods-core-engine/server" || true
pkill -f "./server" || true
pkill -f "go run ./cmd/server" || true
echo -e "${GREEN}  ✓ Backend Core Engine detenido y puerto 8080 liberado${NC}"

# 2. Detener Frontend Customer Portal en Puerto 3000
echo -e "\n${YELLOW}[2/3] Deteniendo Portal de Clientes (Customer Frontend en port 3000)...${NC}"
pkill -f "vite --port 3000" || true
echo -e "${GREEN}  ✓ Customer Portal detenido${NC}"

# 3. Detener Frontend Admin Review Hub en Puerto 3001
echo -e "\n${YELLOW}[3/3] Deteniendo Portal de Administración (Admin Hub en port 3001)...${NC}"
pkill -f "vite --port 3001" || true
echo -e "${GREEN}  ✓ Admin Review Hub detenido${NC}"

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN} 🎉 TODOS LOS SERVICIOS LOCALES FUERON DETENIDOS LIMPIAMENTE ${NC}"
echo -e "${CYAN}======================================================================${NC}\n"
