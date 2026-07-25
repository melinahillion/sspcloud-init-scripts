# sspcloud-dotfiles

Scripts d'initialisation pour mes services [SSP Cloud](https://datalab.sspcloud.fr)
(Onyxia). Un point d'entrée unique (`init.sh`) qui orchestre des briques
modulaires : installation de Claude Code et configuration Git multi-forges.

## Principe

Onyxia ne prend qu'**une** URL de script d'initialisation au lancement d'un
service. Ce dépôt fournit un **orchestrateur** (`init.sh`) qui télécharge et
exécute les autres scripts. On garde ainsi des briques séparées et réutilisables
tout en ne fournissant qu'une seule URL à Onyxia.

```
Champ "init script" d'Onyxia  ──►  init.sh  ──►  install_claude.sh
                                            └──►  setup_git.sh
```

## Règle de sécurité

**Ce dépôt est public et ne doit contenir AUCUN secret.**

- Les tokens (`GITHUB_TOKEN`, `GITLAB_TOKEN`, …) vivent dans **Vault** et sont
  injectés comme variables d'environnement au lancement du service.
- Les scripts ne font que *référencer* ces variables (`$GITHUB_TOKEN`), jamais
  écrire leur valeur.

La mécanique est publique, les secrets sont dans Vault, et on ne mélange jamais
les deux. Un token qui change se met à jour dans Vault sans toucher au code.

## Contenu

| Fichier | Rôle |
|---|---|
| `init.sh` | Orchestrateur : la seule URL à fournir à Onyxia |
| `install_claude.sh` | Installe Node.js, le CLI Claude Code et l'extension VSCode |
| `setup_git.sh` | Configure Git (nom, email) et l'authentification GitHub/GitLab |

## Utilisation

### 1. Préparer les secrets dans Vault
Dans SSP Cloud → **Mon compte → Mes secrets**, crée les variables (portée
minimale recommandée : `repo` pour GitHub, `write_repository` pour GitLab) :
- `GITHUB_TOKEN`
- `GITLAB_TOKEN` *(optionnel)*

### 2. Lancer un service avec ce script d'init
Au lancement d'un service (VSCode, Jupyter…), dans la configuration :
- **Init script** → l'URL brute de `init.sh` :
  ```
  https://raw.githubusercontent.com/melinahillion/sspcloud-dotfiles/main/init.sh
  ```
- **Vault** → rattache le(s) secret(s) contenant `GITHUB_TOKEN` / `GITLAB_TOKEN`.

### 3. Vérifier après démarrage
```sh
claude --version                                         # Claude Code installé
git config --get credential.https://github.com.helper    # helper GitHub présent
echo ${#GITHUB_TOKEN}                                     # ~40 : token bien injecté
```

## Ajouter une forge (ex. GitLab interne)

Dans `setup_git.sh`, ajoute un bloc en adaptant le domaine :
```sh
if [ -n "$GITLAB_INSEE_TOKEN" ]; then
  git config --global credential.https://gitlab.insee.fr.helper \
    '!f() { printf "username=melinahillion\npassword=%s\n" "$GITLAB_INSEE_TOKEN"; }; f'
fi
```
Puis crée le secret correspondant dans Vault. Aucun autre changement nécessaire.

- Le dépôt est public **parce qu'il ne contient aucun secret** — c'est ce qui
  évite le problème d'amorçage (un script d'accès Git ne peut pas dépendre d'un
  accès Git pour être récupéré).
