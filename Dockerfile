FROM alpine:3

# variable "VERSION" must be passed as docker environment variables during the image build
# docker build --no-cache --build-arg HELM_VERSION=3.2.1 --build-arg YQ_VERSION=3.3.0 -t renaultdigital/helm:2.12.0 .

ARG HELM_VERSION
ARG YQ_VERSION

ENV HELM_SOURCE="https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
ENV YQ_SOURCE="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
ENV HELM_PUSH_SOURCE="https://github.com/chartmuseum/helm-push.git"

RUN apk add --update --no-cache git curl ca-certificates && rm -f /var/cache/apk/*

RUN curl ${YQ_SOURCE} --output /usr/bin/yq

RUN curl -L ${HELM_SOURCE} | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64

RUN if [[ $(echo $HELM_VERSION | cut -d '.' -f 1) == "2" ]]; then helm init --client-only; fi && \
    helm plugin install ${HELM_PUSH_SOURCE}

WORKDIR /apps

ENTRYPOINT ["helm"]
CMD ["--help"]
