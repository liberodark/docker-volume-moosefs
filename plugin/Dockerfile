# Build stage
FROM golang:1.20-alpine AS builder
WORKDIR /go/src/github.com/liberodark/docker-volume-moosefs
COPY . .
# Recréer un nouveau go.mod dans le container
RUN rm -f go.mod go.sum && \
    go mod init github.com/liberodark/docker-volume-moosefs && \
    go get github.com/sirupsen/logrus@v1.9.3 && \
    go get github.com/docker/go-plugins-helpers@v0.0.0-20211224144127-6eecb7beb651 && \
    go get github.com/davecgh/go-spew@v1.1.1 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -o /go/bin/docker-volume-moosefs

# Final stage
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Installation du client MooseFS
RUN apt-get update && \
    apt-get install -y wget gnupg2 && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - http://repository.moosefs.com/moosefs.key | gpg --dearmor > /etc/apt/keyrings/moosefs.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/moosefs.gpg] http://repository.moosefs.com/moosefs-4/apt/ubuntu/jammy jammy main" > /etc/apt/sources.list.d/moosefs.list && \
    apt-get update && \
    apt-get install -y moosefs-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/bin/docker-volume-moosefs /usr/bin/docker-volume-moosefs
RUN mkdir -p /run/docker/plugins /var/lib/docker-volume-moosefs
CMD ["docker-volume-moosefs"]
