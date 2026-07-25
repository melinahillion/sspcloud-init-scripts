#!/bin/sh
# setup_git.sh — configure Git pour GitHub et GitLab.
# Les tokens viennent de Vault (variables d'env), jamais écrits ici.

git config --global user.name  "Mélina Hillion"
git config --global user.email "melina.hillion@insee.fr"

# Un helper par forge : git choisit le bon token selon le domaine appelé.
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global credential.https://github.com.helper \
    '!f() { printf "username=melinahillion\npassword=%s\n" "$GITHUB_TOKEN"; }; f'
  echo "[git] GitHub configuré."
fi

if [ -n "$GITLAB_TOKEN" ]; then
  # Adapte l'URL si tu utilises une instance GitLab interne (ex. gitlab.insee.fr)
  git config --global credential.https://gitlab.com.helper \
    '!f() { printf "username=melinahillion\npassword=%s\n" "$GITLAB_TOKEN"; }; f'
  echo "[git] GitLab configuré."
fi
