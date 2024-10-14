#!/bin/bash
set -eu

zipfile=$1

rm -rf zipdir outdir users.yml
unzip -d zipdir "$zipfile"
mkdir outdir

echo "users:" >> users.yml
for assignment in zipdir/* ; do
    for student in "$assignment"/* ; do
        student=$(basename "$student")
        netid=$(echo "$student" | sed 's/^.*(\(.*\)@.*)/\1/')
        for file in "$assignment/$student/Submission attachment(s)"/* ; do
            sed -i 's/\r$//' "$file"
            if ssh-keygen -l -f "$file" &> /dev/null ; then
                echo "Found pubkey for $netid: $(ssh-keygen -l -f "$file")"
                cp "$file" "outdir/$netid.pub"
                echo "  - $netid" >> users.yml
            fi
        done
        if [[ ! -s "outdir/$netid.pub" ]] ; then
            echo "No valid pubkey found for $netid; please resubmit"
        fi
    done
done
echo "Run completed $(date)"
