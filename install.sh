#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'Starship Bluefin : %s\n' "$*" >&2
    exit 1
}

mode=${1:-install}
case "$#:$mode" in
    0:install|1:--no-font|1:--uninstall) ;;
    *) die "Utilisation : bash install.sh [--no-font] ou bash uninstall.sh." ;;
esac
(( EUID != 0 )) || die "Lance ce script avec ton compte, sans sudo."

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
theme_dir="$config_home/bash-prompt-bluefin"
bin_dir="$HOME/.local/bin"
font_dir="$data_home/fonts"
font_target="$font_dir/JetBrainsMono-bluefin-v3.5.1"
konsole_config="$config_home/konsolerc"
konsole_profile="$data_home/konsole/Bluefin.profile"
theme="$theme_dir/starship.toml"
old_hook='if [[ $- == *i* ]] && command -v starship >/dev/null && [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml" ]]; then export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml"; declare -F starship_precmd >/dev/null || eval "$(starship init bash)"; fi # bash-prompt-bluefin'
hook='if [[ $- == *i* && -x "$HOME/.local/bin/starship" ]] && ! command -v starship >/dev/null; then export PATH="$HOME/.local/bin:$PATH"; fi; if [[ $- == *i* ]] && command -v starship >/dev/null && [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml" ]]; then export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml"; declare -F starship_precmd >/dev/null || eval "$(starship init bash)"; fi # bash-prompt-bluefin'

# Verrou commun, même si plusieurs installations sont lancées.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/bash-prompt-bluefin"
mkdir -p -- "$state_dir"
exec 9>"$state_dir/install.lock"
flock 9

rc="$HOME/.bashrc"
if [[ -L "$rc" ]]; then
    rc=$(realpath -e -- "$rc") || die "Le lien ~/.bashrc ne mène pas à un fichier existant."
fi
[[ ! -e "$rc" || -f "$rc" ]] || die "$rc doit être un fichier."
if [[ -f "$rc" ]]; then
    bash -n "$rc" || die "Corrige d’abord la syntaxe de $rc."
fi

rc_tmp=
theme_tmp=
font_tmp=
installer_tmp=
trap '[[ -z "$rc_tmp" ]] || rm -f -- "$rc_tmp"; [[ -z "$theme_tmp" ]] || rm -f -- "$theme_tmp"; [[ -z "$font_tmp" ]] || rm -rf -- "$font_tmp"; [[ -z "$installer_tmp" ]] || rm -f -- "$installer_tmp"' EXIT

edit_bashrc() {
    rc_tmp=$(mktemp -- "${rc}.bluefin.XXXXXX")
    if [[ -f "$rc" ]]; then
        cp -p -- "$rc" "$rc_tmp"
    fi
    if [[ -f "$rc" ]] && grep -Fxq -e "$hook" -e "$old_hook" -- "$rc"; then
        awk -v hook="$hook" -v old_hook="$old_hook" '$0 != hook && $0 != old_hook' "$rc" > "$rc_tmp"
    fi
    if [[ "$mode" != --uninstall ]]; then
        # Si le dernier octet n’est pas un saut de ligne, séparer la ligne ajoutée.
        if [[ -s "$rc_tmp" && -n "$(tail -c 1 -- "$rc_tmp")" ]]; then
            printf '\n' >> "$rc_tmp"
        fi
        printf '%s\n' "$hook" >> "$rc_tmp"
    fi
    bash -n "$rc_tmp" || die "Impossible d’ajouter ou de retirer l’activation dans $rc."
    if [[ -f "$rc" ]]; then
        cp -p -- "$rc" "$(mktemp -- "$state_dir/bashrc.XXXXXX")"
    fi
    mv -fT -- "$rc_tmp" "$rc"
    rc_tmp=
}

if [[ "$mode" == --uninstall ]]; then
    if [[ -f "$rc" ]] && grep -Fxq -e "$hook" -e "$old_hook" -- "$rc"; then
        edit_bashrc
    fi
    if [[ -f "$state_dir/konsole-owned" ]]; then
        if [[ "$(kreadconfig6 --file "$konsole_config" --group 'Desktop Entry' --key DefaultProfile)" == Bluefin.profile ]]; then
            previous_profile=$(cat -- "$state_dir/konsole-owned")
            if [[ -n "$previous_profile" ]]; then
                kwriteconfig6 --file "$konsole_config" --group 'Desktop Entry' --key DefaultProfile "$previous_profile"
            else
                kwriteconfig6 --file "$konsole_config" --group 'Desktop Entry' --key DefaultProfile --delete
            fi
        fi
        [[ ! -f "$konsole_profile" ]] || mv -- "$konsole_profile" "$(mktemp -- "$state_dir/Bluefin.profile.XXXXXX")"
        rm -f -- "$state_dir/konsole-owned"
    fi
    for artifact in eza-theme starship-theme starship-bin fonts; do
        [[ -f "$state_dir/$artifact-owned" ]] || continue
        case "$artifact" in
            eza-theme) path=$(cat -- "$state_dir/eza-theme-owned") ;;
            starship-theme) path="$theme" ;;
            starship-bin) path="$bin_dir/starship" ;;
            fonts) path="$font_target" ;;
        esac
        if [[ -e "$path" ]]; then
            mv -- "$path" "$(mktemp -d -- "$state_dir/removed-$artifact.XXXXXX")/"
        fi
        rm -f -- "$state_dir/$artifact-owned"
        if [[ "$artifact" == fonts ]]; then fc-cache -f; fi
    done
    printf '%s\n' 'Bluefin est désinstallé. Ferme et rouvre le terminal.'
    exit 0
