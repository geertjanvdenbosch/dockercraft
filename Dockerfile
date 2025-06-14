FROM alpine:3.6 AS wget
RUN apk add --no-cache ca-certificates wget tar

FROM wget AS docker
ARG DOCKER_VERSION=17.09.0-ce
RUN wget -qO- https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | \
  tar -xvz --strip-components=1 -C /bin

FROM wget AS cuberite
WORKDIR /srv
RUN wget -qO- "https://download.cuberite.org/linux-x86_64/Cuberite.tar.gz" |\
  tar -xzf -

FROM golang:1.9 AS dockercraft
WORKDIR /go/src/github.com/docker/dockercraft
COPY . .
RUN go install

FROM debian:bullseye
RUN apt update; apt install -y ca-certificates
COPY --from=dockercraft /go/bin/dockercraft /bin
COPY --from=docker /bin/docker /bin
COPY --from=cuberite /srv /srv

# Copy Dockercraft config and plugin
COPY ./config /srv/Server
COPY ./docs/img/logo64x64.png /srv/Server/favicon.png
COPY ./Docker /srv/Server/Plugins/Docker

EXPOSE 25565
ENTRYPOINT ["/srv/Server/start.sh"]
