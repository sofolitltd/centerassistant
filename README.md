# 🏥 Center Assistant

**Center Assistant** is a comprehensive, role-based management system built with Flutter and Firebase. It streamlines operations for centers by providing distinct, optimized experiences for both Administrators and Employees.

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-blueviolet?style=for-the-badge)](https://riverpod.dev/)
[![Live Demo](https://img.shields.io/badge/Live_Demo-Visit_Site-success?style=for-the-badge&logo=google-chrome&logoColor=white)](https://centerassistantbd.web.app/)

## 🚀 Key Features

### 🔑 Advanced Authentication
- **Dual-Portal Access:** Simultaneous login for users who hold both Admin and Employee roles with seamless account switching.
- **Security First:** Enforced password changes for new employee accounts and account status verification (active/disabled).

### 👔 Admin Portal
- **Dashboard Analytics:** High-level overview of center operations.
- **Dynamic Scheduling:** Template-based scheduling system with customizable time slots.
- **Client & Staff Management:** Complete CRUD operations and schedule assignments.
- **Leave Management:** Review and manage staff availability.

### 💼 Employee Portal
- **Intelligent Dashboard:** 
  - Real-time session tracking: Displays **"Running Now"** for active sessions and **"All Done"** when the day is complete.
  - Daily workload and client stats at a glance.
- **Personalized Schedule:** Interactive weekly and daily schedule views.
- **Client Portal:** Access to assigned client information and contact details.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Multi-platform: Android, iOS, Web)
- **State Management:** [Riverpod 3.0](https://riverpod.dev/) (NotifierProvider, AsyncNotifier)
- **Backend:** [Firebase](https://firebase.google.com/) (Cloud Firestore for real-time sync)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with redirect logic)
- **UI/UX:** [Lucide Icons](https://lucideicons.com/), Google Fonts, Staggered Grid Views.
- **Local Storage:** Shared Preferences (Auth persistence).

## 🏗 Architecture
The project follows a **Feature-First Modular Architecture**, ensuring scalability and maintainability:
- `lib/core`: Shared models, providers, and global routing logic.
- `lib/app/admin`: Feature-based modules specific to administrators.
- `lib/app/employee`: Feature-based modules specific to employees.
- `lib/services`: Infrastructure layer (Firebase, API).

## 🏁 Getting Started

### Prerequisites
- Flutter SDK `^3.10.1`
- A Firebase project configured for Android and Web.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/centerassistant.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

---
*Developed with ❤️ by [Sofol IT](https://sofolit.vercel.app)*
