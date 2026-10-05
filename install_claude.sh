#!/bin/bash
# install_claude.sh — v6 : Claude Code prêt à l'emploi, sans « claude login »
#
# Ce que fait ce script, au démarrage du service VSCode-Python :
#   1. installe Claude Code avec l'installateur officiel (aucun Node.js requis) ;
#   2. récupère le token d'abonnement dans le Vault SSPCloud ;
#   3. saute l'écran d'accueil, choisit le thème sombre et fait confiance
#      au dossier ~/work (plus de questions au premier lancement) ;
#   4. fixe des permissions raisonnables (ce que Claude peut faire sans demander)
#      et écrit des consignes générales (~/.claude/CLAUDE.md) ;
#   5. installe l'extension VSCode ;
#   6. rend tout cela actif dans chaque nouveau terminal.
#
# ---------------------------------------------------------------------------
# PRÉREQUIS (une seule fois, à refaire environ tous les ans) :
# créer le token d'abonnement Claude et le ranger dans le Vault SSPCloud
# ---------------------------------------------------------------------------
#
# Le token permet à Claude Code de se connecter à ton abonnement Pro ou Max
# sans passer par « claude login ». Il est valable environ un an.
#
# A. Obtenir le token
#    1. Ouvre un terminal dans un service où Claude Code est installé
#       (ce service, une fois ce script lancé, convient très bien).
#    2. Tape :
#           claude setup-token
#    3. Un lien s'affiche : ouvre-le dans ton navigateur et connecte-toi avec
#       ton compte claude.ai (celui de ton abonnement), comme pour « claude login ».
#    4. Si un code t'est demandé, colle-le dans le terminal puis appuie sur Entrée
#       (deux fois si rien ne se passe).
#    5. Le terminal affiche un long token qui commence par « sk-ant-oat01- ».
#       Copie-le EN ENTIER.
#
# B. Le ranger dans le Vault
#    1. Sur https://datalab.sspcloud.fr, ouvre « Mes secrets ».
#    2. Crée un nouveau secret nommé exactement « claude », à la racine de ton
#       espace (pas dans un sous-dossier).
#    3. Ajoute-lui une variable :
#           clé    : CLAUDE_CODE_OAUTH_TOKEN
#           valeur : le token copié à l'étape A.5
#    4. Relance ton service VSCode-Python : le script lira le token tout seul.
#
# ATTENTION : ce token donne accès à ton abonnement, comme un mot de passe.
# Ne le colle jamais dans un fichier, un notebook ou un dépôt Git.
# Ce script ne le contient pas : il va le chercher dans le Vault au démarrage,
# il peut donc être publié sur GitHub sans risque.
#
# Quand le token expire (Claude te redemande de te connecter), refais A puis
# remplace la valeur dans le secret « claude ».
#
# Plan B : si claude.ai est inaccessible depuis le pod, utiliser la v5 (Node + npm).

set -u

# ---------------------------------------------------------------------------
# 0. Réglages — à adapter si besoin
# ---------------------------------------------------------------------------
USER_HOME="/home/onyxia"
SECRET_NAME="claude"                 # nom du secret dans « Mes secrets »
DOSSIER_DE_CONFIANCE="$USER_HOME/work"
THEME="dark"                         # dark, light, dark-daltonized, light-daltonized…

CLAUDE_BIN="$USER_HOME/.local/bin/claude"
CLAUDE_JSON="$USER_HOME/.claude.json"
CLAUDE_DIR="$USER_HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TOKEN_FILE="$CLAUDE_DIR/.oauth_token"
BASHRC="$USER_HOME/.bashrc"

echo "=== [Claude Code] Installation (v6) ==="
echo "[contexte] utilisateur : $(id -un) (uid $(id -u))"

# Exécute une commande sous l'identité onyxia, même si le script tourne en root :
# sinon les fichiers appartiendraient à root et seraient inutilisables.
en_onyxia() {
  if [ "$(id -u)" = "0" ]; then
    su onyxia -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

# ---------------------------------------------------------------------------
# 1. Installation de Claude Code (installateur officiel, sans Node.js)
# ---------------------------------------------------------------------------
echo ""
echo "[1/6] Installation de Claude Code..."
en_onyxia "curl -fsSL https://claude.ai/install.sh | bash" \
  || echo "  (l'installateur a échoué — essayer la v5 en plan B)"

if [ -x "$CLAUDE_BIN" ]; then
  echo "  OK : $("$CLAUDE_BIN" --version 2>/dev/null)"
else
  echo "  ÉCHEC : $CLAUDE_BIN introuvable"
fi

# ---------------------------------------------------------------------------
# 2. Récupération du token d'abonnement dans le Vault
# ---------------------------------------------------------------------------
echo ""
echo "[2/6] Récupération du token dans le Vault..."
mkdir -p "$CLAUDE_DIR"
TOKEN=""

if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  # Cas où Onyxia a déjà injecté le secret comme variable d'environnement
  TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
  echo "  token déjà présent dans l'environnement"
elif [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ] && [ -n "${VAULT_TOP_DIR:-}" ]; then
  TOKEN=$(curl -fsS --max-time 15 -H "X-Vault-Token: $VAULT_TOKEN" \
      "$VAULT_ADDR/v1/${VAULT_MOUNT:-onyxia-kv}/data/$VAULT_TOP_DIR/$SECRET_NAME" \
      2>/dev/null \
    | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin)['data']['data'].get('CLAUDE_CODE_OAUTH_TOKEN', '').strip())
except Exception:
    pass
" 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    echo "  token lu dans le secret « $SECRET_NAME »"
  else
    echo "  token introuvable : vérifier le secret « $SECRET_NAME » et la clé CLAUDE_CODE_OAUTH_TOKEN"
  fi
