# sspcloud-init-scripts

Scripts d'initialisation pour mes services [SSP Cloud](https://datalab.sspcloud.fr)
(Onyxia) : installation de Claude Code, configuration Git multi-forges, et
clonage automatique du dépôt de travail.

---

## Principe

Onyxia n'accepte qu'**une** URL de script d'initialisation par service. Ce dépôt
fournit donc un **orchestrateur** (`init.sh`) qui télécharge et exécute les
briques, ce qui permet de garder des morceaux séparés et réutilisables.

```
Champ « script d'initialisation » d'Onyxia
        │  (curl au démarrage)
        ▼
    init.sh
        ├──► install_claude.sh      Node.js + CLI Claude Code
        └──► setup_git.sh           config Git + clonage du dépôt
                    └──► git-credential-vault   (helper installé dans ~/.local/bin)
```

## Contenu

| Fichier | Rôle |
|---|---|
| `init.sh` | Orchestrateur : **la seule URL à fournir à Onyxia** |
| `install_claude.sh` | Installe Node.js (≥ 18) et le CLI Claude Code |
| `setup_git.sh` | Configure Git, installe le helper, clone le dépôt du service |
| `git-credential-vault` | Helper d'identifiants : trouve le bon token selon la forge |

---

## Installation

### 1. Préparer les secrets dans Vault

SSP Cloud → **Mon compte → Mes secrets**. Crée les clés dont tu as besoin :

| Clé | Nécessaire pour | Portée recommandée du token |
|---|---|---|
| `GITHUB_TOKEN` | pousser / cloner sur GitHub | `repo` uniquement |
| `GITLAB_TOKEN` | pousser / cloner sur GitLab.com | `write_repository` |
| `GITLAB_INSEE_TOKEN` | instance GitLab interne | `write_repository` |
| `GIT_NAME` | *(optionnel)* surcharger le nom d'auteur | — |
| `GIT_EMAIL` | *(optionnel)* surcharger l'email d'auteur | — |


### 2. Configurer le service Onyxia

Au lancement d'un service (VSCode, Jupyter…) :

