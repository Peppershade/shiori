# build stage
FROM golang:1.22.2-alpine3.19 AS builder
WORKDIR /src
COPY . .
RUN go mod download
RUN go build -ldflags '-s -w'

FROM docker.io/library/alpine:${ALPINE_VERSION} AS builder
ARG TARGETARCH
ARG TARGETOS
ARG TARGETVARIANT
COPY dist/shiori_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}/shiori /usr/bin/shiori
RUN apk add --no-cache ca-certificates tzdata && \
    chmod +x /usr/bin/shiori && \
    rm -rf /tmp/*

# Server image
FROM scratch

ENV PORT 8080
ENV SHIORI_DIR=/shiori
WORKDIR ${SHIORI_DIR}

LABEL org.opencontainers.image.source="https://github.com/go-shiori/shiori"
LABEL maintainer="Felipe Martin <github@fmartingr.com>"

COPY --from=builder /tmp /tmp
COPY --from=builder /usr/bin/shiori /usr/bin/shiori
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE ${PORT}

FROM docker.io/alpine:3.19
LABEL org.opencontainers.image.source https://github.com/go-shiori/shiori
COPY --from=builder /src/shiori /usr/bin/
RUN addgroup -g 1000 shiori \
    && adduser -D -h /shiori -g '' -G shiori -u 1000 shiori
RUN mkdir shiori-data && chown -R shiori:shiori shiori-data
USER shiori
WORKDIR /shiori-data
EXPOSE 8080
ENV SHIORI_DIR /shiori-data
ENTRYPOINT ["/usr/bin/shiori"]
CMD ["server"]