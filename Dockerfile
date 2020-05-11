FROM alpine:3

# variable "VERSION" must be passed as docker environment variables during the image build
# docker build --no-cache --build-arg VERSION=2.12.0 -t alpine/helm:2.12.0 .

ARG VERSION

ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-${VERSION}-linux-amd64.tar.gz"

RUN apk add --update --no-cache git curl ca-certificates && \
    echo ${BASE_URL}/${TAR_FILE} && \
    curl -L ${BASE_URL}/${TAR_FILE} | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    rm -f /var/cache/apk/*

RUN if [[ $(echo $VERSION | cut -d '.' -f 1) == "v2" ]]; then helm init --client-only; fi
RUN helm plugin install https://github.com/chartmuseum/helm-push.git

WORKDIR /apps

ENTRYPOINT ["helm"]
CMD ["--help"]
