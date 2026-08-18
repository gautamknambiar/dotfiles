# Shared loader for bash and zsh dotfile fragments.

dotfiles_load_profile() {
    local profile_file="${DOTFILES_PROFILE_FILE:-}"
    local local_home
    local local_profile_file

    if [[ -z "$profile_file" ]]; then
        profile_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.sh"
        if [[ ! -r "$profile_file" && -r "${DOTFILES_DIR:-$HOME/dotfiles}/.config/dotfiles/profile.sh" ]]; then
            profile_file="${DOTFILES_DIR:-$HOME/dotfiles}/.config/dotfiles/profile.sh"
        fi
    fi

    if [[ -r "$profile_file" ]]; then
        . "$profile_file"
    fi

    local_home="${DOTFILES_LOCAL_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles}"
    local_profile_file="${DOTFILES_LOCAL_PROFILE_FILE:-$local_home/profile.sh}"

    if [[ "$local_profile_file" != "$profile_file" && -r "$local_profile_file" ]]; then
        . "$local_profile_file"
    fi
}

dotfiles_should_source() {
    local name="${1##*/}"

    [[ "$name" == .* ]] && return 1

    case " ${DOTFILES_SOURCE_EXCLUDE:-} " in
        *" $name "*) return 1 ;;
    esac

    if [[ -n "${DOTFILES_SOURCE_INCLUDE:-}" ]]; then
        case " $DOTFILES_SOURCE_INCLUDE " in
            *" $name "*) return 0 ;;
            *) return 1 ;;
        esac
    fi

    return 0
}

dotfiles_emit() {
    local output_file="$1"
    local format="$2"
    shift
    shift

    if [[ -n "$output_file" ]]; then
        printf "$format" "$@" >> "$output_file"
    else
        printf "$format" "$@"
    fi
}

dotfiles_record_sourced_file() {
    local filename="$1"

    DOTFILES_SOURCED_FILES="${DOTFILES_SOURCED_FILES}${filename}"$'\n'
    DOTFILES_SOURCED_COUNT=$((DOTFILES_SOURCED_COUNT + 1))
}

dotfiles_source_dir() {
    local source_dir="$1"
    local file
    local filename

    DOTFILES_SOURCED_FILES=""
    DOTFILES_SOURCED_COUNT=0

    if [[ ! -d "$source_dir" ]]; then
        echo "Directory $source_dir does not exist."
        return 1
    fi

    while IFS= read -r file; do
        [[ -r "$file" ]] || continue

        if dotfiles_should_source "$file"; then
            . "$file"
            filename="${file##*/}"
            dotfiles_record_sourced_file "$filename"
        fi
    # The install script symlinks ~/.bash.d and ~/.zsh.d to this repo.
    done < <(find -L "$source_dir" -maxdepth 1 -type f -print | sort)
}

dotfiles_render_sourced_files() {
    local output_file="${1:-}"
    local output_style="${2:-terminal}"
    local total_length=45
    local color_start=""
    local color_end=""
    local filename
    local filename_length
    local padding_length
    local padding
    local i

    case "$output_style" in
        fastfetch)
            color_start='$2'
            color_end='$1'
            ;;
        terminal)
            color_start="${FG_GREEN:-}"
            color_end="${TXT_RESET:-}"
            ;;
    esac

    dotfiles_emit "$output_file" "╔═════════════════════════════════════════════╗\n"
    dotfiles_emit "$output_file" "║                %sSOURCED FILES%s                ║\n" "$color_start" "$color_end"
    dotfiles_emit "$output_file" "╠═════════════════════════════════════════════╣\n"

    while IFS= read -r filename; do
        [[ -n "$filename" ]] || continue

        filename_length=${#filename}
        padding_length=$(( (total_length - filename_length) / 2 ))
        padding=""

        for ((i=0; i<padding_length; i++)); do
            padding+=" "
        done

        if (( (total_length - filename_length) % 2 != 0 )); then
            filename="$filename "
        fi

        dotfiles_emit "$output_file" "║%s%s%s%s%s║\n" "$padding" "$color_start" "$filename" "$color_end" "$padding"
    done <<< "$DOTFILES_SOURCED_FILES"

    dotfiles_emit "$output_file" "╚═════════════════════════════════════════════╝"
}

dotfiles_show_fastfetch() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local runtime_home="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
    local runtime_dir
    local logo_file
    local generated_config
    local config_file="${CONFIG_FILE:-$config_home/fastfetch/config_src.jsonc}"
    local newcomp_file="$config_home/fastfetch/newcomp.txt"
    local top_value
    local fastfetch_status

    [[ -f "$newcomp_file" ]] || return 1
    [[ -f "$config_file" ]] || return 1
    command -v jq >/dev/null 2>&1 || return 1
    command -v fastfetch >/dev/null 2>&1 || return 1

    runtime_dir="$(mktemp -d "${runtime_home%/}/dotfiles-shell-motd.XXXXXX")" || return 1
    logo_file="${LOGO_FILE:-$runtime_dir/fastfetch-logo.txt}"
    generated_config="$runtime_dir/fastfetch-config.jsonc"

    cat "$newcomp_file" > "$logo_file"
    printf "\n" >> "$logo_file"
    dotfiles_render_sourced_files "$logo_file" fastfetch
    printf "\n" >> "$logo_file"

    top_value=$(( (13 - DOTFILES_SOURCED_COUNT) / 2 ))
    if (( top_value < 0 )); then
        top_value=0
    fi

    if ! jq --argjson newTop "$top_value" --arg logoSource "$logo_file" \
        '.logo.padding.top = $newTop | .logo.source = $logoSource' \
        "$config_file" > "$generated_config"; then
        rm -f "$logo_file" "$generated_config"
        rmdir "$runtime_dir" 2>/dev/null || true
        return 1
    fi

    fastfetch --config "$generated_config"
    fastfetch_status=$?
    rm -f "$logo_file" "$generated_config"
    rmdir "$runtime_dir" 2>/dev/null || true
    return "$fastfetch_status"
}

dotfiles_daily_motd() {
    local shell_name="$1"
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
    local stamp_dir="$state_home/dotfiles/shell-motd"
    local stamp_file="$stamp_dir/${shell_name}-fastfetch.last"
    local today

    today=$(date +%F)
    mkdir -p "$stamp_dir"

    if [[ -r "$stamp_file" ]] && [[ "$(cat "$stamp_file")" == "$today" ]]; then
        dotfiles_render_sourced_files "" terminal
        printf "\n"
        return
    fi

    if dotfiles_show_fastfetch; then
        printf '%s\n' "$today" > "$stamp_file"
    else
        dotfiles_render_sourced_files "" terminal
        printf "\n"
    fi
}

dotfiles_init_shell() {
    local shell_name="$1"
    local source_dir="$2"

    DOTFILES_SHELL_NAME="$shell_name"
    DOTFILES_SHELL_DIR="$source_dir"

    dotfiles_load_profile
    dotfiles_source_dir "$source_dir" || return
    dotfiles_daily_motd "$shell_name"
}

re-source() {
    dotfiles_load_profile
    dotfiles_source_dir "$DOTFILES_SHELL_DIR" || return
    dotfiles_render_sourced_files "" terminal
    printf "\n"
}
