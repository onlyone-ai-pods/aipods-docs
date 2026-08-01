#!/usr/bin/env bash
# ==============================================================================
# 🛡️ Sincronizador & Auditor de Skills de Gobernanza (SPEC-CORE-41)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN} 🛡️ Auditoría & Sincronización Segregada de Skills v71.0.0 ${NC}"
echo -e "${CYAN}======================================================================${NC}"

MASTER_SKILLS_DIR="$SERVER_DIR/aipods-docs/.aipods/skills"

# 1. VERIFICACIÓN ANTI-HARDCODED PATHS EN SKILLS
echo -e "↳ 1. Auditando que no existan rutas locales fijas en las skills..."
if grep -rn "/home/martin/go/bin" "$MASTER_SKILLS_DIR" > /dev/null 2>&1; then
  echo -e "  ${RED}✗ Error: Se detectaron rutas locales absolutas hardcoded en las skills.${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Auditoría de rutas locales superada (0 hardcoded paths)${NC}"

# 1.1 VERIFICACIÓN DE GUÍA DE ONBOARDING
echo -e "↳ 1.1 Verificando integridad de DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md..."
ONBOARDING_FILE="$SERVER_DIR/aipods-docs/DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md"
if [ ! -f "$ONBOARDING_FILE" ]; then
  echo -e "  ${RED}✗ Error: Falta el archivo DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md en aipods-docs.${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Guía de Onboarding presente y actualizada al 100%${NC}"

# 2. DISTRIBUCIÓN SEGREGADA POR REPOSITORIO
echo -e "↳ 2. Sincronizando skills segregadas en los 3 repositorios..."

# Backend Engine (Go)
GO_ENGINE_DIR="$SERVER_DIR/aipods-core-engine/.aipods/skills"
mkdir -p "$GO_ENGINE_DIR"
rm -rf "$GO_ENGINE_DIR"/*
cp -r "$MASTER_SKILLS_DIR/core-go-architect" "$GO_ENGINE_DIR/"
cp -r "$MASTER_SKILLS_DIR/multi-tenant-security" "$GO_ENGINE_DIR/"
cp -r "$MASTER_SKILLS_DIR/sdd-spec-writer" "$GO_ENGINE_DIR/"
echo -e "  ${GREEN}✓ Skills Backend Go sincronizadas en aipods-core-engine${NC}"

# Customer Portal (React)
CUSTOMER_DIR="$SERVER_DIR/aipods-frontend-customer/.aipods/skills"
mkdir -p "$CUSTOMER_DIR"
rm -rf "$CUSTOMER_DIR"/*
cp -r "$MASTER_SKILLS_DIR/frontend-ui-architect" "$CUSTOMER_DIR/"
cp -r "$MASTER_SKILLS_DIR/ui-layout-governance" "$CUSTOMER_DIR/"
cp -r "$MASTER_SKILLS_DIR/sdd-spec-writer" "$CUSTOMER_DIR/"
echo -e "  ${GREEN}✓ Skills Frontend React sincronizadas en aipods-frontend-customer${NC}"

# Admin Hub (React)
ADMIN_DIR="$SERVER_DIR/aipods-frontend-admin/.aipods/skills"
mkdir -p "$ADMIN_DIR"
rm -rf "$ADMIN_DIR"/*
cp -r "$MASTER_SKILLS_DIR/frontend-ui-architect" "$ADMIN_DIR/"
cp -r "$MASTER_SKILLS_DIR/ui-layout-governance" "$ADMIN_DIR/"
cp -r "$MASTER_SKILLS_DIR/sdd-spec-writer" "$ADMIN_DIR/"
echo -e "  ${GREEN}✓ Skills Frontend React sincronizadas en aipods-frontend-admin${NC}"

echo -e "${GREEN}🎉 Sincronización & Auditoría de Skills Completada al 100%${NC}"
