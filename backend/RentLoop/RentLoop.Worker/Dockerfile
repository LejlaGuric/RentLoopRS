FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# kopiraj csproj fajlove prvo (bolji cache)
COPY RentLoop.API/RentLoop.API.csproj RentLoop.API/
COPY RentLoop.Worker/RentLoop.Worker.csproj RentLoop.Worker/

# restore workera (povuèe i reference)
RUN dotnet restore RentLoop.Worker/RentLoop.Worker.csproj

# kopiraj source za oba projekta
COPY RentLoop.API/ RentLoop.API/
COPY RentLoop.Worker/ RentLoop.Worker/

WORKDIR /src/RentLoop.Worker
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "RentLoop.Worker.dll"]
