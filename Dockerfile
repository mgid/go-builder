FROM alpine as builder

ENV PROTOBUF_VERSION="3.8.0"
ENV PROTOBUF_URL=https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz

RUN apk add --quiet --no-cache autoconf automake build-base libtool
RUN wget -q ${PROTOBUF_URL} -O - | tar -xz -C /tmp
RUN cd /tmp/protobuf-* && \
    ./autogen.sh && \
    ./configure --disable-shared --enable-static && \
    make --silent -j `nproc` install-strip


FROM golang:alpine

RUN apk add --quiet --no-cache \
      apache-ant \
      build-base \
      ca-certificates \
      git \
      libstdc++ \
      openjdk8 \
      pcre-dev

COPY --from=builder /usr/local/bin/protoc /usr/local/bin/protoc

RUN go get -u -ldflags="-s -w" github.com/golang/protobuf/protoc-gen-go && \
    mv /go/bin/protoc-gen-go /usr/local/bin/ && \
    rm -rf /go/bin/* /go/src/* /root/.cache