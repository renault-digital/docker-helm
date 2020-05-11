#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret environment variables in Travis CI
# DOCKER_USERNAME
# DOCKER_PASSWORD
# API_TOKEN

set -e

image="renaultdigital/helm"
repo="helm/helm"

build() {
  echo "Found new version, building the image ${image}:${tag}"
  docker build --no-cache --build-arg VERSION="${tag}" -t ${image}:"${tag}" .

  # run test
  version=$(docker run -ti --rm "${image}:${tag}" version --client)

  if [[ "${version}" == *"Error: unknown flag: --client"* ]]; then
    echo "Detected Helm >= 3"
    version=$(docker run -ti --rm "${image}:${tag}" version | cut -d"\"" -f2 | cut -d"\"" -f1)
    # version.BuildInfo{Version:"v3.0.0-beta.2", GitCommit:"26c7338408f8db593f93cd7c963ad56f67f662d4", GitTreeState:"clean", GoVersion:"go1.12.9"}
  else
    echo "Detected Helm < 3"
    # Client: &version.Version{SemVer:"v2.9.0-rc2", GitCommit:"08db2d0181f4ce394513c32ba1aee7ffc6bc3326", GitTreeState:"clean"}
    version=$(echo "${version}"| cut -d"\"" -f2 | cut -d"\"" -f1)
  fi

  if [ "${version}" == "${tag}" ]; then
    echo "matched"

    if [[ "$TRAVIS_BRANCH" == "master" ]]; then
      docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
      docker push ${image}:"${tag}"
    fi
  else
    echo "unmatched"
  fi
}

if [[ ${CI} == 'true' ]]; then
  tags=$(curl -sL -H "Authorization: token ${API_TOKEN}"  https://api.github.com/repos/${repo}/releases |jq -r ".[].tag_name"| cut -c 1-)
else
  tags=$(curl -sL https://api.github.com/repos/${repo}/releases |jq -r ".[].tag_name"| cut -c 1-)
fi

for tag in ${tags}
do
  echo "$tag"
  status=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/"${tag}")
  echo "$status"
  if [[ "${status}" =~ "not found" ]]; then
    build
  fi
done

echo "Get latest version based on the latest Github release"

if [[ ${CI} == 'true' ]]; then
  latest=$(curl -sL -H "Authorization: token ${API_TOKEN}"  https://api.github.com/repos/${repo}/releases/latest |jq -r ".tag_name"| cut -c 2-)
else
  latest=$(curl -sL https://api.github.com/repos/${repo}/releases/latest |jq -r ".tag_name"| cut -c 2-)
fi

digest=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/"${latest}" | jq -r ".images[].digest" )
digest_latest=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/latest | jq -r ".images[].digest" )

if [ "${digest_latest}" != "${digest}" ]; then
  echo "Update latest image to ${latest}"
  if [[ "$TRAVIS_BRANCH" == "master" && "$TRAVIS_PULL_REQUEST" == false ]]; then
    docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    docker pull ${image}:"${latest}"
    docker tag ${image}:"${latest}" ${image}:latest
    docker push ${image}:latest
  fi
else
  echo "Nothing to do !"
fi
