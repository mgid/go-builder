ARG GO_VERSION="1.14.4"
ARG LINTER_VERSION="v1.28.1"
ARG PROTOBUF_VERSION="3.12.3"

FROM alpine as proto-builder

ARG PROTOBUF_VERSION
ENV PROTOBUF_URL=https://github.com/protocolbuffers/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz

RUN apk add --quiet --no-cache autoconf automake build-base libtool zlib-dev
RUN wget -q ${PROTOBUF_URL} -O - | tar -xz -C /tmp
RUN cd /tmp/protobuf-* && \
    ./autogen.sh && \
    ./configure --disable-shared --enable-static && \
    make --silent -j `nproc` install-strip

FROM golang:${GO_VERSION}-alpine

ARG GO_VERSION
ARG LINTER_VERSION

RUN apk add --quiet --no-cache \
      apache-ant \
      build-base \
      ca-certificates \
      git \
      libstdc++ \
      openjdk8 \
      pcre-dev

RUN wget -O - -q https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin ${LINTER_VERSION}

COPY --from=proto-builder /usr/local /usr/local

RUN go get -u -ldflags="-s -w" github.com/golang/protobuf/protoc-gen-go && \
    go get -u -ldflags="-s -w" google.golang.org/grpc/cmd/protoc-gen-go-grpc && \
    mv /go/bin/* /usr/local/bin/ && \
    rm -rf /go/bin/* /go/src/* /root/.cache
