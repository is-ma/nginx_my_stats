# Función para aplicar filtro en caliente
apply_filter() {
    local field="$1"
    local value="$2"
    
    # Validar campo
    if [[ -z "${MODE_FIELD[$field]:-}" ]]; then
        return 1
    fi
    
    # Si estamos en modo time, necesitamos convertir el valor del intervalo
    # a un filtro de rango para jq
    if [[ "$field" == "time" ]]; then
        # Buscar el intervalo correspondiente en los arrays
        local interval_index=-1
        for i in "${!TIME_INTERVAL_LABELS[@]}"; do
            if [[ "${TIME_INTERVAL_LABELS[$i]}" == "$value" ]]; then
                interval_index=$i
                break
            fi
        done
        
        if [[ $interval_index -eq -1 ]]; then
            return 1  # Intervalo no encontrado
        fi
        
        local min_val="${TIME_INTERVAL_MIN[$interval_index]}"
        local max_val="${TIME_INTERVAL_MAX[$interval_index]}"
        
        # Construir condición de filtro para jq
        if [[ "$max_val" == "inf" ]]; then
            FILTER_FIELD="$field"
            FILTER_VALUE=">=$min_val"  # Usaremos un formato especial para rango
        else
            FILTER_FIELD="$field"
            FILTER_VALUE="range:$min_val:$max_val"  # Formato especial para rango
        fi
    else
        FILTER_FIELD="$field"
        FILTER_VALUE="$value"
    fi
    
    # Reconfigurar según el periodo actual
    stop_tail
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        start_tail
    else
        load_data
    fi
}

# Función para quitar filtro en caliente
remove_filter() {
    if [[ -n "$FILTER_FIELD" ]]; then
        FILTER_FIELD=""
        FILTER_VALUE=""
        
        # Reconfigurar según el periodo actual
        stop_tail
        if [[ "$CURRENT_PERIOD" == "now" ]]; then
            start_tail
        else
            load_data
        fi
    fi
}
