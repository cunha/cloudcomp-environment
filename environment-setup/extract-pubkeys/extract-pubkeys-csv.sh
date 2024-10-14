#!/bin/bash
set -eu

function log {
    echo "$1"
    echo "$1" >> log.txt
}

if [[ ! -e $1 ]] ; then
    echo "Usage: $0 <csvfile>"
    exit 1
fi

rm -f students.yml
echo "students:" >> students.yml

while IFS=, read -r sid pubkey ; do
    log "Processing $sid"
    user=$(echo "$sid" | tr -d -c '[:alnum:] [:space:]')
    user=$(echo "$user" | awk '{printf("%s", tolower($1));}')
    log "$sid mapped to $user"
    if echo "$pubkey" | ssh-keygen -l -f - &> /dev/null ; then
        echo "Found pubkey for $user"
        echo "  - username: $user" >> students.yml
        echo "    pubkey: $pubkey" >> students.yml
    else
        log "No valid pubkey found for $sid; please resubmit"
    fi
done < <(tail -n +2 "$1")

log "Run completed $(date)"
