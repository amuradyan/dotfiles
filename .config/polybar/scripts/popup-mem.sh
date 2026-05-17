#!/usr/bin/env bash
set -u

declare -A m
while IFS= read -r line; do
  key=${line%%:*}
  rest=${line#*:}
  rest=${rest# }
  rest=${rest% kB}
  m[$key]=$rest
done < /proc/meminfo

h() {
  awk -v v="$1" 'BEGIN {
    if (v >= 1024*1024) printf "%.1f GiB", v/1024/1024
    else if (v >= 1024)  printf "%.0f MiB", v/1024
    else                  printf "%d KiB", v
  }'
}

total=${m[MemTotal]}
free=${m[MemFree]}
avail=${m[MemAvailable]}
buffers=${m[Buffers]}
cached=${m[Cached]}
used=$((total - avail))
used_pct=$((used * 100 / total))

printf 'total       %s\n'           "$(h "$total")"
printf 'used        %s  %d%%\n'     "$(h "$used")" "$used_pct"
printf 'free        %s\n'           "$(h "$free")"
printf 'cache       %s\n'           "$(h $((buffers + cached)))"
