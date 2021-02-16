ARG ALPINE_VERSION=latest
ARG GOLANG_VERSION=1.15
ARG TARGET=amd64

# ---------------------------------------------------------------------
#   builder
# ---------------------------------------------------------------------
FROM golang:${GOLANG_VERSION}-alpine as builder
MAINTAINER Marco Pantaleoni <marco.pantaleoni@gmail.com>

ENV LANG=C.UTF-8
ENV TARGET=amd64

# Install base packages
RUN apk -U add --no-cache \
    ca-certificates git make \
  && rm -rf /var/cache/apk/*

RUN go get -u github.com/mitchellh/gox

# copy go.mod and go.sum early to allow caching
RUN mkdir -p /src
WORKDIR /src
COPY go.mod .
COPY go.sum .

ENV GO111MODULE=on
ENV GOFLAGS=" -mod=vendor"

RUN go mod download && \
    go mod vendor
# COPY the source code as the last step (to enable caching)
COPY . .

RUN go mod download && \
    go mod vendor

# build
RUN make build OS=linux ARCH=$TARGET


# ---------------------------------------------------------------------
#   final stage
# ---------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION}
MAINTAINER Marco Pantaleoni <marco.pantaleoni@gmail.com>

ENV LANG=C.UTF-8
ENV TARGET=amd64

WORKDIR /

RUN apk -U add --no-cache \
	openssl ca-certificates \
	&& rm -rf /var/cache/apk/*

#COPY --from=builder /go/bin/tunneld /go/bin/tunnel /usr/bin/
COPY --from=builder /src/build/pkg/linux_${TARGET}/tunneld /src/build/pkg/linux_${TARGET}/tunnel /usr/bin/

# default variables
ENV CLIENTS ""
ENV DEBUG ""
ENV DISABLE_HTTPS ""
ENV TUNNEL_CONFIG /tunnel.yml

# certificate directories
ENV CERT_DIR "/etc/ssl/certs"

# certificates generation variables
ENV COUNTY "US"
ENV STATE "New Jersey"
ENV LOCATION "Somewhere"
ENV ORGANISATION "Organisation"
ENV OU "Development"
ENV ROOT_CN "Root"
ENV ROOT_NAME "root"
ENV ISSUER_CN "Issuer Ltd"
ENV ISSUER_NAME "issuer"
ENV SERVER_CN "tunnel.test"
ENV SERVER_NAME "server"
ENV CLIENT_CN "client.test"
ENV CLIENT_NAME "client"
ENV RSA_KEY_NUMBITS "2048"
ENV DAYS "365"

RUN mkdir -p /.tunnel
WORKDIR /.tunnel

VOLUME ["$CERT_DIR"]

COPY docker/*.ext /
COPY docker/*.ext /.tunnel/
COPY docker/entrypoint.sh /
RUN chmod a+x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
