# syntax=docker/dockerfile:1.7
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o api .

FROM scratch
COPY --from=builder /app/api /api
EXPOSE 8080
ENTRYPOINT ["/api"]