| Onglet | Champ | Valeur |
|---|---|---|
| Init | script d'initialisation | `https://raw.githubusercontent.com/melinahillion/sspcloud-init-scripts/refs/heads/main/init.sh` |
| Vault | chemin du secret | le chemin copié depuis « Mes secrets » |
| Git | URL du dépôt | ex. `https://github.com/melinahillion/Assistant.git` |
| Git | token | **laisser vide** (le helper s'en charge) |

Puis **enregistre la configuration** (favoris Onyxia) : tout sera pré-rempli aux
prochains lancements, il n'y aura plus rien à ressaisir.

> Le champ Vault est le plus souvent oublié. S'il est vide, la variable
> `VAULT_RELATIVE_PATH` reste vide et aucun secret n'est injecté.

### 3. Vérifier après démarrage

```bash
# Claude Code
claude --version

# Git : le helper est-il installé et actif ?
ls -l ~/.local/bin/git-credential-vault
git config --get credential.helper

# Le dépôt a-t-il été cloné automatiquement ?
ls ~/work/

# Test réel : doit passer sans rien demander
cd ~/work/<mon-depot> && git pull
```

Pour vérifier une variable sans jamais afficher sa valeur :

```bash
echo ${#GITHUB_TOKEN}      # affiche la longueur, pas le contenu
```

---

## Comment fonctionne `git-credential-vault`

Git dispose d'un mécanisme d'extension pour l'authentification : quand il a
besoin d'identifiants, il lance le programme désigné par `credential.helper`,
lui écrit `host=github.com` sur l'entrée standard, et attend `username=…` et
`password=…` sur la sortie standard.

Notre helper exploite ce mécanisme :

1. il lit le **domaine** demandé par Git ;
2. il en déduit quelle clé chercher (`github.com` → `GITHUB_TOKEN`, etc.) ;
3. il cherche la valeur d'abord dans les **variables d'environnement**, puis, si
   elle est absente, **directement dans Vault** via `VAULT_ADDR` / `VAULT_TOKEN` ;
4. il la renvoie à Git, qui l'utilise et l'oublie.

Deux conséquences utiles :

- **un seul helper pour toutes les forges** : rien à reconfigurer selon que le
  dépôt est sur GitHub ou GitLab, le routage est automatique ;
- **ça fonctionne même si les secrets Vault ne sont pas propagés au terminal** —
  cas courant sur SSP Cloud, où les variables sont visibles par le script d'init
  (lancé en root) mais pas par les shells interactifs.

Le token n'est **jamais écrit sur disque** : il vit dans Vault et ne transite
qu'en mémoire, le temps d'une opération Git.

### Ajouter une forge

Dans `git-credential-vault`, complète le dictionnaire `FORGES` :

```python
FORGES = {
    "github.com":      ("x-access-token", "GITHUB_TOKEN"),
    "gitlab.com":      ("oauth2",         "GITLAB_TOKEN"),
    "ma-forge.fr":     ("oauth2",         "MA_FORGE_TOKEN"),
}
```

Puis crée la clé correspondante dans Vault. Rien d'autre à modifier.

*(Le nom d'utilisateur `x-access-token` / `oauth2` est une convention technique :
avec un token d'accès personnel, la forge ignore ce champ. Aucune donnée
personnelle n'apparaît donc dans le fichier.)*

---

## Identité Git (nom et email)

Git refuse de créer un commit sans `user.name` ni `user.email`. Le script les
récupère dans cet ordre, sans jamais les écrire en dur :

1. `GIT_USER_NAME` / `GIT_USER_MAIL` — **fournis automatiquement par Onyxia** ;
2. les clés `GIT_NAME` / `GIT_EMAIL` dans Vault, si tu veux les surcharger.

---

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| `echo ${#GITHUB_TOKEN}` → `0` mais Git fonctionne | secret non propagé au terminal | normal : le helper lit Vault directement |
| `[git-credential-vault] Aucun token trouve` | clé absente de Vault, ou nom incorrect | vérifier l'orthographe exacte de la clé |
| `Authentication failed` malgré un token valide | l'askpass de VSCode intercepte l'authentification | ouvrir un **nouveau** terminal (le `.bashrc` neutralise l'askpass) |
| `ECONNREFUSED /tmp/vscode-git-*.sock` | même cause | idem |
| Dépôt non cloné au démarrage | `GIT_REPOSITORY` non renseigné, ou token absent | remplir l'URL dans l'onglet Git ; vérifier Vault |
| `claude: command not found` | `PATH` non rechargé, ou installation échouée | `export PATH="$HOME/.npm-global/bin:$PATH"`, puis consulter les logs |
| `node: command not found` | installation de Node échouée | voir les logs du service, section *Brique 1/2* |

### Lire les logs d'initialisation

Onglet **Logs** du service. Les briques sont balisées :

```
############ INIT SSPCLOUD : DEBUT ############
---- Brique 1/2 : Claude Code ----
---- Brique 2/2 : configuration Git ----
############ INIT SSPCLOUD : FIN ############
```

Les scripts n'écrasent volontairement pas les messages d'erreur : un `> /dev/null`
mal placé masque précisément l'information dont on a besoin pour diagnostiquer.

---

## Notes techniques

- **Le shebang d'un script est ignoré quand on le pipe.** `curl … | sh` exécute
  avec `sh` quoi qu'il arrive ; c'est pourquoi `init.sh` utilise `| bash`
  (l'installeur NodeSource exige bash).
- **Les scripts d'init tournent en root.** `git config --global` écrirait alors
  dans `/root/.gitconfig` ; on cible donc explicitement le fichier de
  l'utilisateur avec `--file`, puis on rétablit les droits avec `chown`.
- **Les pods sont jetables** : la configuration est reposée à chaque démarrage,
  c'est voulu. Rien n'a besoin de persister.