else
  echo "  variables Vault absentes : le token ne peut pas être lu"
fi

if [ -n "$TOKEN" ]; then
  # Fichier lisible par toi seule (droits 600)
  printf '%s' "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
else
  echo "  → sans token, il faudra faire « claude login » à la main"
fi

# ---------------------------------------------------------------------------
# 3. Fin des questions du premier lancement (~/.claude.json)
# ---------------------------------------------------------------------------
echo ""
echo "[3/6] Accueil sauté, thème « $THEME », confiance accordée à $DOSSIER_DE_CONFIANCE..."
python3 - "$CLAUDE_JSON" "$DOSSIER_DE_CONFIANCE" "$THEME" <<'EOF'
import json, os, sys
chemin, dossier, theme = sys.argv[1], sys.argv[2], sys.argv[3]

config = {}
if os.path.exists(chemin) and os.path.getsize(chemin) > 0:
    try:
        with open(chemin) as f:
            config = json.load(f)
    except Exception:
        config = {}

config["hasCompletedOnboarding"] = True      # pas d'écran d'accueil
config["theme"] = theme                      # pas de question sur le thème
projet = config.setdefault("projects", {}).setdefault(dossier, {})
projet["hasTrustDialogAccepted"] = True      # pas de « Do you trust this folder? »
projet["hasCompletedProjectOnboarding"] = True

with open(chemin, "w") as f:
    json.dump(config, f, indent=2)
EOF
echo "  OK"

# ---------------------------------------------------------------------------
# 4. Permissions et token pour l'extension (~/.claude/settings.json)
# ---------------------------------------------------------------------------
echo ""
echo "[4/6] Permissions globales..."
python3 - "$SETTINGS" "$TOKEN_FILE" <<'EOF'
import json, os, sys
chemin, fichier_token = sys.argv[1], sys.argv[2]

reglages = {
    "permissions": {
        # Autorisé sans demander : commandes qui lisent ou testent, sans rien casser
        "allow": [
            "Bash(git status)",
            "Bash(git diff:*)",
            "Bash(git log:*)",
            "Bash(ls:*)",
            "Bash(cat:*)",
            "Bash(head:*)",
            "Bash(wc:*)",
            "Bash(python:*)",
            "Bash(pytest:*)",
            "Bash(ruff:*)",
            "Bash(uv:*)"
        ],
        # Interdit, toujours (bloqué par le programme Claude Code)
        "deny": [
            "Bash(rm -rf:*)",
            "Bash(sudo:*)"
        ]
    }
}

# Le token est aussi transmis ici pour que l'extension VSCode, qui ne lit pas
# .bashrc, soit connectée elle aussi.
if os.path.exists(fichier_token):
    with open(fichier_token) as f:
        token = f.read().strip()
    if token:
        reglages["env"] = {"CLAUDE_CODE_OAUTH_TOKEN": token}

with open(chemin, "w") as f:
    json.dump(reglages, f, indent=2)
os.chmod(chemin, 0o600)
EOF
echo "  OK"

# Consignes générales, lues par Claude au début de chaque session
# (~/.claude/CLAUDE.md s'applique à tous les projets)
cat > "$CLAUDE_DIR/CLAUDE.md" <<'EOF'
# Consignes générales

## Commandes administrateur (sudo)
Tu n'as pas le droit d'utiliser sudo : ces commandes sont bloquées.
Si une action nécessite des droits administrateur, arrête-toi et explique-moi :
1. pourquoi c'est nécessaire ;
2. la commande exacte à copier-coller dans le terminal ;
3. ce que fait cette commande, en termes simples ;
4. comment vérifier qu'elle a fonctionné.
Attends ensuite que je te confirme l'avoir lancée avant de continuer.
EOF
echo "  consignes générales écrites dans ~/.claude/CLAUDE.md"

# ---------------------------------------------------------------------------
# 5. Extension VSCode
# ---------------------------------------------------------------------------
echo ""
echo "[5/6] Extension VSCode..."
if command -v code-server >/dev/null 2>&1; then
  en_onyxia "code-server --install-extension anthropic.claude-code" \
    || echo "  (extension non installée)"
else
  echo "  code-server absent : extension ignorée"
fi

# ---------------------------------------------------------------------------
# 6. Terminal : PATH et token dans chaque nouveau terminal (.bashrc)
# ---------------------------------------------------------------------------
echo ""
echo "[6/6] Configuration du terminal..."
if ! grep -q '>>> claude-code >>>' "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" <<'EOF'

# >>> claude-code >>>
export PATH="$HOME/.local/bin:$PATH"
if [ -r "$HOME/.claude/.oauth_token" ]; then
  export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$HOME/.claude/.oauth_token")"
fi
# <<< claude-code <<<
EOF
  echo "  .bashrc complété"
else
  echo "  .bashrc déjà configuré"
fi

# Droits : tout doit appartenir à onyxia
if [ "$(id -u)" = "0" ]; then
  chown -R onyxia:onyxia "$CLAUDE_DIR" "$CLAUDE_JSON" "$BASHRC" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Bilan
# ---------------------------------------------------------------------------
echo ""
if [ -x "$CLAUDE_BIN" ] && [ -s "$TOKEN_FILE" ]; then
  echo "[Claude Code] Prêt : ouvre un NOUVEAU terminal et tape « claude »."
elif [ -x "$CLAUDE_BIN" ]; then
  echo "[Claude Code] Installé, mais sans token : ouvre un nouveau terminal"
  echo "              et fais « claude login »."
else
  echo "[Claude Code] Installation incomplète : relire les messages ci-dessus."
fi
echo "=== [Claude Code] Fin ==="
