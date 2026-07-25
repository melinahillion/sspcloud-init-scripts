#!/bin/bash
# setup_git.sh — v3
# Configure Git une fois pour toutes, pour TOUTES les forges.
#
# Nouveaute v3 : on n'ecrit plus les tokens dans la config git. On installe un
# helper (git-credential-vault) qui va chercher le bon token au moment du push,
# dans l'environnement OU directement dans Vault. Cela regle le probleme de
# non-propagation des secrets Vault vers le terminal interactif.
#
# Aucun secret dans ce fichier.

set -u

USER_HOME="/home/onyxia"
GITCONFIG="$USER_HOME/.gitconfig"
BIN_DIR="$USER_HOME/.local/bin"
HELPER="$BIN_DIR/git-credential-vault"
BASHRC="$USER_HOME/.bashrc"

# ATTENTION : adapte cette URL si tu renommes ton depot de dotfiles.
BASE_URL="https://raw.githubusercontent.com/melinahillion/sspcloud-init-scripts/main"

echo "[git] Configuration en cours..."

# -- 1. Installer le helper --------------------------------------------------
mkdir -p "$BIN_DIR"
if curl -fsSL "$BASE_URL/git-credential-vault" -o "$HELPER"; then
  chmod +x "$HELPER"
  echo "[git] Helper installe dans $HELPER"
else
  echo "[git] ERREUR : impossible de telecharger le helper depuis $BASE_URL"
fi

# -- 2. Configurer git (on cible le fichier : peut tourner en root) ----------
gitcfg() { git config --file "$GITCONFIG" "$@"; }

gitcfg user.name  "Melina Hillion"
gitcfg user.email "melina.hillion@insee.fr"
gitcfg init.defaultBranch main
gitcfg pull.rebase false

# UN SEUL helper pour toutes les forges : c'est lui qui route selon le domaine.
gitcfg credential.helper "$HELPER"

# On retire les anciens helpers par domaine (versions precedentes du script),
# pour eviter qu'ils prennent le pas avec un token vide.
git config --file "$GITCONFIG" --remove-section 'credential.https://github.com' 2>/dev/null || true
git config --file "$GITCONFIG" --remove-section 'credential.https://gitlab.com' 2>/dev/null || true

echo "[git] Helper unique configure (routage automatique par forge)."

# -- 3. Neutraliser l'askpass de VSCode -------------------------------------
if ! grep -q "unset GIT_ASKPASS" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << 'EOF'

# --- Laisse agir les helpers git plutot que l'askpass de VSCode ---
unset GIT_ASKPASS
unset VSCODE_GIT_ASKPASS_NODE
unset VSCODE_GIT_ASKPASS_MAIN
unset VSCODE_GIT_ASKPASS_EXTRA_ARGS
unset VSCODE_GIT_IPC_HANDLE
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
EOF
  echo "[git] Askpass VSCode neutralise + PATH complete dans .bashrc"
fi

# -- 4. Droits (le script tourne souvent en root) ---------------------------
if [ "$(id -u)" = "0" ]; then
  chown -R onyxia:onyxia "$USER_HOME/.local" 2>/dev/null || true
  chown onyxia:onyxia "$GITCONFIG" "$BASHRC" 2>/dev/null || true
fi

echo "[git] Termine."
