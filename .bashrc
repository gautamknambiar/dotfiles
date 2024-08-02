eval "$(/opt/homebrew/bin/brew shellenv)"

BASH_D="$HOME/.bash.d"
LOGO_FILE="$HOME/.config/fastfetch/logo.txt"
CONFIG_FILE="$HOME/.config/fastfetch/config_src.jsonc"

cat "$HOME/.config/fastfetch/newcomp.txt" > "$LOGO_FILE"

if [[ -d "$BASH_D" ]]; then
    totalfiles=0
    total_length=45
    printf "\n╔═════════════════════════════════════════════╗\n" >> "$LOGO_FILE"
    printf "║                \$2SOURCED FILES\$1                ║\n" >> "$LOGO_FILE"
    printf "╠═════════════════════════════════════════════╣\n" >> "$LOGO_FILE"

    for file in "$BASH_D"/*; do
        if [[ -f "$file" && -r "$file" ]]; then
            ((totalfiles++))
            source "$file"
            filename=$(basename "$file")
            filename_length=${#filename}
            padding_length=$(( (total_length - filename_length) / 2 ))
            padding=""

            for (( i=0; i<padding_length; i++ )); do
                padding+=" "
            done

            if (( (total_length - filename_length) % 2 != 0 )); then
                filename="$filename "
            fi

            printf "║%s\$2%s\$1%s║\n" "$padding" "$filename" "$padding" >> "$LOGO_FILE"
        fi
    done
else
    echo "Directory $BASH_D does not exist."
fi

printf "╚═════════════════════════════════════════════╝" >> "$LOGO_FILE"

top_value=$(( (13 - totalfiles) / 2 ))
if (( top_value < 0 )); then
    top_value=0
fi

jq --argjson newTop "$top_value" '.logo.padding.top = $newTop' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

fastfetch --load-config ~/.config/fastfetch/config_src.jsonc

rm -f $LOGO_FILE

cleanpath -q
