#!/usr/bin/env bash
# cAIrn resources — a host-local, read-only memory snapshot for a handoff or
# troubleshooting session. It never writes the repository or the ledger.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "cairn resources: not a git repository" >&2
  exit 1
}
cd "$ROOT"

OS="$(uname -s 2>/dev/null || printf 'unknown')"

human_gib() {
  awk -v bytes="$1" 'BEGIN { printf "%.1f GiB", bytes / 1073741824 }'
}

show_macos_memory() {
  local total_bytes free_percentage swap_usage
  echo "-- system memory (macOS) --"

  total_bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
  case "$total_bytes" in
    *[!0-9]*|"") echo "  physical RAM: unavailable" ;;
    *)              echo "  physical RAM: $(human_gib "$total_bytes")" ;;
  esac

  free_percentage="$(memory_pressure -Q 2>/dev/null \
    | awk -F': ' '/^System-wide memory free percentage:/ { print $2; exit }' || true)"
  if [ -n "$free_percentage" ]; then
    echo "  memory free estimate: $free_percentage"
  else
    echo "  memory free estimate: unavailable"
  fi

  swap_usage="$(sysctl vm.swapusage 2>/dev/null || true)"
  if [ -n "$swap_usage" ]; then
    echo "  $swap_usage"
  else
    echo "  swap usage: unavailable"
  fi
}

show_linux_memory() {
  local memory
  echo "-- system memory (Linux) --"
  memory="$(awk '
    /^MemTotal:/ { total=$2 }
    /^MemAvailable:/ { available=$2 }
    /^SwapTotal:/ { swap_total=$2 }
    /^SwapFree:/ { swap_free=$2 }
    END {
      if (total) printf "  physical RAM: %.1f GiB\n", total / 1048576
      else print "  physical RAM: unavailable"
      if (available) printf "  memory available: %.1f GiB\n", available / 1048576
      else print "  memory available: unavailable"
      if (swap_total || swap_free) printf "  swap: %.1f GiB used / %.1f GiB total\n", (swap_total - swap_free) / 1048576, swap_total / 1048576
      else print "  swap: unavailable"
    }' /proc/meminfo 2>/dev/null || true)"
  if [ -n "$memory" ]; then
    printf '%s\n' "$memory"
  else
    echo "  memory information: unavailable"
  fi
  if grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "  note: this reports the WSL VM, not all Windows-host memory."
  fi
}

show_top_processes() {
  local rows
  echo
  echo "-- top visible processes by resident memory --"
  case "$OS" in
    Darwin) rows="$(ps -axo pid=,rss=,comm= 2>/dev/null \
      | LC_ALL=C sort -k2,2nr \
      | awk '
          NR <= 10 {
            pid=$1; rss=$2; $1=""; $2=""; sub(/^[[:space:]]+/, "", $0)
            name=$0; sub(/^.*\//, "", name)
            gsub(/[[:cntrl:]]/, "?", name)
            if (length(name) > 72) name=substr(name, 1, 69) "..."
            if (name == "") name="[unknown]"
            printf "  %-7s %8.1f MiB  %s\n", pid, rss / 1024, name
          }' || true)" ;;
    Linux) rows="$(ps -eo pid=,rss=,comm= 2>/dev/null \
      | LC_ALL=C sort -k2,2nr \
      | awk '
          NR <= 10 {
            pid=$1; rss=$2; $1=""; $2=""; sub(/^[[:space:]]+/, "", $0)
            name=$0; sub(/^.*\//, "", name)
            gsub(/[[:cntrl:]]/, "?", name)
            if (length(name) > 72) name=substr(name, 1, 69) "..."
            if (name == "") name="[unknown]"
            printf "  %-7s %8.1f MiB  %s\n", pid, rss / 1024, name
          }' || true)" ;;
    *) rows="" ;;
  esac
  if [ -n "$rows" ]; then
    printf '%s\n' "$rows"
  elif [ "$OS" = "MINGW64_NT" ] || [[ "$OS" == MINGW* ]]; then
    echo "  unavailable in Git Bash; use Windows Task Manager for host processes."
  else
    echo "  unavailable on this platform."
  fi
}

echo "== cAIrn resources: $(basename "$ROOT") =="
echo "   host-local snapshot only — no files or processes are changed."
echo

case "$OS" in
  Darwin) show_macos_memory ;;
  Linux)  show_linux_memory ;;
  *)
    echo "-- system memory --"
    echo "  unavailable on $OS; use the platform's native system monitor."
    ;;
esac
show_top_processes

echo
echo "Note: this is instantaneous. RSS can include shared pages; macOS cache and"
echo "compression are normal and this output alone does not establish a memory leak."
