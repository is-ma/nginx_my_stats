# Módulo para renderizar el menú común
# Dependencias: necesita acceso a variables globales del script principal

# Función para renderizar el encabezado
render_header() {
    local title="${MODE_TITLE[$CURRENT_MODE]}"
    local period="${PERIOD_TITLE[$CURRENT_PERIOD]}"
    echo "=== ${title} (${period}) ==="
}

# Función para renderizar el menú (propiedades, cantidad, resultados, filtro, salir)
render_menu() {
    local highlight_q="${1:-false}"
    local prop_line
    local period_line
    local max_results_line
    local filter_line
    local exit_line

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

    # Construir línea de resultados máximos
    max_results_line=$(format_max_results_line)

    # Construir línea de filtro
    filter_line=$(format_filter_line)

    # Construir línea de salida
    local yellow_start=$'\e[93m'
    local reset=$'\e[0m'
    if [[ "$highlight_q" == "true" ]]; then
        exit_line="Salir: [${yellow_start}q${reset}]"
    else
        exit_line="Salir: [q]"
    fi

    echo "$prop_line"
    echo "$period_line"
    echo "$max_results_line"
    echo "$filter_line"
    echo "$exit_line"
}

# Función principal para renderizar la pantalla completa
render_screen() {
    local content="$1"
    local highlight_q="${2:-false}"
    
    # Limpiar pantalla
    local output=$(printf '\033[H\033[J')
    
    # Agregar línea del archivo de log
    local log_name
    log_name=$(basename "$LOG_FILE")
    output+="### Log: $log_name"
    output+=$'\n'
    
    # Agregar encabezado
    output+=$(render_header)
    output+=$'\n'
    
    # Agregar menú
    output+=$(render_menu "$highlight_q")
    output+=$'\n'
    
    # Agregar contenido específico
    # Eliminar nueva línea al final si existe
    content="${content%$'\n'}"
    output+="$content"
    
    # Agregar línea en blanco y prompt de opción
    output+=$'\n'
    output+=$'\n'
    output+="Opción: "
    
    printf '%s' "$output"
}
