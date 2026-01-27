# Función de limpieza
cleanup() {
    stty echo 2>/dev/null || true

    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi

    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi

    echo ""
    exit 0
}

# Función para formatear opción (mayúsculas si activa)
format_option() {
    local key="$1"
    local label="$2"
    local current="$3"
    local match="$4"
    local yellow_start=$'\e[93m'
    local reset=$'\e[0m'

    if [[ "$current" == "$match" ]]; then
        printf "[%s%s%s] %s%s%s" "$yellow_start" "$key" "$reset" "$yellow_start" "$label" "$reset"
    else
        printf "[%s] %s" "$key" "$label"
    fi
}

# Función para formatear línea de resultados máximos
format_max_results_line() {
    local yellow_start=$'\e[93m'
    local reset=$'\e[0m'
    
    local line="Resultados: "
    
    # Opción ten
    if [[ "$CURRENT_MAX_RESULTS" == "ten" ]]; then
        line+="[${yellow_start}e${reset}] ${yellow_start}ten${reset}"
    else
        line+="[e] ten"
    fi
    
    line+="  "
    
    # Opción twenty
    if [[ "$CURRENT_MAX_RESULTS" == "twenty" ]]; then
        line+="[${yellow_start}w${reset}] ${yellow_start}twenty${reset}"
    else
        line+="[w] twenty"
    fi
    
    line+="  "
    
    # Opción thirty
    if [[ "$CURRENT_MAX_RESULTS" == "thirty" ]]; then
        line+="[${yellow_start}y${reset}] ${yellow_start}thirty${reset}"
    else
        line+="[y] thirty"
    fi
    
    echo "$line"
}

# Función para formatear línea de filtro
format_filter_line() {
    local yellow_start=$'\e[93m'
    local reset=$'\e[0m'
    
    if [[ -n "$FILTER_FIELD" ]]; then
        # Con filtro: [f] en amarillo, "sí" en minúsculas, y el filtro en amarillo
        printf "Filtro: [%sf%s] sí (%s%s%s: %s%s%s)" \
            "$yellow_start" "$reset" \
            "$yellow_start" "$FILTER_FIELD" "$reset" \
            "$yellow_start" "$FILTER_VALUE" "$reset"
    else
        # Sin filtro: solo "no" en minúsculas, sin 'f'
        printf "Filtro: no"
    fi
}
