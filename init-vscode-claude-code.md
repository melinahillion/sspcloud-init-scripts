# Tutoriel : Utiliser Claude Code dans VSCode sur le SSPCloud

> **Public visé** : débutants souhaitant configurer Claude Code comme assistant de code dans un service VSCode-Python sur le SSPCloud (datalab Onyxia de l'INSEE).  
> **Prérequis** : avoir un compte SSPCloud actif et un abonnement Claude Pro ou Max.

---

## Sommaire

1. [Ce que tu vas obtenir](#1-ce-que-tu-vas-obtenir)
2. [Comprendre les outils](#2-comprendre-les-outils)
3. [Lancer un service VSCode-Python sur le SSPCloud](#3-lancer-un-service-vscode-python-sur-le-sspcloud)
4. [Installer Claude Code manuellement](#4-installer-claude-code-manuellement)
5. [Se connecter avec son abonnement Claude](#5-se-connecter-avec-son-abonnement-claude)
6. [Utiliser Claude Code](#6-utiliser-claude-code)
7. [Choisir son modèle](#7-choisir-son-modèle)
8. [Automatiser l'installation avec un script d'init](#8-automatiser-linstallation-avec-un-script-dinit)
9. [Conseils pratiques](#9-conseils-pratiques)

---

## 1. Ce que tu vas obtenir

À la fin de ce tutoriel, ton service VSCode-Python sur le SSPCloud sera équipé de **Claude Code**, un assistant de code intelligent développé par Anthropic. Tu pourras :

- Poser des questions sur ton code en langage naturel
- Demander à Claude de corriger des bugs, écrire des fonctions, expliquer du code
- Interagir via un panneau de chat dans VSCode ou via le terminal

---

## 2. Comprendre les outils

### Le SSPCloud (Onyxia)
Le SSPCloud est une plateforme de data science développée par l'INSEE. Elle permet de lancer des environnements de travail (VSCode, Jupyter, RStudio…) dans le cloud, sans installation locale. **Important** : les services sont **éphémères** — tout ce qui n'est pas sauvegardé dans ton espace de stockage ou un dépôt Git est perdu à la fermeture du service.

### Claude Code
Claude Code est l'outil de programmation assistée par IA d'Anthropic. Il se compose de deux parties distinctes :
- **Le CLI** (`claude`) : une commande à utiliser dans le terminal
- **L'extension VSCode** : un panneau de chat intégré dans l'éditeur

### Abonnement vs API
C'est une distinction importante :
- Ton **abonnement Claude Pro ou Max** te donne accès à Claude via claude.ai et via Claude Code (inclus dans l'abonnement, sans frais supplémentaires)
- L'**API Anthropic** est un système séparé, facturé au token — tu n'en as pas besoin si tu utilises Claude Code avec ton abonnement

---

## 3. Lancer un service VSCode-Python sur le SSPCloud

1. Connecte-toi sur [datalab.sspcloud.fr](https://datalab.sspcloud.fr)
2. Clique sur **Catalogue de services**
3. Cherche **VSCode-Python** et clique sur **Lancer**
4. (Optionnel) Configure le service selon tes besoins (ressources, dépôt Git…)
5. Clique sur **Lancer** — le service démarre en quelques secondes
6. Clique sur le lien du service pour ouvrir VSCode dans ton navigateur

---

## 4. Installer Claude Code manuellement

> Cette étape est à refaire à chaque nouveau service (les conteneurs SSPCloud sont éphémères). La section 8 explique comment l'automatiser.

Ouvre le **terminal intégré** de VSCode (`Ctrl+` ` `) et exécute les commandes suivantes dans l'ordre.

### Étape 4.1 — Installer Node.js

Node.js est nécessaire pour faire fonctionner le CLI Claude Code.

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

Vérifie l'installation :
```bash
node --version
# Doit afficher quelque chose comme : v20.20.2
```

### Étape 4.2 — Configurer npm pour éviter les erreurs de permissions

Par défaut, npm essaie d'installer les paquets dans un dossier système auquel tu n'as pas accès. Cette configuration le redirige vers ton dossier personnel :

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.npm-global/bin:$PATH"
```

### Étape 4.3 — Installer le CLI Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Vérifie l'installation :
```bash
claude --version
# Doit afficher quelque chose comme : 2.1.91 (Claude Code)
```

### Étape 4.4 — Installer l'extension VSCode

```bash
code-server --install-extension anthropic.claude-code
```

---

## 5. Se connecter avec son abonnement Claude

### Vérification préalable importante

Assure-toi qu'aucune clé API n'est définie dans ton environnement (ce qui forcerait une facturation au token) :

```bash
echo $ANTHROPIC_API_KEY
```

Si cette commande affiche quelque chose, désactive la variable :
```bash
unset ANTHROPIC_API_KEY
```

Si elle n'affiche rien, c'est parfait — continue.

### Lancer l'authentification

```bash
claude login
```

Un assistant de configuration s'affiche :

1. **Choix du thème** : utilise les touches fléchées pour sélectionner ton thème préféré (ex. `1. Dark mode`) puis appuie sur `Entrée`
2. **Choix de l'authentification** : sélectionne l'option de connexion via **claude.ai** (pas "API key")
3. **Navigateur** : une fenêtre s'ouvre dans ton navigateur — connecte-toi avec tes identifiants claude.ai
4. **Code de confirmation** : un code t'est envoyé par mail, colle-le dans le terminal à l'invite `Paste code here if prompted >`
5. Appuie sur `Entrée` (parfois deux fois si rien ne se passe)

✅ Une fois connecté, Claude Code est prêt à l'emploi.

---

## 6. Utiliser Claude Code

Tu as deux façons d'interagir avec Claude Code.

### Via la sidebar VSCode (recommandé pour les débutants)

Clique sur l'icône Claude dans la barre latérale gauche de VSCode. Un panneau de chat s'ouvre. Tu peux :
- Poser des questions en langage naturel sur ton code
- Mentionner un fichier spécifique avec `@nom_du_fichier`
- Voir les modifications proposées sous forme de diff (rouge = supprimé, vert = ajouté) avant de les accepter

### Via le terminal (CLI)

**Session interactive** (pour une conversation suivie) :
```bash
claude
```
Puis tape tes questions directement. Commandes utiles dans la session :
```
/help     → affiche l'aide
/clear    → vide le contexte de la conversation
/model    → change le modèle utilisé
/exit     → quitter
```

**One-shot** (pour une question rapide) :
```bash
claude "Explique ce que fait ce script Python"
claude "Corrige le bug dans ma fonction clean_data()"
```

### Quand utiliser quoi ?

| Situation | Mode recommandé |
|---|---|
| Modifier ou refactoriser des fichiers | Sidebar VSCode |
| Question rapide sur du code | CLI one-shot |
| Session longue de débogage | CLI interactif |
| Travailler sur plusieurs fichiers | Sidebar VSCode |

---

## 7. Choisir son modèle

### Modèles disponibles

| Modèle | Caractéristiques | Usage recommandé |
|---|---|---|
| `claude-haiku-4-5-20251001` | Très rapide, léger | Questions simples, tâches courtes |
| `claude-sonnet-4-6` | Équilibre qualité/vitesse | **Usage quotidien (recommandé)** |
| `claude-opus-4-6` | Le plus puissant | Problèmes complexes (Max uniquement) |

### Changer de modèle

**Dans la sidebar VSCode** : utilise le sélecteur de modèle dans l'interface du panneau Claude.

**Dans le CLI** :
```bash
# Au lancement
claude --model claude-sonnet-4-6

# Depuis une session interactive
/model claude-sonnet-4-6
```

**Définir un modèle par défaut** (pour ne plus avoir à le préciser) :
```bash
claude config set model claude-sonnet-4-6
```

---

## 8. Automatiser l'installation avec un script d'init

Comme les services SSPCloud sont éphémères, il faut réinstaller Claude Code à chaque démarrage. Le script d'init permet d'automatiser cela.

### Le script

Crée un fichier `init-vscode-claude-code.sh` avec le contenu suivant :

```bash
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
```

> **Différence avec la version précédente** : la configuration npm (`prefix` et `PATH`) est intégrée directement dans le script, ce qui évite l'erreur de permissions rencontrée lors de l'installation manuelle.

### Mettre le script sur GitHub

1. Crée un **nouveau dépôt public** sur [github.com](https://github.com) (ex. `sspcloud-init-scripts`)
2. Ajoute le fichier `init-vscode-claude-code.sh`
3. Clique sur le fichier, puis sur le bouton **Raw**
4. Copie l'URL qui ressemble à :
   ```
   https://raw.githubusercontent.com/<ton-pseudo>/sspcloud-init-scripts/main/init-vscode-claude-code.sh
   ```

### Configurer le script d'init sur le SSPCloud

1. Sur le datalab, clique sur **VSCode-Python** → **Configurer**
2. Va dans l'onglet **Init**
3. Colle l'URL raw de ton script dans le champ *Script d'initialisation*
4. Clique sur l'icône **marque-page** en haut à droite pour sauvegarder cette configuration
5. Lance le service — le script s'exécute automatiquement au démarrage

### Après chaque démarrage

Le script installe tout automatiquement. Il te reste juste à faire une fois dans le terminal :
```bash
claude login
```
Et suivre les étapes d'authentification (section 5).

---

## 9. Conseils pratiques

### Créer un fichier CLAUDE.md dans ton projet

Claude lit automatiquement ce fichier au démarrage de chaque session pour comprendre le contexte de ton projet. Crée-le à la racine de ton projet :

```markdown
# Mon projet

## Contexte
[Décris en quelques phrases ce que fait ton projet]

## Stack technique
- Python 3.11, pandas
- Données sur S3 (MinIO SSPCloud)

## Conventions
- Commentaires en français
- Noms de variables en snake_case
```

### Gérer le quota

Ton abonnement Pro ou Max partage le quota entre claude.ai et Claude Code. Pour économiser :
- Utilise **Haiku** pour les questions simples
- Réserve **Sonnet** ou **Opus** pour les tâches complexes
- Utilise `/clear` régulièrement pour vider le contexte et alléger les échanges

### En cas de problème

| Problème | Solution |
|---|---|
| `claude: command not found` | Relancer `export PATH="$HOME/.npm-global/bin:$PATH"` |
| Erreur de permissions npm | Vérifier la config avec `npm config get prefix` |
| Authentification bloquée | Appuyer sur `Entrée` une deuxième fois après le code |
| Claude utilise l'API au lieu de l'abonnement | Vérifier avec `echo $ANTHROPIC_API_KEY` et faire `unset ANTHROPIC_API_KEY` |