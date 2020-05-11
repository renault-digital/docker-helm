#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret environment variables in Travis CI
# DOCKER_USERNAME
# DOCKER_PASSWORD
# API_TOKEN

set -e

IMAGE="renaultdigital/helm"
REPOSITORY="helm/helm"

build() {
  tag=$1

  echo "Found new version, building the image ${IMAGE}:${tag}"
  docker build --no-cache --build-arg VERSION="${tag}" -t ${IMAGE}:"${tag}" .

  if [[ "$TRAVIS_BRANCH" == "master" ]]; then
    docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    docker push ${IMAGE}:"${tag}"

  else
    echo "Not on master, ignore push"
  fi
}

if [[ ${CI} == 'true' ]]; then
  tags=$(curl -sL -H "Authorization: token ${API_TOKEN}"  https://api.github.com/repos/${REPOSITORY}/releases |jq -r ".[].tag_name"| cut -c 1-)
else
  tags=$(curl -sL https://api.github.com/repos/${REPOSITORY}/releases |jq -r ".[].tag_name"| cut -c 1-)
fi

for tag in ${tags}
do
  echo "$tag"
  status=$(curl -sL https://hub.docker.com/v2/repositories/${IMAGE}/tags/"${tag}")
  echo "$status"
  if [[ "${status}" =~ "not found" ]]; then
    build "$tag"
  fi
done

echo "Get latest version based on the latest Github release"

if [[ ${CI} == 'true' ]]; then
  latest=$(curl -sL -H "Authorization: token ${API_TOKEN}"  https://api.github.com/repos/${REPOSITORY}/releases/latest |jq -r ".tag_name"| cut -c 2-)
else
  latest=$(curl -sL https://api.github.com/repos/${REPOSITORY}/releases/latest |jq -r ".tag_name"| cut -c 2-)
fi

digest=$(curl -sL https://hub.docker.com/v2/repositories/${IMAGE}/tags/"${latest}" | jq -r ".images[].digest" )
digest_latest=$(curl -sL https://hub.docker.com/v2/repositories/${IMAGE}/tags/latest | jq -r ".images[].digest" )

if [ "${digest_latest}" != "${digest}" ]; then
  echo "Update latest image to ${latest}"
  if [[ "$TRAVIS_BRANCH" == "master" && "$TRAVIS_PULL_REQUEST" == false ]]; then
    docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    docker pull ${IMAGE}:"${latest}"
    docker tag ${IMAGE}:"${latest}" ${IMAGE}:latest
    docker push ${IMAGE}:latest
  fi
else
  echo "Nothing to do !"
fi
