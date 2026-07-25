#!/bin/bash
# init.sh — orchestrateur d'initialisation SSPCloud
# Fourni à Onyxia (une seule URL). Appelle les briques ci-dessous.
set -e

BASE_URL="https://raw.githubusercontent.com/melinahillion/sspcloud-init-scripts/main"

echo "=== Init SSPCloud ==="

# Brique 1 : Claude Code
curl -fsSL "$BASE_URL/install_claude.sh" | sh

# Brique 2 : configuration Git multi-forges
curl -fsSL "$BASE_URL/setup_git.sh" | sh

echo "=== Init terminé ==="
