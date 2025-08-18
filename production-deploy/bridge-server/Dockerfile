# Build stage - Ubuntu 기반으로 변경 (SQLite CGO 호환성 개선)
FROM golang:1.21-bullseye AS builder

# SQLite 개발 라이브러리 설치
RUN apt-get update && apt-get install -y \
    gcc \
    libc6-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=1 go build -o main .

# Run stage - 경량 런타임
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    sqlite3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Docker 클라이언트 설치 (Docker-in-Docker를 위해)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | \
    tar xzvf - --strip 1 -C /usr/local/bin docker/docker && \
    chmod +x /usr/local/bin/docker

WORKDIR /app

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
