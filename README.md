# Flutter Todo App — Clean Architecture, BLoC & Secure Auth

A production-style Flutter application demonstrating **Clean Architecture**,  
**BLoC state management**, **JWT authentication with single-flight refresh**, **pagination**, **debounced search**, and **comprehensive unit & BLoC testing**.

This project focuses on **engineering correctness**, **scalability**, and **testability** not just UI.

---

## Getting Started

This Flutter app is built to showcase real-world application patterns commonly used in production systems.

### Project Objective

The goal of this project is to practice and demonstrate **real-world Flutter application architecture** and patterns commonly used in production mobile apps.

Key objectives:

- Build a scalable Flutter app using **Clean Architecture**
- Implement **secure authentication** with access & refresh tokens
- Handle token expiry safely using a **single-flight refresh mechanism**
- Manage state using **BLoC with proper event transformers**
- Implement pagination and debounced search correctly
- Write meaningful **unit tests, BLoC tests, and concurrency tests**


---

### Key Engineering Concepts Implemented

- Clean Architecture (Domain / Data / Presentation)
    - Domain / Data / Presentation separation
    - UseCases isolate business logic
    - UI depends only on abstractions
- BLoC with event transformers (`droppable`, `sequential`, `debounce`)
- JWT-based authentication
- Secure token storage
- **Single-flight refresh token mechanism**
- Pagination with state preservation
- Search with debounce
- Robust error handling
- High-quality automated tests

---

### Architecture Overview

The app follows a **feature-based Clean Architecture** approach:

features/
├── auth/
├── todo/
core/
├── network/
├── secure_storage/


**Data flow:**

UI → Bloc → UseCase → Repository → DataSource → API



This structure ensures:
- Clear separation of concerns
- Easy testing
- Long-term maintainability

---

### Authentication & Token Refresh

- Login returns access & refresh tokens
- Tokens are stored securely
- Access token expiry is checked before API calls
- If expired, a refresh is triggered
- **Only one refresh request runs at a time**
- Concurrent requests wait for the same refresh operation
- User is logged out safely if refresh fails

---

### Testing Strategy

Testing is focused on **behavior**, not UI rendering.

Tests include:
- UseCase unit tests
- BLoC tests (success, error, pagination, search)
- Refresh token concurrency tests
- JWT expiry handling tests

This ensures the app behaves correctly under real-world conditions.

---

### Tech Stack

- Flutter
- Dart
- flutter_bloc
- bloc_concurrency
- bloc_test
- mocktail
- http
- secure_storage
- JWT-based authentication
- FastAPI (backend API)

---

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
2. Install dependencies:
   ```bash
   flutter pub get
3. Run the app:
   ```bash
   flutter run
4. Run tests:
   ```bash
   flutter test
