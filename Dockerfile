# Build stage
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
COPY go.mod .
RUN go mod download
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -o tasks-api .

# Runtime stage
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /build/tasks-api .
EXPOSE 8082
CMD ["./tasks-api"]
