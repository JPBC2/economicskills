# Admin CMS Guide

The Admin CMS is a Flutter Windows application for managing EconomicSkills course content.

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- Windows development environment

### Running the Admin App

```bash
cd apps/admin
flutter run -d windows
```

Or from the root directory:
```bash
cd apps\admin; flutter run -d windows
```

---

## Authentication

The Admin CMS uses Google OAuth for authentication. Only authorized admin accounts can access the CMS.

1. Click **"Sign in with Google"**
2. Select your admin Google account
3. Authorize the application

---

## Navigation

The main dashboard has a navigation rail on the left:

| Icon | Section | Description |
|------|---------|-------------|
| 📊 | Dashboard | Overview and quick actions |
| 📚 | Courses | Manage courses and content hierarchy |
| ❓ | Quizzes | Quiz management (coming soon) |
| 👥 | Users | User management (coming soon) |
| ⚙️ | Settings | App settings (coming soon) |

---

## Content Hierarchy

EconomicSkills content is organized hierarchically:

```
Course (e.g., Microeconomics)
└── Unit (e.g., Fundamentals)
    └── Lesson (e.g., Scarcity)
        └── Exercise (e.g., Calculating economic profit)
            └── Section (e.g., Cashflows spreadsheet)
```

---

## Managing Courses

### View All Courses
1. Click **"Courses"** in the navigation rail
2. See list of all courses with title and status

### Create a New Course
1. Click **"+ New Course"** button
2. Fill in:
   - **Title** (required in English)
   - **Description** (optional)
   - **Display Order** (lower = appears first)
   - **Active** toggle (visible to students)
3. Switch language tabs to add translations
4. Click **"Create"**

### Edit a Course
1. Click the edit icon (✏️) on a course
2. Modify fields as needed
3. Click **"Save"**

---

## Managing Units

### Navigate to Units
1. Edit a course
2. Click **"Manage Units"** button in the sidebar

### Create a Unit
1. Click **"+ New Unit"**
2. Fill in:
   - **Title** (English required)
   - **Description**
   - **Display Order**
   - **Premium Unit** (requires XP to unlock)
   - **Unlock Cost** (XP required if premium)
3. Add translations in other languages
4. Click **"Create"**

---

## Managing Lessons

### Navigate to Lessons
1. From the Units list, click on a unit
2. This shows the Lessons for that unit

### Create a Lesson
1. Click **"+ New Lesson"**
2. Fill in:
   - **Title**
   - **Explanation** (lesson content)
   - **Source References** (optional)
   - **YouTube Video URL** (optional)
3. Add translations
4. Click **"Create"**

---

## Managing Exercises

### Navigate to Exercises
1. From the Lessons list, click on a lesson

### Create an Exercise
1. Click **"+ New Exercise"**
2. Fill in:
   - **Title**
   - **Instructions** (what students should do)
3. Add translations
4. Click **"Create"**

---

## Managing Sections (Spreadsheets)

Sections link to Google Sheets templates that students will work on.

### Navigate to Sections
1. From the Exercises list, click on an exercise

### Create a Section
1. Click **"+ New Section"**
2. Fill in:
   - **Title** (e.g., "Cashflows")
   - **Template Spreadsheet URL** (Google Sheets link)
   - **Solution Spreadsheet URL** (for validation)
   - **Validation Range** (e.g., `O3:O102`)
   - **XP Reward** (points for completion)
3. Click **"Create"**

### Important Notes
- The Template URL is automatically parsed to extract the spreadsheet ID
- Share the template with the service account email (see GOOGLE_CLOUD_SETUP.md)
- The solution spreadsheet is used to validate student answers

---

## Multilingual Support

The Admin CMS supports 6 languages:

| Flag | Code | Language |
|------|------|----------|
| 🇺🇸 | en | English |
| 🇨🇳 | zh | 中文 (Chinese) |
| 🇷🇺 | ru | Русский (Russian) |
| 🇪🇸 | es | Español (Spanish) |
| 🇫🇷 | fr | Français (French) |
| 🇧🇷 | pt | Português (Portuguese) |

### Adding Translations
1. In any editor, click the language chips at the top
2. Switch to the desired language
3. Enter the translated content
4. Translations are saved automatically when you save the record

### Translation Requirements
- **English is always required** for the primary content
- Other languages are optional
- Students see content in their preferred language, falling back to English

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + S` | Save current item |
| `Escape` | Cancel / Go back |

---

## Troubleshooting

### "Error: Column not found"
- Run the latest database migrations in Supabase SQL Editor
- Check `supabase/migrations/` for pending migrations

### "Sign in failed"
- Ensure you're using an authorized admin Google account
- Check Supabase Auth configuration

### Changes not saving
- Check your internet connection
- Verify Supabase project is running
- Check browser console for error details
