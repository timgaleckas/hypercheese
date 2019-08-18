#!/usr/bin/env bash
docker run -d -p 3000:3000 \
  -v /storage/hypercheese/db:/db \
  -v /storage/hypercheese/data:/usr/src/app/public/data \
  -v /storage/SharedFiles/Pictures:/usr/src/app/originals/Pictures \
  tgaleckas/hypercheese:0.1
