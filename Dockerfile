# build stage
FROM golang:1.22.3-alpine3.19 AS builder
WORKDIR /src
COPY . .
RUN go mod download
RUN go build -ldflags '-s -w'

# server image

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