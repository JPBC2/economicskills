# Economic Skills

[![Development Status](https://img.shields.io/badge/status-in%20active%20development-blue.svg)](https://github.com/JPBC2/economicskills)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **Master economics through interactive Google Sheets and Python exercises.**

🌐 **Live Demo:** [https://jpbc2.github.io/economicskills/](https://jpbc2.github.io/economicskills/)

---

## 📖 Overview

**Economic Skills** is an educational platform that bridges the gap between economic theory and real-world application. Developed for the Introduction to Economic Theory course at FES Acatlán (UNAM), it enables students to learn through hands-on exercises using **Google Sheets** and **Python**.

The platform includes:
- **Web Application** — Student-facing learning platform
- **Admin CMS** — Windows desktop app for content management (courses, units, lessons, exercises)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📊 **Google Sheets Exercises** | Solve economic problems in live spreadsheets with real-time validation |
| 🐍 **Python Exercises** | Write code to analyze economic data with instant feedback |
| 🌍 **15 Languages** | Full localization support (EN, ES, FR, ZH, RU, PT, IT, CA, RO, DE, NL, AR, ID, KO, JA) |
| 🎨 **Dark/Light Theme** | Toggle between themes for comfortable learning |
| 📱 **Responsive Design** | Works seamlessly on desktop, tablet, and mobile |
| 🔐 **Google OAuth** | Secure authentication via Google accounts |
| 📈 **Progress Tracking** | Monitor student progress through courses and exercises |

---

## 🏗️ Architecture

```
economicskills/
├── lib/                    # Web application (Flutter)
├── apps/
│   └── admin/              # Admin CMS (Flutter Desktop - Windows)
├── packages/
│   └── shared/             # Shared models and services
├── supabase/               # Database migrations and functions
└── docs/                   # Documentation
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Web + Windows Desktop) |
| **Backend** | Supabase (PostgreSQL + Auth + Storage) |
| **Exercises** | Google Sheets API, Python (in-browser) |
| **Deployment** | GitHub Pages |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK
- Visual Studio 2022 (for Windows Admin CMS)

### Run the Web App
```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

### Run the Admin CMS (Windows)
```bash
cd apps/admin
flutter run -d windows
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Technical Requirements](docs/REQUIREMENTS.md) | Complete Software Requirements Specification |
| [Development Guide](docs/DEVELOPMENT.md) | Setup, coding standards, and workflows |
| [Admin CMS Guide](docs/ADMIN_CMS_GUIDE.md) | How to manage content via the Admin app |
| [Google Cloud Setup](docs/GOOGLE_CLOUD_SETUP.md) | OAuth and API configuration |

---

## 🌐 Supported Languages

<table>
<tr>
<td>🇺🇸 English</td><td>🇪🇸 Español</td><td>🇫🇷 Français</td><td>🇨🇳 中文</td><td>🇷🇺 Русский</td>
</tr>
<tr>
<td>🇧🇷 Português</td><td>🇮🇹 Italiano</td><td>🏴󠁥󠁳󠁣󠁴󠁿 Català</td><td>🇷🇴 Română</td><td>🇩🇪 Deutsch</td>
</tr>
<tr>
<td>🇳🇱 Nederlands</td><td>🇸🇦 العربية</td><td>🇮🇩 Indonesia</td><td>🇰🇷 한국어</td><td>🇯🇵 日本語</td>
</tr>
</table>

---

## 📄 License

This project is licensed under the MIT License.

---

<p align="center">
  <strong>Repository:</strong> <a href="https://github.com/JPBC2/economicskills">github.com/JPBC2/economicskills</a>
</p>
