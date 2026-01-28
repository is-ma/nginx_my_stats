# Función para calcular el histograma desde TEMP_FILE
compute_histogram() {
    local histogram_raw
    local line_num=0

    # Si estamos en modo time, usar la función especial
    if [[ "$CURRENT_MODE" == "time" ]]; then
        compute_time_histogram
        return
    fi

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

# Función especial para calcular histograma de tiempos por intervalos
compute_time_histogram() {
    # Construir script awk usando los intervalos definidos
    local awk_script='BEGIN {'
    for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
        awk_script+=" counts[$i]=0;"
    done
    awk_script+=' total=0; }'
    awk_script+=' { if ($0 == "") next; t = $1 + 0; '
    for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
        local min_val="${TIME_INTERVAL_MIN[$i]}"
        local max_val="${TIME_INTERVAL_MAX[$i]}"
        if [[ "$max_val" == "inf" ]]; then
            awk_script+=" if (t >= $min_val) { counts[$i]++; total++; next; } "
        else
            awk_script+=" if (t >= $min_val && t < $max_val) { counts[$i]++; total++; next; } "
        fi
    done
    awk_script+=' }'
    awk_script+=" END { for (i=0; i<$NUM_TIME_INTERVALS; i++) print counts[i]; print total; }"
    
    local results
    results=$(awk "$awk_script" "$TEMP_FILE" 2>/dev/null)
    
    local counts=()
    local total_count=0
    if [[ -n "$results" ]]; then
        # Leer conteos
        local i=0
        while IFS= read -r line; do
            if [[ $i -lt $NUM_TIME_INTERVALS ]]; then
                counts[$i]=$line
            else
                total_count=$line
            fi
            ((i++))
        done <<< "$results"
    else
        # Archivo vacío: todos ceros
        for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
            counts[$i]=0
        done
    fi
    
    HISTOGRAM_VALUES=()
    CACHED_HISTOGRAM=""
    
    for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
        local label="${TIME_INTERVAL_LABELS[$i]}"
        local count="${counts[$i]}"
        local line
        
        if [[ $i -lt 10 ]]; then
            line=$(printf "%-6s %s" "$count" "$label")
            CACHED_HISTOGRAM+="$i $line"$'\n'
        else
            line=$(printf "%-6s %s" "$count" "$label")
            CACHED_HISTOGRAM+="  $line"$'\n'
        fi
        
        HISTOGRAM_VALUES+=("$label")
    done
    
    if [[ $total_count -gt 0 ]]; then
        CACHED_HISTOGRAM=$(echo -e "Total: $total_count\n$CACHED_HISTOGRAM")
    fi
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
