# Configuración por defecto
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=2
TOP_N=30

# Variable para el número máximo de resultados mostrados
CURRENT_MAX_RESULTS="thirty"

# Arrays de configuración de modos
declare -A MODE_FIELD=(
    [date]=".date"
    [ip]=".ip"
    [method]=".method"  # Restaurado
    [status]=".status"
    [ua]=".ua"
    [uri]=".uri"
    [cache]=".cache"
    [lang]=".lang"
    [referer]=".referer"
    [host]=".host"
    [time]=".time"   # Cambiado a .time para usar el campo correcto
    [log]=""
)

declare -A MODE_TITLE=(
    [date]="Top Fechas"
    [ip]="Top IPs"
    [method]="Top Methods"  # Restaurado
    [status]="Top Status Codes"
    [ua]="Top User Agents"
    [uri]="Top URIs"
    [cache]="Top Cache Status"
    [lang]="Top Languages"
    [referer]="Top Referers"
    [host]="Top Hosts"
    [time]="Top Time"
    [log]="Selector de Log"
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
    [method]="Method"  # Restaurado
    [status]="Status"
    [ua]="User Agent"
    [uri]="URI"
    [cache]="Cache"
    [lang]="Language"
    [referer]="Referer"
    [host]="Host"
    [time]="Time"
    [log]="Log File"
)

# Configuración para opciones de resultados
declare -A MAX_RESULTS_OPTIONS=(
    [ten]=10
    [twenty]=20
    [thirty]=30
)

declare -A MAX_RESULTS_TITLE=(
    [ten]="ten"
    [twenty]="twenty"
    [thirty]="thirty"
)

# Configuración de intervalos de tiempo para el modo time (10 intervalos)
declare -a TIME_INTERVAL_LABELS=(
    "[0.000 ≤ t < 0.010]"
    "[0.010 ≤ t < 0.020]"
    "[0.020 ≤ t < 0.050]"
    "[0.050 ≤ t < 0.100]"
    "[0.100 ≤ t < 0.250]"
    "[0.250 ≤ t < 0.500]"
    "[0.500 ≤ t < 1.000]"
    "[1.000 ≤ t < 2.000]"
    "[2.000 ≤ t < 3.000]"
    "[        t ≥ 3.000]"
)

declare -a TIME_INTERVAL_MIN=(
    "0.000"
    "0.010"
    "0.020"
    "0.050"
    "0.100"
    "0.250"
    "0.500"
    "1.000"
    "2.000"
    "3.000"
)

declare -a TIME_INTERVAL_MAX=(
    "0.010"
    "0.020"
    "0.050"
    "0.100"
    "0.250"
    "0.500"
    "1.000"
    "2.000"
    "3.000"
    "inf"
)

# Número total de intervalos de tiempo (ahora 10)
NUM_TIME_INTERVALS=10
