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

# Función para renderizar el contenido del histograma (sin menú)
render_histogram_content() {
    # En modo now, recalcular cada vez; en otros modos, usar cache
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        compute_histogram
    fi

    local content=""
    content+="F      #  ${MODE_HEADER[$CURRENT_MODE]}"
    content+=$'\n'
    content+="$CACHED_HISTOGRAM"
    
    echo "$content"
}
