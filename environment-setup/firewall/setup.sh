#!/bin/bash
set -eu

apt install nftables
systemctl enable nftables.service
nft -f nftables.conf
nft list ruleset
cp nftables.conf /etc/nftables.conf
