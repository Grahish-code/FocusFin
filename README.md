# FocusFin 🎯
**Bring your finances into focus.** A production-ready, End-to-End Encrypted (E2EE) personal finance manager that tracks your transactions through secure, automated SMS parsing and beautiful, intuitive UI.

Built with Flutter, Riverpod, and an unwavering commitment to user privacy.

---

## 🚀 Overview

Expense tracking usually fails because logging transactions manually introduces friction. **FocusFin** solves this by automating the process without compromising security. 

When a transaction occurs, the app securely reads your bank's SMS alert in the background and instantly utilizes Android's **Display Over Other Apps** (`SYSTEM_ALERT_WINDOW`) feature. This prompts you to categorize the spend right on your screen—no need to even open the app. 

*What you build doesn't matter as much as how you build it.* In an era where UI can be easily generated, FocusFin focuses on robust **System Design** and **Zero-Knowledge Security Architecture**.

---

## 🔥 Key Features

### 🔒 Uncompromising Security
* **Zero-Knowledge E2EE:** Your data is locked with a Master Key that *only* you know. It is never stored on the server. If the key is lost, the data remains permanently encrypted.
* **Local SQLCipher Database:** Even if a malicious actor physically accesses your device and extracts the local SQLite database, the data remains unreadable without your Master Key.
* **Biometric App Lock:** Secure your account and hide your current balance behind native device fingerprint authentication.

### ⚡ Smart, Frictionless Tracking
* **Background SMS Parsing:** Utilizes a cached headless Flutter Engine and native Android Broadcast Receivers to detect bank transactions instantly.
* **Instant Categorization:** A seamless overlay prompts you to categorize expenses the second a transaction hits your phone.
* **Budget Control:** Set limits for different categories (Food, Travel, etc.) and receive smart alerts when you approach your spending thresholds.

### ✨ Premium UX & UI
* **Dynamic Dual Theme Engine:** A fully responsive Light & Dark mode architecture that instantly repaints the entire app without needing a restart.
* **Innovative Floating Navigation:** A custom, collapsible bottom navigation bar that auto-inverts its colors to contrast perfectly with the active theme, maximizing screen real estate.
* **Glassmorphism Design:** Beautiful `AppGlassCard` and `AppGlassSheet` components that give the app a modern, tactile feel.
* **Hero Balance Card:** A sticky, animated balance header featuring custom gradients (Royal Purple in Dark Mode, Black Diamond in Light Mode).

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** Riverpod 
* **Backend & Auth:** Firebase Authentication
* **Local Storage:** SQLite secured with SQLCipher
* **Native Android:** MethodChannels, BroadcastReceivers, and `SYSTEM_ALERT_WINDOW` permissions.

---

## 🏗️ Local Development Setup

To run this project locally, you will need to configure your own Firebase project.

1. Clone the repository:
   ```bash
   git clone [https://github.com/YourUsername/FocusFin.git](https://github.com/YourUsername/FocusFin.git)
