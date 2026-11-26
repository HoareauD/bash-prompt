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
bash install.sh
```

Si tu as déjà cloné le dépôt, ouvre un terminal à sa racine et lance
`bash install.sh`.

Si Starship est déjà présent, le script le réutilise. Sinon, il utilise
[l’installateur officiel de Starship](https://starship.rs/guide/) pour placer
le binaire dans `~/.local/bin`, sans sudo et sans ajouter de dépôt DNF.
Cette méthode fonctionne aussi sur Fedora Atomic.

Si une dépendance manque sur Fedora classique, installe-la puis relance le script.

```bash
sudo dnf install curl unzip fontconfig
```

Le script télécharge et vérifie le ZIP officiel JetBrainsMono v3.5.1, puis
extrait la famille complète sous `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`.
Pour passer cette étape, utilise `bash install.sh --no-font`.

Si Konsole et les outils KDE 6 sont disponibles, un profil Bluefin est créé
avec **JetBrainsMono Nerd Font**, taille 12. Cette variante a des icônes plus
grandes. Si eza et Python 3 sont présents et qu’il n’existe aucun thème eza,
le script harmonise les symboles Bash et ceux des dossiers visibles du
dossier personnel au moment de l’installation.

Le thème est copié dans
`${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml`.
Le script conserve ce fichier si tu le personnalises. Il ajoute une ligne
d’activation dans `~/.bashrc` et en sauvegarde une copie lors de chaque
modification sous `${XDG_STATE_HOME:-$HOME/.local/state}/bash-prompt-bluefin/`.
Ta configuration Starship par défaut et les fichiers de ton ancien prompt
restent à leur emplacement.

## Vérifier dans Konsole

Ferme et rouvre Konsole pour utiliser le profil **Bluefin**. Pour un autre
terminal, sélectionne **JetBrainsMono Nerd Font**, taille 12, dans ses
préférences.

```bash
starship --version
printf '%s\n' "$STARSHIP_CONFIG"
fc-list --format '%{family}\n' | cut -d, -f1 | sort -u | grep -Fx 'JetBrainsMono Nerd Font'
printf '%s\n' '        ❯'
false
```

Le chemin affiché doit se terminer par `bash-prompt-bluefin/starship.toml`.
Après `false`, la flèche du prompt doit devenir rouge. Entre dans un dépôt Git
possédant au moins un commit pour voir la branche.

Pour afficher uniquement un aperçu, sans activer le thème dans Bash, lance
cette commande depuis la racine du dépôt où Starship est déjà disponible.

```bash
STARSHIP_CONFIG="$PWD/starship.toml" starship prompt
```

## Revenir au prompt précédent

```bash
bash uninstall.sh
```

Ferme le terminal qui utilisait Bluefin et ouvre une nouvelle fenêtre depuis
le menu des applications. Le script retire sa ligne de `~/.bashrc`, rétablit
le profil Konsole précédent et déplace les éléments qu’il a installés vers
le dossier de sauvegarde Bluefin.

## Sources officielles

- [Installation de Starship et configuration de Bash](https://github.com/starship/starship#-installation)
- [Configuration de Starship](https://starship.rs/config/)
- [Nerd Fonts v3.5.1 et empreintes des archives](https://github.com/ryanoasis/nerd-fonts/releases/expanded_assets/v3.5.1)
- [Catalogue des icônes Nerd Fonts](https://www.nerdfonts.com/cheat-sheet)
