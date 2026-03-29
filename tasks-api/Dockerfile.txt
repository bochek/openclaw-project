# Minimal Go image for tasks-api
FROM golang:alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN go install github.com/lib/pq@v1.10.9
WORKDIR /build
COPY tasks-api/main.go .
RUN go mod init tasks-api && go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o tasks-api .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /build/tasks-api .
EXPOSE 8082
CMD ["./tasks-api"]
