#!/usr/bin/env bash
set -u

df -h -x tmpfs -x devtmpfs -x squashfs -x overlay --output=target,used,size,pcent 2>/dev/null \
  | awk 'NR == 1 { next }
         $1 == "/" || $1 == "/home" || $1 == "/boot" || $1 == "/tmp" {
           if (!seen[$1]++) printf "%-10s %5s / %5s  %s\n", $1, $2, $3, $4
         }'

df -i / 2>/dev/null | awk '
function h(v) {
  if (v >= 1048576) return sprintf("%.1fM", v/1048576)
  if (v >= 1024)    return sprintf("%.0fK", v/1024)
  return sprintf("%d", v)
}
NR == 2 { printf "inodes /   %5s / %5s  %s\n", h($3+0), h($2+0), $5 }'
