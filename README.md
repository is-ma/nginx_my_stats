# Nginx My Stats

Suite de herramientas para monitorear en tiempo real las estadísticas del servidor Nginx.

## 📊 Herramienta

### `panelt.sh` - Panel de Estadísticas

Monitor interactivo que muestra histogramas en tiempo real de diferentes campos del log de Nginx. Permite navegar entre vistas usando el teclado.

**Vistas disponibles:**
- **[d] date** - Fechas de las peticiones
- **[i] ip** - Direcciones IP de los clientes
- **[m] method** - Métodos HTTP (GET, POST, PUT, DELETE, etc.)
- **[s] status** - Códigos de respuesta HTTP
- **[a] agent** - User Agents
- **[u] uri** - URIs solicitadas

**Periodos disponibles:**
- **[n] now** - Tiempo real
- **[h] hundred** - Últimos 100 registros
- **[t] thousand** - Últimos 1000 registros
- **[c] complete** - Log completo

**Filtros dinámicos:**
- **[0-9]** - Selecciona un valor del histograma para filtrar por él
- **[f]** - Quita el filtro actual

**Útil para:**
- Identificar bots agresivos y crawlers no deseados
- Detectar posibles ataques DDoS
- Monitorear errores 404, 500, etc.
- Ver la salud general del servidor
- Identificar las páginas más visitadas
- Detectar escaneos de vulnerabilidades

## 🚀 Instalación

### Requisitos
- `jq` - Parser de JSON
- Acceso sudo para leer logs de Nginx

**Instalar jq si no lo tienes:**
```bash
sudo apt-get install jq
```

### Configurar Alias

Agrega esto a tu `~/.bashrc` para acceso rápido:

```bash
# Nginx Stats Panel
alias panelt='/home/deploy/.is-ma/nginx_my_stats/panelt.sh'
```

Luego recarga tu configuración:
```bash
source ~/.bashrc
```

## 📖 Uso

```bash
panelt          # Inicia en modo IP (default)
panelt date     # Inicia en modo fecha
panelt status   # Inicia en modo status codes
panelt ua       # Inicia en modo User Agents
panelt uri      # Inicia en modo URIs
panelt method   # Inicia en modo métodos HTTP
```

### Navegación
Una vez dentro del panel, usa las teclas para cambiar de vista:
- `d` - Ver fechas
- `i` - Ver IPs
- `m` - Ver métodos HTTP
- `s` - Ver status codes
- `a` - Ver User Agents
- `u` - Ver URIs
- `n` - Cambiar a modo tiempo real
- `h` - Cambiar a últimos 100 registros
- `t` - Cambiar a últimos 1000 registros
- `c` - Cambiar a log completo
- `0-9` - Seleccionar un valor del histograma para filtrar
- `f` - Quitar el filtro actual
- `Ctrl+C` - Salir

### Salir
Presiona `Ctrl+C` para salir. El script automáticamente:
- ✓ Mata el proceso `tail` en background
- ✓ Elimina archivos temporales
- ✓ No deja basura en el sistema

## 🎯 Ejemplo de Uso Real

Después de implementar un nuevo `robots.txt`, puedes usar `panelt` para verificar que los bots están respetando las reglas:

```bash
$ panelt ua

=== Top User Agents en tiempo real ===
Teclas: [d] date  [i] ip  [m] method  [s] status  [a] agent  [u] uri  [n] now  [h] hundred  [t] thousand  [c] complete  [f] quitar filtro  [0-9] seleccionar  [Ctrl+C] salir

   208 Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...
    82 Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot...
    76 Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...
    ...
```

Si un bot que bloqueaste sigue apareciendo, sabes que no está respetando el `robots.txt` y necesitas medidas más agresivas (como fail2ban).

## 🔧 Configuración

El script tiene variables de configuración al inicio que puedes modificar:

```bash
LOG_FILE="/var/log/nginx/shield_access.log"  # Ruta al log
REFRESH_INTERVAL=1                           # Segundos entre actualizaciones
TOP_N=30                                     # Cantidad de resultados a mostrar
```

## 📝 Notas Técnicas

### ¿Cómo funciona?

1. **Inicia un `tail -f`** en background que lee el log continuamente
2. **Extrae el campo deseado** usando `jq` (date, ip, method, status, ua, uri)
3. **Acumula los datos** en un archivo temporal único
4. **Muestra el histograma** sin parpadeo usando doble buffer
5. **Captura teclas** para cambiar de vista instantáneamente
6. **Limpia todo** cuando presionas Ctrl+C usando `trap`

### Archivos Temporales

El script usa `mktemp` para crear un archivo temporal único:
- `/tmp/nginx_stats_XXXXXX.tmp`

Donde `XXXXXX` es un string aleatorio. Este archivo se elimina automáticamente al salir.

### Permisos

El script necesita `sudo` para leer `/var/log/nginx/shield_access.log`. Si no quieres usar sudo, puedes:

1. Agregar tu usuario al grupo que posee los logs
2. O cambiar los permisos del log (no recomendado)

## 🐛 Troubleshooting

**Error: "jq no está instalado"**
```bash
sudo apt-get install jq
```

**Error: "No se encuentra el archivo /var/log/nginx/shield_access.log"**

Verifica la ruta de tu log de Nginx y modifica la variable `LOG_FILE` en el script.

**El histograma no se actualiza**

Verifica que tu log de Nginx esté en formato JSON y tenga los campos: `date`, `ip`, `method`, `status`, `ua`, `uri`.

## 🎨 Características

- ✅ Navegación interactiva entre vistas
- ✅ Cambio de modo instantáneo sin reiniciar
- ✅ Visualización sin parpadeo (doble buffer)
- ✅ Auto-limpieza de procesos y archivos temporales
- ✅ Mensajes coloridos para mejor legibilidad
- ✅ Validación de dependencias
- ✅ Manejo robusto de errores
- ✅ Sin configuración externa necesaria
- ✅ Portable y fácil de modificar

## 📜 Licencia

Licencia para jugar.

---

**Creado con ❤️ para monitorear servidores como un pro** 🚀
