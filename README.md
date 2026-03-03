# RentLoop – Property Rental Platform

RentLoop is a property rental platform developed as a seminar project for the course **Razvoj softvera 2** at the Faculty of Information Technologies, Mostar.

The system enables users to browse and reserve properties, communicate with administrators in real time, make online payments, and receive automated notifications.

The solution consists of:

- .NET 8 Web API backend  
- Flutter Desktop application (Windows)  
- Flutter Mobile application (Android)  
- SQL Server database  
- RabbitMQ message broker  

---

# How to Run the Project

## Environment Setup

Make sure the following tools are installed:

- Docker Desktop  
- .NET SDK 8  
- Flutter SDK  

Docker Desktop must be running before starting the project.

---

## Start Backend Services

In the root project folder (where `docker-compose.yml` is located), run:

```bash
docker compose up -d --build
```
Wait until all containers are fully initialized.

After starting the application with Docker, the API documentation is available at:

http://localhost:5068/swagger

You can also access it directly via:

http://localhost:5068/swagger/index.html

Swagger allows you to test all available API endpoints, including authentication, reservations, payments, and messaging.

---

# Desktop and Mobile Applications

## Windows Desktop Application

Location:

```
frontend/rentloop_app/deliverables/windows/Release
```

Run:

```bash
rentloop_app.exe
```

---

## Android Mobile Application

Location:

```
frontend/rentloop_app/deliverables/android
```

Install on Android device:

```
app-release.apk
```

(Enable installation from unknown sources if required.)

---

# Login Credentials (Seed Data)

## Administrator (Desktop & Mobile)

```
Email: admin
Password: admin
```

## Regular User

```
Email: demo
Password: demo
```

---

# Online Payment (PayPal Sandbox)

The system supports online payments using the PayPal Sandbox environment.

## PayPal Sandbox Test Credentials

```
Email: sb-2vl2448691010@personal.example.com
Password: m)lO,Yi6
```

These credentials are intended strictly for testing purposes within the PayPal Sandbox environment.

---

# RabbitMQ & Notification System

RabbitMQ is used for asynchronous communication and background processing.

The system handles:

- Reservation confirmations  
- Notification events  
- Background processing tasks  

This architecture ensures scalable and non-blocking API operations.

---

# Real-Time Communication

RentLoop uses SignalR for real-time chat between administrators and users.

Messages are delivered instantly without manual refresh.

---

# Technologies Used

**Backend**
- .NET 8 Web API  
- Entity Framework Core  
- SQL Server  

**Frontend**
- Flutter (Windows Desktop & Android Mobile)

**Real-time Communication**
- SignalR  

**Message Broker**
- RabbitMQ  

**Online Payment**
- PayPal (Sandbox)

**Containerization**
- Docker & Docker Compose  

---

# Key Features

- Property browsing and advanced filtering  
- Reservation system  
- Online payments via PayPal  
- Real-time chat system  
- User authentication & authorization  
- Favorites functionality  
- Review and rating system  
- Personalized recommendations  
- Admin management dashboard  
- Asynchronous notification processing  
