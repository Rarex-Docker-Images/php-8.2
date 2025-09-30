#!/bin/bash

APP_VERSION=1.0.0
BUILD_DATE=$(date +%Y-%m-%d)

args="--build-arg APP_VERSION=$APP_VERSION --build-arg BUILD_DATE=$BUILD_DATE -f Dockerfile"

docker build $args --target dev -t ghcr.io/rarex-docker-images/php-8.2:v$APP_VERSION . &
docker build $args --target debug -t ghcr.io/rarex-docker-images/php-8.2:v$APP_VERSION-debug . &
wait