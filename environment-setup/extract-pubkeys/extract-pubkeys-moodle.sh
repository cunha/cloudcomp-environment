#!/bin/bash
set -eu

function log {
    echo "$1"
    echo "$1" >> log.txt
}

rm -rf zipdir students.yml log.txt

echo "students:" >> students.yml
echo "  - username: tstudent" >> students.yml
echo "    pubkey: $(sed '$ { /^$/ d}' tstudent-key/id_ed25519_tstudent.pub)" >> students.yml

if [[ ! -s submission.zip ]] ; then
    echo "File submission.zip does not exist, get it from Moodle"
    echo "Generated students.yml file with test student account"
    exit 0
fi
7z x -ozipdir submission.zip

for student in zipdir/* ; do
    student=$(basename "$student")
    name=$(echo "$student" | cut -d '_' -f 1)
    user=$(echo "$name" | tr -d -c ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
    sid=$(echo "$user" | awk '{printf("%s%s\n", tolower($1), tolower($NF));}')
    log "$name mapped to $sid"
    for file in "zipdir/$student/"* ; do
        sed -i 's/\r$//' "$file"
        if [[ $(grep -c "" "$file") -gt 1 ]] ; then
            log "Pubkey file for $sid has multiple lines; please resubmit"
        fi
        if ssh-keygen -l -f "$file" &> /dev/null ; then
            echo "Found pubkey for $sid: $(ssh-keygen -l -f "$file")"
            echo "  - username: $sid" >> students.yml
            echo "    pubkey: $(sed '$ { /^$/ d}' "$file")" >> students.yml
        else
            log "No valid pubkey found for $sid; please resubmit"
        fi
    done
done
log "Run completed $(date)"
