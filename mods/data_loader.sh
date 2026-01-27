# Construir expresión jq con filtro opcional
build_jq_expr() {
    local field="$1"
    local filter_field="$2"
    local filter_value="$3"

    if [[ -n "$filter_field" ]]; then
        # Usar contains para strings, == para números
        if [[ "$filter_field" == "status" ]]; then
            echo "select(.$filter_field == $filter_value) | $field"
        else
            echo "select(.$filter_field | tostring | contains(\"$filter_value\")) | $field"
        fi
    else
        echo "$field"
    fi
}

# Función para cargar datos según el periodo
load_data() {
    local field="${MODE_FIELD[$CURRENT_MODE]}"
    local lines
    local jq_expr

    case "$CURRENT_PERIOD" in
        hundred)  lines=100 ;;
        thousand) lines=1000 ;;
        complete) lines="" ;;
        *)        return ;; # now no usa esta función
    esac

    # Limpiar archivo temporal existente
    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
    
    # Crear nuevo archivo temporal
    TEMP_FILE=$(mktemp /tmp/nginx_stats_XXXXXX.tmp)

    jq_expr=$(build_jq_expr "$field" "$FILTER_FIELD" "$FILTER_VALUE")

    if [[ -n "$lines" ]]; then
        sudo tail -n "$lines" "$LOG_FILE" | jq -r "$jq_expr" > "$TEMP_FILE"
    else
        sudo jq -r "$jq_expr" "$LOG_FILE" > "$TEMP_FILE"
    fi

    # Calcular histograma una sola vez para modos estáticos
    compute_histogram
}

# Función para iniciar el tail con el campo actual (modo now)
start_tail() {
    local field="${MODE_FIELD[$CURRENT_MODE]}"
    local jq_expr

    # Limpiar archivo temporal existente
    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
    
    # Crear nuevo archivo temporal
    TEMP_FILE=$(mktemp /tmp/nginx_stats_XXXXXX.tmp)

    jq_expr=$(build_jq_expr "$field" "$FILTER_FIELD" "$FILTER_VALUE")

    sudo tail -f "$LOG_FILE" | jq --unbuffered -r "$jq_expr" >> "$TEMP_FILE" &
    TAIL_PID=$!
}

# Función para detener el tail actual
stop_tail() {
    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi
    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
    TAIL_PID=""
    TEMP_FILE=""
}

# Función para cambiar modo en caliente
change_mode() {
    local new_mode="$1"
    
    # Validar modo
    if [[ -z "${MODE_FIELD[$new_mode]:-}" ]]; then
        return 1
    fi
    
    CURRENT_MODE="$new_mode"
    
    # Si es modo log, no iniciar tail ni cargar datos
    if [[ "$new_mode" == "log" ]]; then
        stop_tail
        list_log_files
        return 0
    fi
    
    # Si estamos en modo now, reiniciar tail con el nuevo campo
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        stop_tail
        start_tail
    else
        # Para modos estáticos, recargar datos
        load_data
    fi
}

# Función para cambiar CUANTOS en caliente
change_period() {
    local new_period="$1"
    
    # Validar periodo
    if [[ -z "${PERIOD_TITLE[$new_period]:-}" ]]; then
        return 1
    fi
    
    CURRENT_PERIOD="$new_period"
    
    # Detener tail si existe
    stop_tail
    
    # Iniciar según el nuevo periodo
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        start_tail
    else
        load_data
    fi
}
