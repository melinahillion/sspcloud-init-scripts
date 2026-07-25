#!/bin/bash
# install_claude.sh — installe Node.js + le CLI Claude Code
#
# v2 : les erreurs ne sont PLUS masquees (fini les > /dev/null), et on tente
# plusieurs sources pour Node afin de resister aux filtrages reseau.
# L'authentification reste manuelle : lancer "claude login" dans le terminal.

set -u

USER_HOME="/home/onyxia"
NPM_PREFIX="$USER_HOME/.npm-global"

echo "=== [Claude Code] Installation ==="

# -- 1. Node.js (>= 18 requis) ----------------------------------------------
node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  major=$(node --version | sed 's/^v//' | cut -d. -f1)
  [ "$major" -ge 18 ] 2>/dev/null
}

if node_ok; then
  echo "[Claude Code] Node deja present : $(node --version)"
else
  echo "[Claude Code] Tentative 1/2 : depot Ubuntu (apt)"
  apt-get update -qq || echo "  (apt-get update a echoue)"
  apt-get install -y nodejs npm || echo "  (apt install nodejs a echoue)"

  if ! node_ok; then
    echo "[Claude Code] Tentative 2/2 : depot NodeSource 20.x"
    # NB : ce script NodeSource exige bash (pas sh).
    curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource.sh \
      && bash /tmp/nodesource.sh \
      && apt-get install -y nodejs \
      || echo "  (NodeSource a echoue : reseau filtre ?)"
  fi
fi

if ! node_ok; then
  echo "[Claude Code] ECHEC : Node.js indisponible ou trop ancien."
  echo "               Verifie l'acces reseau a archive.ubuntu.com"
  echo "               et deb.nodesource.com depuis le pod."
  exit 0   # on n'interrompt pas le reste de l'init
fi
echo "[Claude Code] Node $(node --version), npm $(npm --version)"

# -- 2. npm en espace utilisateur (evite les soucis de droits) --------------
mkdir -p "$NPM_PREFIX"
if [ "$(id -u)" = "0" ]; then
  chown -R onyxia:onyxia "$NPM_PREFIX"
fi

# -- 3. CLI Claude Code (installe EN TANT QUE onyxia, pas root) -------------
echo "[Claude Code] Installation du CLI @anthropic-ai/claude-code..."
if [ "$(id -u)" = "0" ]; then
  su - onyxia -c "npm config set prefix '$NPM_PREFIX' && \
                  PATH=$NPM_PREFIX/bin:\$PATH npm install -g @anthropic-ai/claude-code"
else
  npm config set prefix "$NPM_PREFIX"
  PATH="$NPM_PREFIX/bin:$PATH" npm install -g @anthropic-ai/claude-code
fi

# -- 4. PATH persistant ------------------------------------------------------
BASHRC="$USER_HOME/.bashrc"
if ! grep -q '.npm-global/bin' "$BASHRC" 2>/dev/null; then
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$BASHRC"
fi

# -- 5. Droits ---------------------------------------------------------------
mkdir -p "$USER_HOME/.claude"
if [ "$(id -u)" = "0" ]; then
  chown -R onyxia:onyxia "$USER_HOME/.claude" "$NPM_PREFIX" "$BASHRC" 2>/dev/null || true
fi

# -- 6. Verification ---------------------------------------------------------
if [ -x "$NPM_PREFIX/bin/claude" ]; then
  echo "[Claude Code] OK : $($NPM_PREFIX/bin/claude --version 2>/dev/null || echo installe)"
  echo "[Claude Code] Lance 'claude login' dans le terminal pour t'authentifier."
else
  echo "[Claude Code] ECHEC : le binaire n'a pas ete cree dans $NPM_PREFIX/bin"
fi
