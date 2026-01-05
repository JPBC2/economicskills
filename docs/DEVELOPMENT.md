# Development Guide

This guide covers local development setup for the EconomicSkills project.

---

## Project Structure

```
economicskills/
├── apps/
│   ├── admin/          # Admin CMS (Flutter Windows)
│   └── web/            # Student web app (if created)
├── lib/                # Main Flutter web application
├── packages/
│   └── shared/         # Shared models and services
├── supabase/
│   ├── functions/      # Edge Functions (Deno)
│   └── migrations/     # Database migrations
├── docs/               # Documentation
└── assets/             # Images and icons
```

---

## Prerequisites

### Required Tools
- **Flutter SDK** 3.x or later
- **Dart SDK** (included with Flutter)
- **Supabase CLI** 2.x or later
- **Git**

### Windows-Specific
- Visual Studio 2022 with C++ desktop development workload
- Windows 10 SDK

### Verify Installation
```bash
flutter doctor -v
supabase --version
```

---

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/JPBC2/economicskills.git
cd economicskills
```

### 2. Install Dependencies
```bash
# Root project
flutter pub get

# Shared package
cd packages/shared && flutter pub get

# Admin app
cd apps/admin && flutter pub get
```

### 3. Configure Environment

Create `.env` file in root (for local development):
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
```

---

## Running the Applications

### Web Application (Chrome)
```bash
flutter run -d chrome
```

### Admin CMS (Windows)
```bash
cd apps/admin
flutter run -d windows
```

Or from root:
```bash
cd apps\admin; flutter run -d windows
```

---

## Database Setup

### Running Migrations

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy and run each migration file in order:
   - `supabase/migrations/20231123_initial_schema.sql`
   - `supabase/migrations/20260103_content_translations.sql`
   - `supabase/migrations/20260103_add_lesson_columns.sql`
   - `supabase/migrations/20260104_edge_functions_tables.sql`

### Using Supabase CLI (Local Development)
```bash
supabase start
supabase db reset  # Runs all migrations
```

---

## Edge Functions

### Local Development
```bash
# Start local Supabase
supabase start

# Serve a specific function
supabase functions serve copy-spreadsheet --env-file .env.local
```

### Deployment
```bash
supabase functions deploy copy-spreadsheet
supabase functions deploy validate-spreadsheet
supabase functions deploy delete-spreadsheet
```

### Testing
```bash
curl -X POST http://localhost:54321/functions/v1/copy-spreadsheet \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"template_id":"...", "section_id":"...", "user_id":"...", "new_name":"Test"}'
```

---

## Code Style

### Flutter/Dart
- Use `flutter analyze` to check for issues
- Follow effective dart style guide
- Run `flutter format .` before committing

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `course_editor.screen.dart` |
| Classes | PascalCase | `CourseEditorScreen` |
| Variables | camelCase | `courseTitle` |
| Constants | camelCase | `defaultLanguage` |

---

## Git Workflow

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation

### Commit Messages
```
feat: Add multilingual translation support
fix: Correct unlock_cost_xp column name
docs: Update GOOGLE_CLOUD_SETUP.md
```

### Committing Changes
```bash
git add -A
git commit -m "feat: Description of changes"
git push
```

---

## Testing

### Running Tests
```bash
# All tests
flutter test

# Admin app tests
cd apps/admin && flutter test

# Shared package tests
cd packages/shared && flutter test
```

### Widget Tests
Located in `test/` directory of each project.

---

## Troubleshooting

### Flutter Issues
```bash
flutter clean
flutter pub get
```

### Dependency Conflicts
```bash
flutter pub upgrade --major-versions
```

### Supabase Connection Issues
- Verify URL and keys in environment
- Check Supabase project status
- Try `supabase db reset` for local development

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `flutter run -d chrome` | Run web app |
| `flutter run -d windows` | Run Windows app |
| `flutter analyze` | Check for issues |
| `flutter format .` | Format code |
| `flutter clean` | Clean build |
| `supabase start` | Start local Supabase |
| `supabase functions serve` | Serve edge functions |
| `supabase functions deploy` | Deploy functions |

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Google Sheets API](https://developers.google.com/sheets/api)
- [Deno Documentation](https://docs.deno.com/)
