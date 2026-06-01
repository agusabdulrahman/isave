# Finoov

A modern personal finance application built with Flutter and Supabase to help users manage income, expenses, transfers, recurring transactions, and monthly budgets.

![Finoov Screenshot](assets/docs/Screenshot%202026-05-14%20113110.png)

---

## ✨ Features

### 💰 Transaction Management

* Record income and expense transactions
* Edit and delete transactions
* Categorize transactions
* Multi-account support

### 🔄 Account Transfer

* Transfer funds between accounts
* Automatic balance updates

### ⏰ Recurring Transactions

* Schedule recurring income or expenses
* Automatically generate transactions when due

### 📊 Budget Planning

* Monthly budget management
* Auto reset every month
* Manual budget configuration

### 🔐 Authentication

* Secure authentication with Supabase Auth
* User-specific data isolation

### 🌎 Multi Currency

* Indonesian Rupiah (IDR)
* United States Dollar (USD)

---

## 🛠 Tech Stack

| Technology   | Description                       |
| ------------ | --------------------------------- |
| Flutter      | Cross-platform mobile framework   |
| Supabase     | Backend, Authentication, Database |
| Google Fonts | Typography                        |
| Material 3   | Modern UI Design System           |

---

## 📂 Project Structure

```text
lib/
├── config/
├── controller/
├── model/
├── routes/
├── utils/
├── view/
│   ├── core/
│   ├── home/
│   ├── wallet/
│   ├── goals/
│   ├── profile/
│   └── app.dart
├── widgets/
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK 3.x+
* Dart SDK 3.x+
* Active Supabase Project

Required database tables:

```text
profiles
accounts
categories
transactions
recurring_transactions
```

---

## ⚙️ Configuration

Supabase configuration is currently stored in:

```text
lib/config/supabase_config.dart
```

Example:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

For production deployments, use environment variables or secret management.

---

## ▶️ Run Project

Install dependencies:

```bash
flutter pub get
```

Run application:

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

---

## 📦 Build Release

### Android App Bundle (Google Play Store)

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

### Android APK

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ Code Quality

Format code:

```bash
dart format lib
```

Analyze project:

```bash
flutter analyze
```

---

## 🧑‍💻 Development Commands

```text
r   Hot Reload
R   Hot Restart
h   Show Available Commands
d   Detach Application
c   Clear Console
q   Quit
```

---

## 🔒 Security Notes

* All data is filtered using `user_id`
* Users can only access their own records
* Do not commit Supabase credentials to source control
* Use environment variables for production deployments

---

## 🗺 Roadmap

* [ ] Financial goals tracking
* [ ] Savings analytics dashboard
* [ ] Charts and reporting
* [ ] Export transactions (PDF / Excel)
* [ ] Notification reminders
* [ ] Dark mode support
* [ ] Multi-language support

---

## 📄 License

This project is intended for educational and personal finance management purposes.
