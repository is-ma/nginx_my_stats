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
    local line_num=0
    local counts=()
    local total_count=0
    
    # Inicializar array de conteos
    for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
        counts[$i]=0
    done
    
    # Leer tiempos y contar por intervalos
    while IFS= read -r time_str; do
        if [[ -n "$time_str" ]]; then
            # Convertir a número (manejar posibles comillas o formato string)
            local time_val=$(echo "$time_str" | sed 's/"//g')
            
            # Determinar en qué intervalo cae
            for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
                local min_val="${TIME_INTERVAL_MIN[$i]}"
                local max_val="${TIME_INTERVAL_MAX[$i]}"
                
                if [[ "$max_val" == "inf" ]]; then
                    # Último intervalo: t ≥ min_val
                    if (( $(echo "$time_val >= $min_val" | bc -l) )); then
                        ((counts[$i]++))
                        ((total_count++))
                        break
                    fi
                else
                    # Intervalo normal: min_val ≤ t < max_val
                    if (( $(echo "$time_val >= $min_val && $time_val < $max_val" | bc -l) )); then
                        ((counts[$i]++))
                        ((total_count++))
                        break
                    fi
                fi
            done
        fi
    done < "$TEMP_FILE"
    
    # Construir histograma ordenado por conteo (pero mostramos todos los intervalos)
    # Para el modo time, queremos mostrar los intervalos en orden fijo, no ordenados por frecuencia
    # Pero para mantener consistencia con el formato, podemos mostrarlos en orden fijo
    
    HISTOGRAM_VALUES=()
    CACHED_HISTOGRAM=""
    
    for ((i=0; i<NUM_TIME_INTERVALS; i++)); do
        local label="${TIME_INTERVAL_LABELS[$i]}"
        local count="${counts[$i]}"
        local line
        
        # Solo mostrar si hay datos o si es uno de los primeros 10 para selección
        # (mostramos todos los intervalos como solicitaste)
        if [[ $i -lt 10 ]]; then
            line=$(printf "%-6s %s" "$count" "$label")
            CACHED_HISTOGRAM+="$i $line"$'\n'
        else
            line=$(printf "%-6s %s" "$count" "$label")
            CACHED_HISTOGRAM+="  $line"$'\n'
        fi
        
        # Guardar el label en HISTOGRAM_VALUES para filtrado
        HISTOGRAM_VALUES+=("$label")
    done
    
    # Añadir línea total si hay datos
    if [[ $total_count -gt 0 ]]; then
        CACHED_HISTOGRAM=$(echo -e "Total: $total_count\n$CACHED_HISTOGRAM")
    fi
}

# Función para renderizar el contenido del histograma (sin menú)
render_histogram_content() {
    # En modo now, recalcular cada vez; en otros modos, usar cache
    if [[ "$CURRENT_PERIOD" == "now" ]] || [[ "$CURRENT_MODE" == "time" ]]; then
        # Para el modo time, siempre recalcular para mostrar conteos actualizados
        # Para otros modos, mantener el comportamiento original
        if [[ "$CURRENT_MODE" == "time" ]]; then
            compute_histogram
        elif [[ "$CURRENT_PERIOD" == "now" ]]; then
            compute_histogram
        fi
    fi

    local content=""
    content+="F      #  ${MODE_HEADER[$CURRENT_MODE]}"
    content+=$'\n'
    content+="$CACHED_HISTOGRAM"
    
    echo "$content"
}
