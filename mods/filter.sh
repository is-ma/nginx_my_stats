# Función para aplicar filtro en caliente
apply_filter() {
    local field="$1"
    local value="$2"
    
    # Validar campo
    if [[ -z "${MODE_FIELD[$field]:-}" ]]; then
        return 1
    fi
    
    FILTER_FIELD="$field"
    FILTER_VALUE="$value"
    
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
