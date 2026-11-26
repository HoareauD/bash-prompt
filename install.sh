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
theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin"
theme="$theme_dir/starship.toml"
hook='if [[ $- == *i* ]] && command -v starship >/dev/null && [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml" ]]; then export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/bash-prompt-bluefin/starship.toml"; declare -F starship_precmd >/dev/null || eval "$(starship init bash)"; fi # bash-prompt-bluefin'

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
trap '[[ -z "$rc_tmp" ]] || rm -f -- "$rc_tmp"; [[ -z "$theme_tmp" ]] || rm -f -- "$theme_tmp"; [[ -z "$font_tmp" ]] || rm -rf -- "$font_tmp"' EXIT

edit_bashrc() {
    rc_tmp=$(mktemp -- "${rc}.bluefin.XXXXXX")
    if [[ -f "$rc" ]]; then
        cp -p -- "$rc" "$rc_tmp"
    fi
    if [[ "$mode" == --uninstall ]]; then
        awk -v hook="$hook" '$0 != hook' "$rc" > "$rc_tmp"
    else
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
    if [[ -f "$rc" ]] && grep -Fxq -- "$hook" "$rc"; then
        edit_bashrc
    fi
    printf '%s\n' 'Bluefin est désactivé. Ouvre un nouveau terminal.'
    exit 0
fi

[[ -r "$source_dir/starship.toml" ]] || die "starship.toml est introuvable à côté du script."
if ! command -v starship >/dev/null; then
    if [[ -e /run/ostree-booted ]]; then
        die "Sur Fedora Atomic, lance sudo rpm-ostree install starship, redémarre, puis relance ce script."
    fi
    command -v dnf >/dev/null || die "Installe Starship depuis https://starship.rs/guide/ puis relance ce script."
    sudo dnf install starship
fi
starship --version

if [[ "$mode" != --no-font ]]; then
    for dependency in curl tar xz sha256sum fc-list fc-cache; do
        command -v "$dependency" >/dev/null || die "Commande manquante : $dependency. Voir le README."
    done
    font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    version=v3.5.1
    font_target="$font_dir/JetBrainsMonoNerdFontMono-bluefin-$version"
    if [[ -d "$font_target" ]]; then
        fc-cache -f "$font_target"
    else
        installed_families=$(fc-list --format '%{family}\n')
        if [[ "$installed_families" != *'JetBrainsMono Nerd Font Mono'* ]]; then
            mkdir -p -- "$font_dir"
            font_tmp=$(mktemp -d -- "$font_dir/.bluefin.XXXXXX")
            mkdir -- "$font_tmp/fonts"
            curl --fail --silent --show-error --location --retry 3 \
                --proto '=https' --proto-redir '=https' \
                "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/JetBrainsMono.tar.xz" \
                -o "$font_tmp/JetBrainsMono.tar.xz"
            (cd -- "$font_tmp" && sha256sum -c <<'SHA256'
04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf  JetBrainsMono.tar.xz
SHA256
            )
            tar -xJf "$font_tmp/JetBrainsMono.tar.xz" -C "$font_tmp/fonts" \
                --wildcards --no-same-owner 'JetBrainsMonoNerdFontMono-*.ttf' 'OFL.txt'
            mv -nT -- "$font_tmp/fonts" "$font_target"
            fc-cache -f "$font_target"
        fi
    fi
fi

mkdir -p -- "$theme_dir"
if [[ ! -e "$theme" && ! -L "$theme" ]]; then
    theme_tmp=$(mktemp -- "$theme_dir/.starship.XXXXXX")
    cat -- "$source_dir/starship.toml" > "$theme_tmp"
    mv -nT -- "$theme_tmp" "$theme"
fi
[[ -f "$theme" && -r "$theme" ]] || die "Configuration illisible : $theme"
if [[ ! -f "$rc" ]] || ! grep -Fxq -- "$hook" "$rc"; then
    edit_bashrc
fi
printf '%s\n' 'Bluefin est installé. Ouvre un nouveau terminal Bash et sélectionne JetBrainsMono Nerd Font Mono dans ton profil.'
