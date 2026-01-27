# Función para listar archivos de log disponibles
list_log_files() {
    local base_log="$LOG_FILE"
    local log_dir
    local base_name
    
    log_dir=$(dirname "$base_log")
    base_name=$(basename "$base_log")
    
    # Buscar archivos que coincidan con el patrón
    # Primero el archivo actual, luego los rotados ordenados por fecha
    local files=()
    
    # Añadir el archivo principal si existe
    if [[ -f "$base_log" ]]; then
        files+=("$base_log")
    fi
    
    # Añadir archivos rotados (ordenados por fecha, más reciente primero)
    while IFS= read -r file; do
        files+=("$file")
    done < <(sudo ls -t "$log_dir/${base_name}"-* 2>/dev/null | head -n 9)
    
    # Guardar en array global
    LOG_FILES=("${files[@]}")
}

# Función para mostrar selector de logs
show_log_selector() {
    local output
    local line_num=0
    
    output=$(printf '\033[H\033[J')
    output+="=== Selector de Log ==="
    output+=$'\n\n'
    output+="F       Log File"
    output+=$'\n'
    
    for log_file in "${LOG_FILES[@]}"; do
        if [[ $line_num -lt 10 ]]; then
            output+="$line_num       $log_file"
            output+=$'\n'
        fi
        ((line_num++))
    done
    
    output+=$'\n'
    output+="Presiona un número para seleccionar el log, o 'q' para volver"
    
    printf '%s' "$output"
}

# Función para cambiar el archivo de log y reiniciar
change_log_file() {
    local index="$1"
    
    if [[ -n "${LOG_FILES[$index]:-}" ]]; then
        local new_log="${LOG_FILES[$index]}"
        
        # Construir comando para relanzar el script con los mismos parámetros
        local cmd="$0"
        cmd+=" --access-log \"$new_log\""
        cmd+=" --mode \"$CURRENT_MODE\""
        cmd+=" --how-many \"$CURRENT_PERIOD\""
        
        if [[ -n "$FILTER_FIELD" ]]; then
            cmd+=" --filter-field \"$FILTER_FIELD\""
            cmd+=" --filter-value \"$FILTER_VALUE\""
        fi
        
        # Limpiar y ejecutar
        cleanup
        exec bash -c "$cmd"
    fi
}
