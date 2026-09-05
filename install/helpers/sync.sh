#!/usr/bin/env bash

# Sincronizacion de arboles de configuracion (sin rsync, bash + cp).

# Copia el contenido de <src> dentro de <dest>, sobrescribiendo.
# Se usa para semillas de primera instalacion (/etc/skel, overlay de /etc).
x_copy_tree() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || return 0
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
}

# Siembra <home> desde <skel>: copia solo lo que falta, sin pisar lo del usuario.
x_seed_home() {
    local skel="$1" home="$2" p
    [[ -d "$skel" ]] || return 0
    mkdir -p "$home"
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        if [[ -e "$home/$p" ]]; then
            continue
        fi
        if [[ -d "$skel/$p" ]]; then
            mkdir -p "$home/$p"
        else
            install -D -m 644 "$skel/$p" "$home/$p"
        fi
    done < <(cd "$skel" && find . -mindepth 1 | sort)
}

# Sincroniza un arbol de dotfiles a <dest>. Los ficheros existentes que
# difieran se respaldan como <fichero>.bak.<ts> antes de sobrescribirse.
x_sync_config() {
    local src="$1" dest="$2" ts rel from to
    [[ -d "$src" ]] || return 0
    ts="${X_TS:-$(date +%Y%m%d%H%M%S)}"
    mkdir -p "$dest"
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        from="$src/$rel"
        to="$dest/$rel"
        if [[ -d "$from" ]]; then
            mkdir -p "$to"
            continue
        fi
        if [[ -e "$to" ]] && ! cmp -s "$from" "$to"; then
            mv "$to" "$to.bak.$ts"
        fi
        if [[ ! -e "$to" ]]; then
            mkdir -p "$(dirname "$to")"
            cp -p "$from" "$to"
        fi
    done < <(cd "$src" && find . -mindepth 1 | sort)
}
