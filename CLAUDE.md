# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nginx_my_stats is a suite of bash scripts for real-time monitoring of Nginx server statistics. It provides live histograms of User Agents, IPs, and HTTP status codes from JSON-formatted Nginx access logs.

## Scripts

- `top_ua.sh` - Monitor User Agents (extracts `.ua` field)
- `top_ip.sh` - Monitor IP addresses (extracts `.ip` field)
- `top_status.sh` - Monitor HTTP status codes (extracts `.status` field)
- `top_date.sh` - Monitor dates (extracts `.date` field)

## Running the Scripts

```bash
./top_ua.sh       # User Agents histogram
./top_ip.sh       # IP addresses histogram
./top_status.sh   # HTTP status codes histogram
./top_date.sh     # Dates histogram
```

All scripts require `sudo` to read Nginx logs. Press `Ctrl+C` to exit (cleanup is automatic).

## Dependencies

- `jq` - JSON parser (required)
- `watch` - periodic refresh
- Access to `/var/log/nginx/shield_access.log` (configurable via `LOG_FILE` variable)

## Architecture

All three scripts follow the same pattern:
1. Start `sudo tail -f` on the log file in background
2. Pipe through `jq --unbuffered -r` to extract the relevant JSON field
3. Append extracted values to a unique temp file (`mktemp`)
4. Use `watch` to display a sorted/counted histogram
5. `trap` handles cleanup on exit (kills tail process, removes temp file)

### Configuration Variables (top of each script)

```bash
LOG_FILE="/var/log/nginx/shield_access.log"  # Log path
REFRESH_INTERVAL=1                            # Seconds between updates
TOP_N=30                                      # Number of results to show
```

## Nginx Log Format Requirement

Scripts expect JSON-formatted logs with these fields:
- `ua` - User Agent string
- `ip` - Client IP address
- `status` - HTTP status code
- `date` - Request date
