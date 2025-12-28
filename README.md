# Flutter Todo App — Clean Architecture, BLoC & Secure Auth

A production-style Flutter application demonstrating **Clean Architecture**,  
**BLoC state management**, **JWT authentication with single-flight refresh**, **pagination**, **debounced search**, and **comprehensive unit & BLoC testing**.

This project focuses on **engineering correctness**, **scalability**, and **testability** not just UI.

---

## Getting Started

This Flutter app is built to showcase real-world application patterns commonly used in production systems.

### 📌 Project Objective

The goal of this project is to practice and demonstrate **real-world Flutter application architecture** and patterns commonly used in production mobile apps.

Key objectives:

- Build a scalable Flutter app using **Clean Architecture**
- Implement **secure authentication** with access & refresh tokens
- Handle token expiry safely using a **single-flight refresh mechanism**
- Manage state using **BLoC with proper event transformers**
- Implement pagination and debounced search correctly
- Write meaningful **unit tests, BLoC tests, and concurrency tests**


---

### 🧠 Key Engineering Concepts Implemented

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

### 🏗️ Architecture Overview

1. The app follows a **feature-based Clean Architecture** approach:
    ```bash
    features/
    ├── auth/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    ├── todo/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    core/
    ├── network/
    ├── secure_storage/
    └── common utilities

2. **Data flow:**:
    ```bash
    UI -> Bloc -> UseCase -> Repository -> DataSource -> API

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

### 🔐 Authentication & Token Refresh Flow

1. User logs in using credentials
2. API returns:
    - Access token (short-lived)
    - Refresh token (long-lived)
3. Tokens are stored securely
4. Every API request checks token validity
5. If access token is expired:
    - RefreshManager triggers token refresh
6. **Single-flight guarantee**:
    - If refresh is already in progress, other requests wait
7. On refresh success:
    - Tokens updated
    - Pending requests continue
8. On refresh failure:
    - User is logged out safely

This design avoids:
- Multiple refresh calls
- Race conditions
- Inconsistent auth state

---

### 🧪 Testing Strategy

Testing is focused on **behavior**, not implementation details.

What is tested
- ✅ UseCases (success & failure)
- ✅ BLoC state transitions
- ✅ Pagination behavior
- ✅ Debounced search logic
- ✅ Refresh token concurrency
- ✅ Refresh failure → logout
- ✅ JWT expiry logic using real token payloads

Why this matters
- Tests are deterministic
- No reliance on UI or timers
- Concurrency logic is proven safe
- Refactors are confidence-driven

---

### ⚙️ Tech Stack

- Flutter
- Dart
- flutter_bloc
- bloc_concurrency
- bloc_test
- mocktail
- http
- secure_storage
- JWT-based authentication
- Free opensource API (backend API)

---

### 🛠️ Setup Instructions

- Prerequisites
    - Flutter (stable channel)
    - Dart SDK
    - Android Studio / VS Code

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd firstassignbloc
2. Install dependencies:
   ```bash
   flutter pub get
3. Run the app:
   ```bash
   flutter run
4. Run tests:
   ```bash
   flutter test

---

### 📚 Key Learnings

- How to design Flutter apps for long-term maintainability
- How to handle auth safely in mobile apps
- Why concurrency issues matter in token refresh logic
- How to test async and debounced behavior correctly
- Why architecture matters more than UI complexity

---

### 👤 Author

- Manishkumar Vishwakarma
- Full Stack Mobile App Developer (Flutter + Django/FastAPI)
- Focused on scalable architecture, state management, and testing.

---

### ⭐ Why This Project Matters

This is not a tutorial-style Todo app.
It is a production-thinking Flutter project that demonstrates:
- Real auth challenges
- Concurrency safety
- Clean architecture discipline
- Testing mindset