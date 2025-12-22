#!/usr/bin/env bash
file=~/.test/"$1"
mkdir -p "$(dirname "$file")"
if [ -f "$file" ]; then
    cat > /dev/null
    exec cat "$file"
fi
exec tee "$file"
