#!/bin/bash
echo -e "Host $1\n\tIdentityFile ~/pems/powerflex-denver-installer" > ~/.ssh/config
for var in "${@:2}"
do
  echo -e "Host $var\n\tIdentityFile ~/pems/powerflex-denver-co-res" >> ~/.ssh/config
done