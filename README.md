# RentLoop_RS2

Seminarski rad iz predmeta **Razvoj softvera 2**  
Fakultet informacijskih tehnologija, Mostar

---

## 📖 O projektu

**RentLoop** je platforma za iznajmljivanje nekretnina koja omogućava korisnicima:
- pregled i pretragu nekretnina
- pravljenje rezervacija
- upravljanje favoritima
- ostavljanje recenzija
- primanje notifikacija
- online plaćanje putem PayPal-a
- real-time komunikaciju između korisnika i administratora

Projekat se sastoji od **backend API-ja**, **desktop admin aplikacije** i
**mobilne aplikacije**.

---

## 🚀 Upute za pokretanje

### Backend / infrastruktura (Docker)

#### Preduslovi
- Docker Desktop
- .NET SDK
- Flutter

#### Pokretanje

1. Klonirati repozitorij:

```bash
git clone <LINK_REPOZITORIJA>
cd <IME_PROJEKTA>
```

Pokrenuti Docker
(Docker Desktop mora biti aktivan)

U root folderu projekta pokrenuti:

```bash
docker compose up -d
```

Ovom komandom se pokreću:

SQL Server baza podataka

RabbitMQ

Backend API

Sačekati da se svi servisi uspješno pokrenu.

## 🌐 Swagger / API
Swagger dokumentacija backend API-ja dostupna je na:

```bash
https://localhost:7000/swagger/index.html
```
ili

```bash
http://localhost:5068/swagger/index.html
```

## 🗄️ Migracije i baza podataka
Ako se baza pokreće prvi put, potrebno je izvršiti migracije.

```bash
dotnet ef database update --project RentLoop.API
```
```
Update-Database
```
Ako migracije već postoje u projektu, nije potrebno dodavati nove.

## 📱 Desktop i mobilna aplikacija
### Mobilna aplikacija
Za pokretanje mobilne aplikacije potrebno je imati aktivan emulator
```bash
flutter pub get
flutter run
```
### Desktop aplikacija
```bash

flutter pub get
flutter run -d windows
```
### ⚠️ Bitne napomene
Mobilna i desktop aplikacija ne rade na istom localhostu

Obje aplikacije koriste isti backend API

Docker Desktop mora biti aktivan da bi backend API, baza i RabbitMQ radili ispravno.

## 💳 Online plaćanje (PayPal)
Aplikacija podržava online plaćanje putem PayPal Sandbox testnog okruženja.

Plaćanje je testirano korištenjem PayPal sandbox naloga (buyer/seller) koji su
konfigurisani unutar PayPal Developer okruženja.

## 🔐 Kredencijali za prijavu (seed podaci)
### Administrator

Email: admin

Password: admin

### Korisnik

Email: demo

Password: demo

## 🔧 Mikroservisi i real-time funkcionalnosti
Aplikacija koristi RabbitMQ za asinhrone procese i notifikacije, te
SignalR za real-time komunikaciju (chat između administratora i korisnika).

## 🛠️ Tehnologije
Backend: ASP.NET Core

ORM: Entity Framework Core

Frontend: Flutter (desktop i mobilna aplikacija)

Baza podataka: SQL Server

Real-time komunikacija: SignalR

Message broker: RabbitMQ

Online plaćanje: PayPal

Containerization: Docker
