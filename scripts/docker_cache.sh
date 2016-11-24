#!/bin/bash

if [[ ${TRAVIS_BRANCH} == "master" ]] && [[ ${TRAVIS_PULL_REQUEST} == "false" ]]; then 
  mkdir -p $(dirname ${DOCKER_CACHE_FILE})
  docker save $(docker history -q ${DOCKER_REGISTRY}/dtrav:${TRAVIS_COMMIT} | \
  grep -v '<missing>') | gzip > ${DOCKER_CACHE_FILE}
fi
