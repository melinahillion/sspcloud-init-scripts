#!/bin/bash
# init.sh — orchestrateur d'initialisation SSPCloud
# C'est la SEULE URL a fournir a Onyxia (champ "script d'initialisation").
# Il telecharge et execute les briques ci-dessous avec bash (important : le
# shebang d'un script est ignore quand on le pipe, c'est l'interpreteur
# invoque ici qui compte).

BASE_URL="https://raw.githubusercontent.com/melinahillion/sspcloud-init-scripts/main"

echo "############ INIT SSPCLOUD : DEBUT ############"

echo "---- Brique 1/2 : Claude Code ----"
curl -fsSL "$BASE_URL/install_claude.sh" | bash

echo "---- Brique 2/2 : configuration Git ----"
curl -fsSL "$BASE_URL/setup_git.sh" | bash

echo "############ INIT SSPCLOUD : FIN ############"
