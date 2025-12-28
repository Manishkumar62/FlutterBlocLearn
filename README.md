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

- Clean Architecture
    - Domain / Data / Presentation separation
    - UseCases isolate business logic
    - UI depends only on abstractions
- BLoC State Management
    - Event → State driven UI
    - No direct API calls from UI
    - Predictable state transitions
- Authentication & Security
    - JWT-based authentication
    - Access token + refresh token
    - Secure token storage
    - Automatic token refresh on expiry
- **Single-flight refresh token mechanism**
    - Ensures only one refresh request runs at a time
    - Concurrent API calls wait on the same refresh Future
    - Prevents refresh storms and race conditions
    - Graceful logout on refresh failure
- Pagination & Search
    - Ordered pagination using `sequential()` transformer
    - Search with debounce using `debounce()` transformer
    - State preserved across pagination & search
- Robust Testing Strategy
    - Unit tests for UseCases
    - BLoC tests for success, error, pagination & search
    - Concurrency tests for refresh token logic
    - JWT expiry tested using real token payloads

---

### Architecture Overview

The app follows a **feature-based Clean Architecture** approach:
    ```kotlin
    features/
    ├── auth/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    ├── todo/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    core/
    ├── network/
    ├── secure_storage/
    └── common utilities


**Data flow:**
    ```nginx
    UI → Bloc → UseCase → Repository → DataSource → API

- UI dispatches events
- Bloc coordinates state changes
- UseCases contain business rules
- Repositories abstract data sources
- DataSources handle API / storage

This ensures:
- Easy testing
- Clear responsibility boundaries
- Maintainable, scalable code

---

### Authentication & Token Refresh Flow

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
