# Starship · Bluefin

Un prompt Bash à deux lignes, inspiré de Bluefin. Il affiche la distribution,
l’utilisateur et la machine, le dossier courant et l’heure. La branche et
l’état Git, la version de Python et la durée des commandes apparaissent selon
le contexte.

```text
╭─  utilisateur@machine  ~/Documents  main  18:16
╰─ ❯
```

## Installer sur la Surface Pro sous Fedora

Dans un terminal Bash, avec ton compte utilisateur, clone le dépôt public
puis lance le script d’installation.

```bash
git clone https://github.com/HoareauD/bash-prompt.git
cd bash-prompt
bash starship/install.sh
```

Si tu as déjà cloné le dépôt, ouvre un terminal à sa racine et lance
`bash starship/install.sh`.

Si Starship est déjà présent, le script le réutilise. Sur Fedora classique, il
utilise `sudo dnf install starship` au besoin. Si une commande pour installer
la police manque, installe ses dépendances et relance le script.

```bash
sudo dnf install curl tar xz fontconfig
```

Sur Fedora Atomic, si Starship manque, utilise `sudo rpm-ostree install starship`,
redémarre et relance le script. Sur un autre système ayant déjà Starship, le
script peut configurer le thème dans Bash si les commandes nécessaires sont
disponibles.

Le script ne contient aucune police. Il télécharge l’archive officielle Nerd
Fonts v3.5.1, vérifie son empreinte SHA-256 et installe les variantes Mono
sous `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`. Il réutilise la famille si
elle est déjà visible pour Fontconfig. Pour passer l’étape police,
utilise `bash starship/install.sh --no-font`.

Le thème est copié dans
`${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml`.
Le script conserve ce fichier si tu le personnalises. Il ajoute une ligne
d’activation dans `~/.bashrc` et en sauvegarde une copie lors de chaque
modification sous `${XDG_STATE_HOME:-$HOME/.local/state}/bash-prompt-bluefin/`.
Ta configuration Starship par défaut et les fichiers de ton ancien prompt
restent à leur emplacement.

## Vérifier dans Konsole

Dans les paramètres du profil Konsole, règle la police sur
**JetBrainsMono Nerd Font Mono**, puis ouvre un nouveau terminal Bash.
Le script installe la police au niveau du compte. Le choix de police se fait
dans chaque profil de terminal.

```bash
starship --version
printf '%s\n' "$STARSHIP_CONFIG"
fc-list --format '%{family}\n' | cut -d, -f1 | sort -u | grep -Fx 'JetBrainsMono Nerd Font Mono'
printf '%s\n' '        ❯'
false
```

Le chemin affiché doit se terminer par `bash-prompt-bluefin/starship.toml`.
Après `false`, la flèche du prompt doit devenir rouge. Entre dans un dépôt Git
possédant au moins un commit pour voir la branche.

Pour afficher uniquement un aperçu, sans activer le thème dans Bash, lance
cette commande depuis la racine du dépôt où Starship est déjà disponible.

```bash
STARSHIP_CONFIG="$PWD/starship/starship.toml" starship prompt
```

## Revenir au prompt précédent

```bash
bash starship/uninstall.sh
```

Ferme le terminal qui utilisait Bluefin et ouvre une nouvelle fenêtre depuis
le menu des applications. Le script retire sa ligne de `~/.bashrc` et conserve
la police, Starship et ta copie locale du thème.

## Sources officielles

- [Installation de Starship et configuration de Bash](https://github.com/starship/starship#-installation)
- [Configuration de Starship](https://starship.rs/config/)
- [Nerd Fonts v3.5.1 et empreintes des archives](https://github.com/ryanoasis/nerd-fonts/releases/expanded_assets/v3.5.1)
- [Catalogue des icônes Nerd Fonts](https://www.nerdfonts.com/cheat-sheet)
