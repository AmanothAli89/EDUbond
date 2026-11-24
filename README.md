# EduBond 

**EduBond** is a comprehensive Android-based educational platform designed to bridge the gap between students and educators. The application facilitates seamless interaction, resource management and interactive learning through a modern and intuitive user interface.

## 🚀 Key Features

### 🔐 Authentication & Security
- **Multi-Role Login:** Dedicated login portals for Students and Administrators.
- **Google Integration:** Secure and easy sign-in using Google Credentials.
- **App Password System:** Enhanced security with a dedicated app-specific password layer.
- **Password Recovery:** Built-in forgot password functionality via Firebase Email Auth.

### 📚 Academic Management
- **Subject-Specific Content:** Organized view of subjects with detailed learning materials.
- **Interactive UI:** Smooth transitions and modern UI components for an engaging experience.

### 📝 Interactive Learning (Quiz System)
- **Teacher Dashboard:** Specialized interface for teachers/admins to create and manage quizzes.
- **Cloud Synchronization:** Real-time data storage and retrieval using Firebase Firestore.
- **Resource Management:** Upload and manage educational assets via Firebase Storage.

### 🛠️ Technical Stack
- **Language:** Kotlin
- **Architecture:** MVVM / Activity-based UI
- **Backend:** Firebase (Authentication, Firestore, Storage)
- **UI Components:** Jetpack Compose (parts), XML, Material Design 3
- **Networking:** OkHttp, Coroutines

## 🛠️ Installation & Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/bappy-81/EduBond.git
   ```
2. Open the project in **Android Studio**.
3. Connect your own **Firebase Project**:
   - Add `google-services.json` to the `app/` directory.
   - Enable Authentication (Email/Password & Google).
   - Setup Firestore and Storage rules.
4. Build and run the application on an emulator or physical device.

## 👨‍💻 Developer
**Md. Lemon Islam Bappy**
- B.Sc. in Computer Science and Engineering (CSE)
- Bangladesh Army University of Science and Technology (BAUST)
- [LinkedIn](https://www.linkedin.com/in/md-lemon-islam-bappy-4116a61b8/) | [GitHub](https://github.com/bappy-81)

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
