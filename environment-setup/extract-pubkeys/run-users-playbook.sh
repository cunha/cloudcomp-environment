#!/bin/bash
set -eu

./extract-pubkeys-moodle.sh

rm -rf ../ansible/pubkeys
echo 
cp -a outdir ../ansible/pubkeys
cat users.yaml > ../ansible/roles/users/defaults/main.yml
