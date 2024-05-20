#!/bin/bash
for var in "${@}"
do
  echo -e "ssh -o 'StrictHostKeyChecking no' $var 'bash -s' < ./remove-rpm.sh" >> ./clean-core.sh
done
echo -e "ssh -o 'StrictHostKeyChecking no' $1 'bash -s' < ./reset-pods.sh" >> ./clean-core.sh