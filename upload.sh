#!/bin/sh
set -e
if [ -z "$1" ]; then
  echo "Usage: $0 <channel>"
  exit 1
fi
zstd --decompress /mnt/data/$1.tar.zst
tar xvf /mnt/data/$1.tar
rm /mnt/data/$1.tar /mnt/data/$1.tar.zst
cat /mnt/data/$1/ia.txt | sh
