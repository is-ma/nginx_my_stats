#!/bin/bash

# =================================================
# nginx_stats - Panel de estadísticas Nginx
# =================================================
# Muestra histogramas de diferentes campos del log
# de Nginx con navegación por teclado
#
# Uso:
#   nginx_stats                              # defaults: ip, now, sin filtro
#   nginx_stats modo periodo                 # sin filtro
#   nginx_stats modo periodo campo valor     # con filtro
# Modos: date, ip, method, status, ua, uri
# Periodos: now, hundred, thousand, complete
# Filtro: campo y valor para filtrar (ej: status 404)
# Salir: Ctrl+C
# =================================================

set -uo pipefail

# Configuración
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=1
TOP_N=30

# Variables de estado
TAIL_PID=""
TEMP_FILE=""
CURRENT_MODE=""
CURRENT_PERIOD="now"
FILTER_FIELD=""
FILTER_VALUE=""
declare -a HISTOGRAM_VALUES=()  # Para selección por número
CACHED_HISTOGRAM=""  # Cache para modos estáticos (hundred, thousand, complete)

# Configuración de modos: campo JSON y título
declare -A MODE_FIELD=(
    [date]=".date"
    [ip]=".ip"
    [method]=".method"
    [status]=".status"
    [ua]=".ua"
    [uri]=".uri"
)

declare -A MODE_TITLE=(
    [date]="Top Fechas"
    [ip]="Top IPs"
    [method]="Top Métodos HTTP"
    [status]="Top Status Codes"
    [ua]="Top User Agents"
    [uri]="Top URIs"
)

declare -A PERIOD_TITLE=(
    [now]="tiempo real"
    [hundred]="últimos 100"
    [thousand]="últimos 1000"
    [complete]="log completo"
)

declare -A MODE_HEADER=(
    [date]="Fecha"
    [ip]="IP"
    [method]="Método"
    [status]="Status"
    [ua]="User Agent"
    [uri]="URI"
)

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

    if [[ "$current" == "$match" ]]; then
        echo "[${key^^}] ${label^^}"
    else
        echo "[$key] $label"
    fi
}

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

# Función para mostrar el histograma (sin parpadeo)
show_histogram() {
    local output
    local prop_line
    local period_line
    local filter_line

    # En modo now, recalcular cada vez; en otros modos, usar cache
    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        compute_histogram
    fi

    # Construir línea de propiedades
    prop_line="Propiedad: "
    prop_line+="$(format_option d date "$CURRENT_MODE" date)  "
    prop_line+="$(format_option i ip "$CURRENT_MODE" ip)  "
    prop_line+="$(format_option m method "$CURRENT_MODE" method)  "
    prop_line+="$(format_option s status "$CURRENT_MODE" status)  "
    prop_line+="$(format_option a agent "$CURRENT_MODE" ua)  "
    prop_line+="$(format_option u uri "$CURRENT_MODE" uri)"

    # Construir línea de periodos
    period_line="Periodo: "
    period_line+="$(format_option n now "$CURRENT_PERIOD" now)  "
    period_line+="$(format_option h hundred "$CURRENT_PERIOD" hundred)  "
    period_line+="$(format_option t thousand "$CURRENT_PERIOD" thousand)  "
    period_line+="$(format_option c complete "$CURRENT_PERIOD" complete)"

    # Construir línea de filtro
    if [[ -n "$FILTER_FIELD" ]]; then
        filter_line="Filtro: [F] SI ($FILTER_FIELD: $FILTER_VALUE)"
    else
        filter_line="Filtro: NO"
    fi

    output=$(printf '\033[H\033[J')
    output+="=== ${MODE_TITLE[$CURRENT_MODE]} (${PERIOD_TITLE[$CURRENT_PERIOD]}) ==="
    output+=$'\n'
    output+="$prop_line"
    output+=$'\n'
    output+="$period_line"
    output+=$'\n'
    output+="$filter_line"
    output+=$'\n'
    output+="[Ctrl+C] salir"
    output+=$'\n\n'
    output+="F      #  ${MODE_HEADER[$CURRENT_MODE]}"
    output+=$'\n'
    output+="$CACHED_HISTOGRAM"

    printf '%s' "$output"
}

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

    # Crear archivo temporal
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

