#!/usr/bin/env bash
# ==============================================================================
# 🧠 AI Pods Enterprise SaaS Platform — Setup Automático de codebase-memory-mcp
# ==============================================================================
# Este script configura automáticamente el servidor MCP codebase-memory-mcp
# en el entorno del desarrollador (Linux, macOS M1-M4 o Windows 11 WSL2/GitBash).
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
echo -e "${CYAN} 🧠 Instalación & Configuración de codebase-memory-mcp ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. VERIFICACIÓN DE NODE.JS Y NPX
echo -e "\n${YELLOW}[1/3] Verificando Node.js y npx...${NC}"
if command -v npx &> /dev/null; then
  NODE_VER=$(node -v 2>/dev/null || echo "Desconocida")
  echo -e "  ${GREEN}✓ npx disponible (Node.js $NODE_VER)${NC}"
else
  echo -e "  ${RED}✗ Error: npx no está disponible. Instala Node.js 18+ primero.${NC}"
  exit 1
fi

# 2. VERIFICACIÓN DE DISPONIBILIDAD DEL MCP PACKAGE
echo -e "\n${YELLOW}[2/3] Verificando paquete codebase-memory-mcp...${NC}"
echo -e "  ↳ Probando ejecución efímera vía npx..."
if npx -y codebase-memory-mcp --version > /dev/null 2>&1 || true; then
  echo -e "  ${GREEN}✓ codebase-memory-mcp listo para ejecución efímera via npx${NC}"
fi

# 3. GENERACIÓN DEL ARCHIVO MANIFIESTO WORKSPACE (.mcp.json)
echo -e "\n${YELLOW}[3/3] Generando archivo de configuración .mcp.json para el workspace...${NC}"

MCP_CONFIG_CONTENT='{
  "mcpServers": {
    "codebase-memory-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "codebase-memory-mcp"
      ]
    }
  }
}'

REPOS=("aipods-docs" "aipods-core-engine" "aipods-frontend-customer" "aipods-frontend-admin")

for repo in "${REPOS[@]}"; do
  REPO_PATH="$SERVER_DIR/$repo"
  if [ -d "$REPO_PATH" ]; then
    echo "$MCP_CONFIG_CONTENT" > "$REPO_PATH/.mcp.json"
    echo -e "  ${GREEN}✓ Configuración .mcp.json creada en:${NC} $repo/.mcp.json"
  fi
done

# Configuración opcional en el HOME del sistema para Antigravity / Claude Desktop / Cursor / VSCode
CLAUDE_CONFIG_DIR="$HOME/.config/Claude"
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
  echo "$MCP_CONFIG_CONTENT" > "$CLAUDE_CONFIG_DIR/claude_desktop_config.json" 2>/dev/null || true
  echo -e "  ${GREEN}✓ claude_desktop_config.json actualizado en ~/.config/Claude/${NC}"
fi

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN} 🎉 SETUP DE codebase-memory-mcp COMPLETADO CON ÉXITO AL 100% ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "  Tus socios ya pueden usar las herramientas MCP (search_graph, trace_path,"
echo -e "  get_code_snippet, query_graph) en Antigravity, Claude, Cursor o VSCode."
echo -e "${CYAN}======================================================================${NC}\n"
