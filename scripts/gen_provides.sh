#!/bin/bash

packages=()

#set -ex
IMAGES_DATA=$(luet tree images --tree=$COMMON_TREE --image-repository $REPO_CACHE --tree=$TREE $PACK -o json)
PKG_LIST=$(luet tree pkglist --tree $TREE --tree=$COMMON_TREE -o json)
images=($(echo $IMAGES_DATA | jq -r '.packages[].image' ))

if [[ "${#images[@]}" == "1" ]];then
packages_before=()
else
packages_before=( $(docker run --rm ${images[-2]} qlist -IC) )
fi
packages_after=( $(docker run --rm ${images[-1]} qlist -IC) )

IFS=/ read -a p <<< $PACK

path=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.name==\"${p[1]}\" and .category==\"${p[0]}\").path")
for target in "${packages_before[@]}"; do
  for i in "${!packages_after[@]}"; do
    if [[ ${packages_after[i]} = $target ]]; then
      unset 'packages_after[i]'
    fi
  done
done

p=0
for i in ${packages_after[@]};
do


echo "Adding $i"
IFS=/ read -a package <<< $i

if [[ "${package[0]}" == "acct-group" ]] || [[ "${package[0]}" == "acct-user" ]];then
continue
fi

yq w -i $path/definition.yaml "provides[$p].name" "${package[1]}"
yq w -i $path/definition.yaml "provides[$p].category" "${package[0]}"
yq w -i $path/definition.yaml "provides[$p].version" ">=0"

p=$((p+1))
done