# Función para relanzar con nuevos parámetros
relaunch() {
    local new_mode="$1"
    local new_period="$2"

    stop_tail

    if [[ -n "$FILTER_FIELD" ]]; then
        exec "$0" "$new_mode" "$new_period" "$FILTER_FIELD" "$FILTER_VALUE"
    else
        exec "$0" "$new_mode" "$new_period"
    fi
}

# Configurar trap
trap cleanup SIGINT SIGTERM EXIT

# Verificar que el log existe
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: No se encuentra el archivo $LOG_FILE"
    exit 1
fi

# Verificar que jq está instalado
if ! command -v jq &> /dev/null; then
    echo "Error: jq no está instalado"
    echo "Instalar con: sudo apt-get install jq"
    exit 1
fi

# Validar número de argumentos: 0, 2 o 4
if [[ $# -ne 0 ]] && [[ $# -ne 2 ]] && [[ $# -ne 4 ]]; then
    echo "Error: Número de argumentos inválido"
    echo "Uso:"
    echo "  nginx_stats                              # defaults: ip, now"
    echo "  nginx_stats modo periodo                 # sin filtro"
    echo "  nginx_stats modo periodo campo valor     # con filtro"
    exit 1
fi

# Asignar valores según número de argumentos
if [[ $# -eq 0 ]]; then
    CURRENT_MODE="ip"
    CURRENT_PERIOD="now"
else
    CURRENT_MODE="$1"
    CURRENT_PERIOD="$2"
fi

# Validar modo
if [[ -z "${MODE_FIELD[$CURRENT_MODE]:-}" ]]; then
    echo "Error: Modo inválido: $CURRENT_MODE"
    echo "Modos válidos: date, ip, method, status, ua, uri"
    exit 1
fi

# Validar periodo
if [[ -z "${PERIOD_TITLE[$CURRENT_PERIOD]:-}" ]]; then
    echo "Error: Periodo inválido: $CURRENT_PERIOD"
    echo "Periodos válidos: now, hundred, thousand, complete"
    exit 1
fi

# Parsear filtro (argumentos 3 y 4)
if [[ $# -eq 4 ]]; then
    FILTER_FIELD="$3"
    FILTER_VALUE="$4"

    # Validar campo de filtro
    if [[ -z "${MODE_FIELD[$FILTER_FIELD]:-}" ]]; then
        echo "Error: Campo de filtro inválido: $FILTER_FIELD"
        echo "Campos válidos: date, ip, method, status, ua, uri"
        exit 1
    fi
fi

# Iniciar según el periodo
if [[ "$CURRENT_PERIOD" == "now" ]]; then
    start_tail
else
    load_data
fi

# Loop principal
while true; do
    show_histogram

    if read -t "$REFRESH_INTERVAL" -n 1 key 2>/dev/null; then
        case "$key" in
            # Propiedades
            d) relaunch "date" "$CURRENT_PERIOD" ;;
            i) relaunch "ip" "$CURRENT_PERIOD" ;;
            m) relaunch "method" "$CURRENT_PERIOD" ;;
            s) relaunch "status" "$CURRENT_PERIOD" ;;
            a) relaunch "ua" "$CURRENT_PERIOD" ;;
            u) relaunch "uri" "$CURRENT_PERIOD" ;;
            # Periodos
            n) relaunch "$CURRENT_MODE" "now" ;;
            h) relaunch "$CURRENT_MODE" "hundred" ;;
            t) relaunch "$CURRENT_MODE" "thousand" ;;
            c) relaunch "$CURRENT_MODE" "complete" ;;
            # Filtro (solo quitar)
            f)
                if [[ -n "$FILTER_FIELD" ]]; then
                    stop_tail
                    exec "$0" "$CURRENT_MODE" "$CURRENT_PERIOD"
                fi
                ;;
            # Selección por número (0-9) - aplica filtro
            [0-9])
                if [[ -n "${HISTOGRAM_VALUES[$key]:-}" ]]; then
                    stop_tail
                    exec "$0" "$CURRENT_MODE" "$CURRENT_PERIOD" "$CURRENT_MODE" "${HISTOGRAM_VALUES[$key]}"
                fi
                ;;
        esac
    fi
done
