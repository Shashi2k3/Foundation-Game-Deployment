# Build stage: compile the supplied app inside the image (no local .NET SDK needed).
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY app/ ./app/
RUN dotnet publish app/Foundation.csproj -c Release -o /publish --nologo

# Runtime stage: the supplied ASP.NET 10.0.12 runtime, pinned by digest; only the published output is copied in.
FROM mcr.microsoft.com/dotnet/aspnet:10.0.12@sha256:222759b391a1aaf241166672c8f99b2d4ada452e7b5319f3c6e8f265a37b5ad4
WORKDIR /app
COPY --from=build /publish/ ./

# Listener: port 8080 inside the container (the Service targets the named port http = 8080).
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

# Entrypoint: start the packaged page + API.
ENTRYPOINT ["dotnet", "Foundation.dll"]
