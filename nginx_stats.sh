#!/bin/bash

# =================================================
# nginx_stats - Panel de estadísticas Nginx
# =================================================
# Muestra histogramas de diferentes campos del log
# de Nginx con navegación por teclado
#
# Uso:
#   nginx_stats [--access-log ARCHIVO] [--mode MODO] [--how-many CUANTOS] [--filter-field CAMPO] [--filter-value VALOR]
#   Modos: date, ip, method, status, ua, uri, cache, lang, referer, host (default: ip)
#   CUANTOS: now, hundred, thousand, complete (default: now)
#   Filtro: campo y valor para filtrar (ej: --filter-field status --filter-value 404)
#   Salir: q
# =================================================

set -uo pipefail

# Determinar directorio donde está el script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Configuración (cargada desde módulo)
source "$SCRIPT_DIR/mods/config.sh"

# Variables de estado
TAIL_PID=""
TEMP_FILE=""
CURRENT_MODE=""
CURRENT_PERIOD="now"
FILTER_FIELD=""
FILTER_VALUE=""
declare -a HISTOGRAM_VALUES=()  # Para selección por número
CACHED_HISTOGRAM=""  # Cache para modos estáticos (hundred, thousand, complete)


# Cargar módulos (funciones)
source "$SCRIPT_DIR/mods/helpers.sh"
source "$SCRIPT_DIR/mods/histogram.sh"
source "$SCRIPT_DIR/mods/data_loader.sh"
source "$SCRIPT_DIR/mods/filter.sh"

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

# Procesar todas las opciones con nombre
while [[ $# -gt 0 ]]; do
    case "$1" in
        --access-log)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --access-log requiere un archivo"
                exit 1
            fi
            LOG_FILE="$2"
            shift 2
            ;;
        --mode)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --mode requiere un valor"
                exit 1
            fi
            CURRENT_MODE="$2"
            shift 2
            ;;
        --how-many)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --how-many requiere un valor"
                exit 1
            fi
            CURRENT_PERIOD="$2"
            shift 2
            ;;
        --filter-field)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --filter-field requiere un valor"
                exit 1
            fi
            FILTER_FIELD="$2"
            shift 2
            ;;
        --filter-value)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --filter-value requiere un valor"
                exit 1
            fi
            FILTER_VALUE="$2"
            shift 2
            ;;
        *)
            echo "Error: Opción desconocida: $1"
            echo "Uso:"
            echo "  nginx_stats [--access-log ARCHIVO] [--mode MODO] [--how-many CUANTOS] [--filter-field CAMPO] [--filter-value VALOR]"
            echo "  Modos: date, ip, method, status, ua, uri, cache, lang, referer, host"
            echo "  CUANTOS: now, hundred, thousand, complete"
            exit 1
            ;;
    esac
done

# Establecer valores por defecto si no se proporcionaron
: "${CURRENT_MODE:=ip}"
: "${CURRENT_PERIOD:=now}"

# Validar modo
if [[ -z "${MODE_FIELD[$CURRENT_MODE]:-}" ]]; then
    echo "Error: Modo inválido: $CURRENT_MODE"
    echo "Modos válidos: date, ip, method, status, ua, uri, cache, lang, referer, host"
    exit 1
fi

# Validar CUANTOS
if [[ -z "${PERIOD_TITLE[$CURRENT_PERIOD]:-}" ]]; then
    echo "Error: CUANTOS inválido: $CURRENT_PERIOD"
    echo "CUANTOS válidos: now, hundred, thousand, complete"
    exit 1
fi

# Validar que si se proporciona --filter-value, también se proporcione --filter-field y viceversa
if [[ -n "$FILTER_FIELD" && -z "$FILTER_VALUE" ]]; then
    echo "Error: --filter-field requiere --filter-value"
    exit 1
fi
if [[ -n "$FILTER_VALUE" && -z "$FILTER_FIELD" ]]; then
    echo "Error: --filter-value requiere --filter-field"
    exit 1
fi

# Validar campo de filtro si se proporciona
if [[ -n "$FILTER_FIELD" ]]; then
    if [[ -z "${MODE_FIELD[$FILTER_FIELD]:-}" ]]; then
        echo "Error: Campo de filtro inválido: $FILTER_FIELD"
        echo "Campos válidos: date, ip, method, status, ua, uri, cache, lang, referer, host"
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
            d) change_mode "date" ;;
            i) change_mode "ip" ;;
            m) change_mode "method" ;;
            s) change_mode "status" ;;
            a) change_mode "ua" ;;
            u) change_mode "uri" ;;
            k) change_mode "cache" ;;
            l) change_mode "lang" ;;
            r) change_mode "referer" ;;
            o) change_mode "host" ;;
            # CUANTOS
            n) change_period "now" ;;
            h) change_period "hundred" ;;
            t) change_period "thousand" ;;
            c) change_period "complete" ;;
            # Filtro (solo quitar)
            f)
                remove_filter
                ;;
            # Selección por número (0-9) - aplica filtro
            [0-9])
                if [[ -n "${HISTOGRAM_VALUES[$key]:-}" ]]; then
                    apply_filter "$CURRENT_MODE" "${HISTOGRAM_VALUES[$key]}"
                fi
                ;;
            # Salir con 'q'
            q)
                # Mostrar la 'q' en amarillo antes de salir
                show_histogram "true"
                # Pequeña pausa para que se vea el cambio
                sleep 0.2
                cleanup
                ;;
        esac
    fi
done
