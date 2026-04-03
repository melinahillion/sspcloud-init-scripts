#!/bin/sh

# Script d'initialisation SSPCloud — VSCode-Python + Claude Code
# Installe Node.js, le CLI Claude Code et l'extension VSCode.
# L'authentification reste manuelle : lancer "claude login" dans le terminal.
#
# Paramètres : aucun

# ── 1. Node.js ───────────────────────────────────────────────────────────────
echo "[Claude Code] Installation de Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1
echo "[Claude Code] Node.js $(node --version) installé."

# ── 2. Configuration npm (évite les erreurs de permissions) ──────────────────
mkdir -p /home/onyxia/.npm-global
npm config set prefix '/home/onyxia/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> /home/onyxia/.bashrc

# ── 3. CLI Claude Code ───────────────────────────────────────────────────────
echo "[Claude Code] Installation du CLI @anthropic-ai/claude-code..."
export PATH="/home/onyxia/.npm-global/bin:$PATH"
npm install -g @anthropic-ai/claude-code > /dev/null 2>&1
echo "[Claude Code] CLI installé : $(claude --version)."

# ── 4. Extension VSCode ──────────────────────────────────────────────────────
echo "[Claude Code] Installation de l'extension VSCode..."
code-server --install-extension anthropic.claude-code > /dev/null 2>&1
echo "[Claude Code] Extension installée."

# ── 5. Droits sur le dossier utilisateur ────────────────────────────────────
# Le script tourne en root — on rend les dossiers accessibles à onyxia
mkdir -p /home/onyxia/.claude
chown -R onyxia:onyxia /home/onyxia/.claude
chown -R onyxia:onyxia /home/onyxia/.npm-global

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅  Installation terminée !                             ║"
echo "║                                                          ║"
echo "║  👉  Lance maintenant dans le terminal VSCode :          ║"
echo "║      claude login                                        ║"
echo "║                                                          ║"
echo "║      Copie le lien affiché et ouvre-le dans              ║"
echo "║      ton navigateur pour te connecter à claude.ai        ║"
echo "╚══════════════════════════════════════════════════════════╝"