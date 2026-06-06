#!/bin/bash

VERSION="${IMAGE_VERSION}_${CONFIG_VERSION}"

IMG="${NAME}_${IMAGE_VERSION}.${IMAGE_EXT}"
STL="${NAME}_${VERSION}_rlf.stl"

printf "reliefing..\n"
if ! relief "${IMG}" "${STL}" --valley 2 --rise $RISE --size $SIZE --invert --flip ; then
exit 1
fi
printf "open \"${IMG}\"\n"
printf "open \"${STL}\"\n"
