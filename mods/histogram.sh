# Función para calcular el histograma desde TEMP_FILE
compute_histogram() {
    local histogram_raw
    local line_num=0

    histogram_raw=$(sort "$TEMP_FILE" 2>/dev/null | uniq -c | sort -snr | head -n "$TOP_N")

    HISTOGRAM_VALUES=()
    CACHED_HISTOGRAM=""
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local value
            value=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
            HISTOGRAM_VALUES+=("$value")

            if [[ $line_num -lt 10 ]]; then
                CACHED_HISTOGRAM+="$line_num $line"$'\n'
            else
                CACHED_HISTOGRAM+="  $line"$'\n'
            fi
            ((line_num++))
        fi
    done <<< "$histogram_raw"
}

# Función para mostrar el histograma (sin parpadeo)
show_histogram() {
    local highlight_q="${1:-false}"
    local output
    local prop_line
    local period_line
    local filter_line

    # En modo now, recalcular cada vez; en otros modos, usar cache
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        compute_histogram
    fi

    # Construir línea de propiedades
    prop_line="Función: "
    prop_line+="$(format_option d date "$CURRENT_MODE" date)"
    prop_line+="  "
    prop_line+="$(format_option i ip "$CURRENT_MODE" ip)"
    prop_line+="  "
    prop_line+="$(format_option m method "$CURRENT_MODE" method)"
    prop_line+="  "
    prop_line+="$(format_option s status "$CURRENT_MODE" status)"
    prop_line+="  "
    prop_line+="$(format_option a agent "$CURRENT_MODE" ua)"
    prop_line+="  "
    prop_line+="$(format_option u uri "$CURRENT_MODE" uri)"
    prop_line+="  "
    prop_line+="$(format_option k cache "$CURRENT_MODE" cache)"
    prop_line+="  "
    prop_line+="$(format_option l lang "$CURRENT_MODE" lang)"
    prop_line+="  "
    prop_line+="$(format_option r referer "$CURRENT_MODE" referer)"
    prop_line+="  "
    prop_line+="$(format_option o host "$CURRENT_MODE" host)"
    prop_line+="  "
    prop_line+="$(format_option g log "$CURRENT_MODE" log)"

    # Construir línea de CUANTOS
    period_line="Cantidad: "
    period_line+="$(format_option n now "$CURRENT_PERIOD" now)"
    period_line+="  "
    period_line+="$(format_option h hundred "$CURRENT_PERIOD" hundred)"
    period_line+="  "
    period_line+="$(format_option t thousand "$CURRENT_PERIOD" thousand)"
    period_line+="  "
    period_line+="$(format_option c complete "$CURRENT_PERIOD" complete)"

    # Construir línea de filtro usando la nueva función
    filter_line=$(format_filter_line)

    output=$(printf '\033[H\033[J')
    output+="=== ${MODE_TITLE[$CURRENT_MODE]} (${PERIOD_TITLE[$CURRENT_PERIOD]}) ==="
    output+=$'\n'
    output+="$prop_line"
    output+=$'\n'
    output+="$period_line"
    output+=$'\n'
    output+="$filter_line"
    output+=$'\n'
    # Definir colores
    local yellow_start=$'\e[93m'
    local reset=$'\e[0m'
    if [[ "$highlight_q" == "true" ]]; then
        output+="Salir: [${yellow_start}q${reset}]"
    else
        output+="Salir: [q]"
    fi
    output+=$'\n\n'
    output+="F      #  ${MODE_HEADER[$CURRENT_MODE]}"
    output+=$'\n'
    output+="$CACHED_HISTOGRAM"

    printf '%s' "$output"
}
