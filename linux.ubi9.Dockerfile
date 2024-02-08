FROM registry.access.redhat.com/ubi9/go-toolset:1.20 as builder

ENV CGO_ENABLED=0

USER 0

RUN mkdir -p /go/src/github.com/letsencrypt/ \
    && cd /go/src/github.com/letsencrypt/ \
    && git clone https://github.com/letsencrypt/pebble

WORKDIR /go/src/github.com/letsencrypt/pebble/

RUN go build -o /go/src/github.com/letsencrypt/pebble/pebble ./cmd/pebble
RUN go build -o /go/src/github.com/letsencrypt/pebble/pebble-challtestsrv ./cmd/pebble-challtestsrv

FROM registry.access.redhat.com/ubi9-minimal:9.2

COPY --from=builder /go/src/github.com/letsencrypt/pebble/pebble /usr/bin/pebble
COPY --from=builder /go/src/github.com/letsencrypt/pebble/pebble-challtestsrv /usr/bin/pebble-challtestsrv

RUN /bin/microdnf reinstall tzdata -y

ENV TZ=America/Boston

EXPOSE 5001
EXPOSE 5002
EXPOSE 5053
EXPOSE 14000
EXPOSE 15000