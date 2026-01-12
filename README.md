# Nginx My Stats

Suite de herramientas para monitorear en tiempo real las estadísticas del servidor Nginx.

## 📊 Herramientas Disponibles

### `top_ua.sh` - Monitor de User Agents
Muestra un histograma actualizado en tiempo real de los User Agents más frecuentes que están accediendo al servidor.

**Útil para:**
- Identificar bots agresivos
- Ver qué navegadores usan tus usuarios
- Detectar crawlers no deseados
- Validar que tu `robots.txt` está siendo respetado

### `top_ip.sh` - Monitor de IPs
Muestra un histograma actualizado en tiempo real de las IPs que más están accediendo al servidor.

**Útil para:**
- Detectar posibles ataques DDoS
- Identificar IPs sospechosas
- Monitorear tráfico por origen
- Validar que fail2ban está funcionando

### `top_status.sh` - Monitor de Status Codes
Muestra un histograma actualizado en tiempo real de los códigos de respuesta HTTP del servidor.

**Útil para:**
- Monitorear errores 404, 500, etc.
- Ver la salud general del servidor
- Detectar problemas en tiempo real
- Validar que todo está funcionando correctamente

## 🚀 Instalación

### Requisitos
- `jq` - Parser de JSON
- `watch` - Comando para actualización periódica
- Acceso sudo para leer logs de Nginx

**Instalar jq si no lo tienes:**
```bash
sudo apt-get install jq
```

### Configurar Aliases

Agrega esto a tu `~/.bashrc` para acceso rápido:

```bash
# Nginx Stats Tools
alias topua='/home/deploy/.is-ma/nginx_my_stats/top_ua.sh'
alias topips='/home/deploy/.is-ma/nginx_my_stats/top_ips.sh'
alias topstatus='/home/deploy/.is-ma/nginx_my_stats/top_status.sh'
```

Luego recarga tu configuración:
```bash
source ~/.bashrc
```

## 📖 Uso

Simplemente ejecuta cualquiera de los comandos:

```bash
topua      # Ver User Agents en tiempo real
topip     # Ver IPs en tiempo real
topstatus  # Ver Status Codes en tiempo real
```

### Salir
Presiona `Ctrl+C` para salir. El script automáticamente:
- ✓ Mata el proceso `tail` en background
- ✓ Elimina archivos temporales
- ✓ No deja basura en el sistema

## 🎯 Ejemplo de Uso Real

Después de implementar un nuevo `robots.txt`, puedes usar `topua` para verificar que los bots están respetando las reglas:

```bash
$ topua

Iniciando monitor de User Agents...
Log: /var/log/nginx/shield_access.log
Presiona Ctrl+C para salir

Every 1.0s: sort /tmp/nginx_ua_ABC123.tmp | uniq -c | sort -nr | head -n 30

   208 Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...
    82 Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot...
    76 Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...
    ...
```

Si un bot que bloqueaste sigue apareciendo, sabes que no está respetando el `robots.txt` y necesitas medidas más agresivas (como fail2ban).

## 🔧 Configuración

Cada script tiene variables de configuración al inicio que puedes modificar:

```bash
LOG_FILE="/var/log/nginx/shield_access.log"  # Ruta al log
REFRESH_INTERVAL=1                           # Segundos entre actualizaciones
TOP_N=30                                     # Cantidad de resultados a mostrar
```

## 📝 Notas Técnicas

### ¿Cómo funciona?

1. **Inicia un `tail -f`** en background que lee el log continuamente
2. **Extrae el campo deseado** usando `jq` (ua, remote_addr, status)
3. **Acumula los datos** en un archivo temporal único
4. **Muestra el histograma** con `watch` actualizándose cada segundo
5. **Limpia todo** cuando presionas Ctrl+C usando `trap`

### Archivos Temporales

Los scripts usan `mktemp` para crear archivos temporales únicos:
- `/tmp/nginx_ua_XXXXXX.tmp`
- `/tmp/nginx_ips_XXXXXX.tmp`
- `/tmp/nginx_status_XXXXXX.tmp`

Donde `XXXXXX` es un string aleatorio. Estos archivos se eliminan automáticamente al salir.

### Permisos

Los scripts necesitan `sudo` para leer `/var/log/nginx/shield_access.log`. Si no quieres usar sudo, puedes:

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

Verifica que tu log de Nginx esté en formato JSON y tenga los campos: `ua`, `remote_addr`, `status`.

## 🎨 Características

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
