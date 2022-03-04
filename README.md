# kubernetes helm


![Docker Image CI Push](https://github.com/renault-digital/docker-helm/workflows/Docker%20Image%20CI%20Push/badge.svg)
![Docker Image Trivy](https://github.com/renault-digital/docker-helm/workflows/Docker%20Image%20Trivy/badge.svg)

Auto-trigger docker build for [kubernetes helm](https://github.com/kubernetes/helm) when new release is announced.

[![DockerHub Badge](http://dockeri.co/image/renaultdigital/helm)](https://hub.docker.com/r/renaultdigital/helm/)

## NOTES

The latest docker tag is the latest release version (https://github.com/helm/helm/releases/latest)

Please avoid to use `latest` tag for any production deployment. Tag with right version is the proper way, such as `renaultdigital/helm:3.1.1`

Same image as [alpine-docker](https://github.com/alpine-docker/helm) with:

- `curl`
- `helm-push`: latest
- `yq`: v3.3.0

### Github Repo

https://github.com/renault-digital/helm

### Daily Travis CI build logs

https://travis-ci.org/renault-digital/helm

### Docker image tags

https://hub.docker.com/r/renaultdigital/helm/tags/

# Usage

    # mount local folders in container.
    docker run -ti --rm -v $(pwd):/apps -w /apps \
        -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm \
        -v ~/.cache/helm:/root/.cache/helm \
        renaultdigital/helm

    # Run helm with special version. The tag is helm's version
    docker run -ti --rm -v $(pwd):/apps -w /apps \
        -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm \
        -v ~/.cache/helm:/root/.cache/helm \
        renaultdigital/helm:3.1.1

    # run container as command
    alias helm="docker run -ti --rm -v $(pwd):/apps -w /apps \
        -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm \
        -v ~/.cache/helm:/root/.cache/helm \
        renaultdigital/helm"
    helm --help
    
    # example in ~/.bash_profile
    alias helm='docker run -e KUBECONFIG="/root/.kube/config:/root/.kube/some-other-context.yaml" -ti --rm -v $(pwd):/apps -w /apps \
        -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm \
        -v ~/.cache/helm:/root/.cache/helm \
        renaultdigital/helm'

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# The Processes to build this image

* Enable Travis CI cronjob on this repo to run build daily on master branch
* Check if there are new tags/releases announced via Github REST API
* Match the exist docker image tags via Hub.docker.io REST API
* If not matched, build the image with release version and push to https://hub.docker.com/
* Get the latest version from https://github.com/helm/helm/releases/latest, pull the image with that version, tag as `renaultdigital/helm:latest` and push to hub.docker.com

# Contribution

Before any contribution, test your code :

- using our testing script: `.githooks/pre-commit`
- by registering our githooks: `git config --local core.hooksPath .githooks/`

# Credits

Original works from https://github.com/alpine-docker/helm.
