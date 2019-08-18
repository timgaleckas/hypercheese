#!/usr/bin/env bash
docker run -it \
  -v /storage/hypercheese/db:/db \
  -v /storage/hypercheese/data:/usr/src/app/public/data \
  -v /storage/SharedFiles/Pictures:/usr/src/app/originals/Pictures \
  tgaleckas/hypercheese:0.1 "$@"
