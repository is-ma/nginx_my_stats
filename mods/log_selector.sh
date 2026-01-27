# Variable para guardar el archivo de log base (el original)
BASE_LOG_FILE=""

# Variable para guardar el modo anterior antes de entrar al selector de log
PREVIOUS_MODE=""

# Función para listar archivos de log disponibles
list_log_files() {
    local log_dir
    local base_name
    
    # Si no tenemos el archivo base guardado, guardarlo ahora
    if [[ -z "$BASE_LOG_FILE" ]]; then
        # Extraer el nombre base sin sufijos de fecha
        # Esto maneja casos como shield_access.log-20260127 -> shield_access.log
        BASE_LOG_FILE=$(echo "$LOG_FILE" | sed 's/-[0-9]\{8\}$//')
    fi
    
    log_dir=$(dirname "$BASE_LOG_FILE")
    base_name=$(basename "$BASE_LOG_FILE")
    
    # Buscar archivos que coincidan con el patrón
    # Primero el archivo actual, luego los rotados ordenados por fecha
    local files=()
    
    # Añadir el archivo principal si existe
    if [[ -f "$BASE_LOG_FILE" ]]; then
        files+=("$BASE_LOG_FILE")
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
    
    printf '%s' "$output"
}

# Función para cambiar el archivo de log y volver al modo anterior
change_log_file() {
    local index="$1"
    
    if [[ -n "${LOG_FILES[$index]:-}" ]]; then
        # Cambiar el archivo de log
        LOG_FILE="${LOG_FILES[$index]}"
        
        # Restaurar el modo anterior (guardado antes de entrar al selector)
        if [[ -n "$PREVIOUS_MODE" ]]; then
            CURRENT_MODE="$PREVIOUS_MODE"
        else
            CURRENT_MODE="ip"
        fi
        
        # Recargar datos según el periodo actual
        if [[ "$CURRENT_PERIOD" == "now" ]]; then
            start_tail
        else
            load_data
        fi
    fi
}
