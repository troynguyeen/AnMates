# syntax=docker/dockerfile:1.7
# Multi-stage build for ASP.NET Core 9.
# Final image runs as a non-root user and ships only the published output.

ARG DOTNET_SDK=8.0
ARG DOTNET_RUNTIME=8.0

# ── Restore ───────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK}-alpine AS restore
WORKDIR /src
COPY ["Directory.Build.props", "AnMates.sln", "./"]
COPY ["src/AnMates.Api/AnMates.Api.csproj", "src/AnMates.Api/"]
COPY ["src/AnMates.Domain/AnMates.Domain.csproj", "src/AnMates.Domain/"]
COPY ["src/AnMates.Infrastructure/AnMates.Infrastructure.csproj", "src/AnMates.Infrastructure/"]
RUN dotnet restore AnMates.sln --runtime linux-musl-x64

# ── Build & publish ───────────────────────────────────────────────────────
FROM restore AS build
COPY src/ ./src/
RUN dotnet publish src/AnMates.Api/AnMates.Api.csproj \
      -c Release \
      -o /app/publish \
      --runtime linux-musl-x64 \
      --no-restore \
      --self-contained false \
      /p:PublishReadyToRun=true

# ── Runtime ───────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_RUNTIME}-alpine AS runtime
RUN apk add --no-cache icu-libs curl tzdata \
 && addgroup -S anmates && adduser -S anmates -G anmates
WORKDIR /app
COPY --from=build --chown=anmates:anmates /app/publish ./
USER anmates
EXPOSE 8080
ENV TZ=UTC \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=false \
    ASPNETCORE_URLS=http://+:8080 \
    DOTNET_GCServer=1
ENTRYPOINT ["dotnet", "AnMates.Api.dll"]