fi

[[ -r "$source_dir/starship.toml" ]] || die "starship.toml est introuvable à côté du script."
if ! command -v starship >/dev/null; then
    if [[ ! -x "$bin_dir/starship" ]]; then
        command -v curl >/dev/null || die "Installe curl, puis relance ce script."
        mkdir -p -- "$bin_dir"
        [[ -w "$bin_dir" ]] || die "Impossible d’écrire dans $bin_dir."
        installer_tmp=$(mktemp)
        curl --fail --silent --show-error --location --retry 3 \
            --proto '=https' --proto-redir '=https' \
            https://starship.rs/install.sh -o "$installer_tmp"
        sh "$installer_tmp" --yes --bin-dir "$bin_dir"
        touch -- "$state_dir/starship-bin-owned"
    fi
    export PATH="$bin_dir:$PATH"
fi
starship --version

if [[ "$mode" != --no-font ]]; then
    for dependency in curl unzip sha256sum fc-cache; do
        command -v "$dependency" >/dev/null || die "Commande manquante : $dependency. Voir le README."
    done
    if [[ ! -f "$font_target/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
        [[ ! -e "$font_target" && ! -L "$font_target" ]] || die "Le dossier $font_target existe déjà mais la police est introuvable."
        mkdir -p -- "$font_dir"
        font_tmp=$(mktemp -d -- "$font_dir/.bluefin.XXXXXX")
        mkdir -- "$font_tmp/fonts"
        curl --fail --silent --show-error --location --retry 3 \
            --proto '=https' --proto-redir '=https' \
            https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip \
            -o "$font_tmp/JetBrainsMono.zip"
        (cd -- "$font_tmp" && sha256sum -c <<'SHA256'
fab782a66f7d3019da64f6572db9fc5d3a4bcb19f9fa13e2d8a62e3693d6396e  JetBrainsMono.zip
SHA256
        )
        unzip -q "$font_tmp/JetBrainsMono.zip" -d "$font_tmp/fonts"
        mv -T -- "$font_tmp/fonts" "$font_target"
        touch -- "$state_dir/fonts-owned"
    fi
    fc-cache -f "$font_target"

    if command -v konsole >/dev/null && command -v kwriteconfig6 >/dev/null && command -v kreadconfig6 >/dev/null &&
        [[ ! -e "$konsole_profile" && ! -L "$konsole_profile" ]]; then
        mkdir -p -- "$(dirname -- "$konsole_profile")"
        kreadconfig6 --file "$konsole_config" --group 'Desktop Entry' --key DefaultProfile > "$state_dir/konsole-owned"
        kwriteconfig6 --file "$konsole_profile" --group General --key Name Bluefin
        kwriteconfig6 --file "$konsole_profile" --group Appearance --key Font 'JetBrainsMono Nerd Font,12,-1,5,400,0,0,0,0,0'
        kwriteconfig6 --file "$konsole_config" --group 'Desktop Entry' --key DefaultProfile Bluefin.profile
    fi
fi

if command -v eza >/dev/null && command -v python3 >/dev/null; then
    eza_theme="${EZA_CONFIG_DIR:-$config_home/eza}/theme.yml"
    if [[ ! -e "$eza_theme" && ! -L "$eza_theme" ]]; then
        mkdir -p -- "$(dirname -- "$eza_theme")"
        python3 - "$eza_theme" <<'PYTHON'
import json
from pathlib import Path
import sys

with Path(sys.argv[1]).open("x", encoding="utf-8") as theme:
    theme.write('extensions:\n  sh: {icon: {glyph: ""}}\n  bash: {icon: {glyph: ""}}\nfilenames:\n')
    for name in (".bashrc", ".bash_profile", ".bash_aliases", ".bash_logout"):
        theme.write(f'  {name}: {{icon: {{glyph: ""}}}}\n')
    for path in sorted(Path.home().iterdir()):
        if not path.name.startswith(".") and path.is_dir():
            theme.write(f'  {json.dumps(path.name, ensure_ascii=False)}: {{icon: {{glyph: ""}}}}\n')
PYTHON
        printf '%s\n' "$eza_theme" > "$state_dir/eza-theme-owned"
    fi
fi

mkdir -p -- "$theme_dir"
if [[ ! -e "$theme" && ! -L "$theme" ]]; then
    theme_tmp=$(mktemp -- "$theme_dir/.starship.XXXXXX")
    cat -- "$source_dir/starship.toml" > "$theme_tmp"
    mv -nT -- "$theme_tmp" "$theme"
    touch -- "$state_dir/starship-theme-owned"
fi
[[ -f "$theme" && -r "$theme" ]] || die "Configuration illisible : $theme"
if [[ ! -f "$rc" ]] || ! grep -Fxq -- "$hook" "$rc"; then
    edit_bashrc
fi
printf '%s\n' 'Bluefin est installé. Ferme et rouvre le terminal. Si nécessaire, sélectionne JetBrainsMono Nerd Font en taille 12.'
