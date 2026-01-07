# Python Exercises Implementation Guide

## Overview

This document tracks the implementation of interactive Python exercises for the EconomicSkills platform, allowing students to complete sections using either Google Sheets or Python code (or both).

---

## ✅ Phase 1: Foundation (COMPLETED)

### 1.1 Database Migration ✅

**File Created:** `supabase/migrations/20260108_python_exercises.sql`

**Changes Made:**
- Added `supports_spreadsheet` and `supports_python` flags to `sections` table
- Added Python starter code columns for 11 languages (en, es, zh, ru, fr, pt, it, ca, ro, de, nl)
- Added `python_solution_code` column (admin reference only)
- Added `python_validation_config` JSONB column for validation rules
- Added `completed_with` tracking to `user_progress` table ('spreadsheet', 'python', or 'both')

**Next Step:** Apply migration to Supabase database
```bash
# In Supabase Dashboard > SQL Editor, run:
supabase/migrations/20260108_python_exercises.sql
```

### 1.2 Section Model Update ✅

**File Modified:** `packages/shared/lib/models/course.model.dart`

**Changes Made:**
- Added `supportsSpreadsheet` and `supportsPython` boolean fields
- Added `pythonStarterCode` Map<String, String?> for multilingual starter code
- Added `pythonSolutionCode` String? for admin reference
- Added `pythonValidationConfig` Map<String, dynamic>? for validation rules
- Added `getPythonStarterCodeForLanguage()` helper method
- Updated `fromJson()` to parse Python fields from database
- Updated `toJson()` to serialize Python fields

**Example Usage:**
```dart
final section = Section.fromJson(jsonData);

// Check if Python is supported
if (section.supportsPython) {
  // Get starter code for user's language
  final starterCode = section.getPythonStarterCodeForLanguage('es');

  // Get validation config
  final validationConfig = section.pythonValidationConfig;
}
```

---

## 📋 Phase 2: Next Steps

### 2.1 Apply Database Migration

**Action Required:** Run the migration in Supabase

**Steps:**
1. Open Supabase Dashboard for your project
2. Navigate to **SQL Editor**
3. Copy contents of `supabase/migrations/20260108_python_exercises.sql`
4. Paste and execute
5. Verify columns were added:
   ```sql
   SELECT column_name, data_type
   FROM information_schema.columns
   WHERE table_name = 'sections'
   AND column_name LIKE '%python%';
   ```

### 2.2 Create Pyodide Service (Flutter Web)

**File to Create:** `lib/app/services/pyodide_service.dart`

**Purpose:**
- Load Pyodide (Python WebAssembly runtime) in browser
- Execute Python code
- Run validation tests
- Return results to UI

**Key Features:**
- Lazy loading (only load when user opens Python exercise)
- Web Worker (non-blocking UI)
- Package management (NumPy, Pandas, SciPy, Matplotlib)
- Error handling and output capture

**Estimated Bundle Size:**
- Core Pyodide: ~11MB
- NumPy + Pandas: ~20MB
- Full scientific stack: ~30MB
- (Cached after first load)

### 2.3 Create Python Exercise Widget

**File to Create:** `lib/app/widgets/python_exercise_widget.dart`

**Components:**
- Code editor (syntax highlighting, line numbers)
- Run button (execute code, show output)
- Submit button (run validation, award XP)
- Output panel (console output, errors, charts)
- Feedback panel (step-by-step validation results)

**Dependencies:**
```yaml
# pubspec.yaml
dependencies:
  flutter_code_editor: ^0.3.0  # Code editor with syntax highlighting
  highlight: ^0.7.0  # Python syntax highlighting
  # OR use CodeMirror via iframe
```

### 2.4 Update Section Screen

**File to Modify:** `lib/app/screens/content/section.screen.dart`

**Changes Needed:**
- Add tool selector tabs (Sheets / Python)
- Conditional rendering based on `supportsSpreadsheet` and `supportsPython`
- Pass section data to PythonExerciseWidget
- Handle XP awards for Python completion
- Track `completed_with` in user_progress

**UI Flow:**
```
┌─────────────────────────────────────────────────────────┐
│ Section: Calculate Mean and Standard Deviation         │
├─────────────────────────────────────────────────────────┤
│ Tools:  [📊 Google Sheets]  [🐍 Python] ←─ Tabs        │
├─────────────────────────────────────────────────────────┤
│  Instructions              │  Python Editor             │
│  (Collapsible)             │  (CodeMirror)              │
│                            │                            │
│  Step 1: Load data...      │  import pandas as pd       │
│  Step 2: Calculate mean... │  df = pd.read_csv(...)     │
│                            │                            │
│                            │  [▶ Run]  [Submit ✓]       │
│                            │                            │
│                            │  Output:                   │
│                            │  ✓ Step 1: Data loaded     │
│                            │  ✗ Step 2: Mean incorrect  │
└─────────────────────────────────────────────────────────┘
```

### 2.5 Update Admin Section Editor

**File to Modify:** `apps/admin/lib/screens/sections/section_editor.screen.dart`

**Changes Needed:**
- Add exercise type toggles (Spreadsheet / Python / Both)
- Add Python code editors:
  - Starter code (multilingual tabs)
  - Solution code (admin reference)
  - Validation config (JSON or UI builder)
- Add data file upload (Supabase Storage)
- Add preview button

**Admin UI Mock:**
```
┌─────────────────────────────────────────────────────────┐
│ Section Editor                                          │
├─────────────────────────────────────────────────────────┤
│ Title: [Calculate Mean and Std Dev]                     │
│ XP Reward: [15]                                         │
│                                                         │
│ Exercise Tools (user chooses):                          │
│ [✓] Google Sheets    [✓] Python                         │
│                                                         │
│ ┌─ Google Sheets Configuration ────────────────────┐   │
│ │ Template URL (EN): [https://...]                 │   │
│ │ Solution URL (EN): [https://...]                 │   │
│ └───────────────────────────────────────────────────┘   │
│                                                         │
│ ┌─ Python Configuration ───────────────────────────┐   │
│ │ Language: [EN ▼] [ES] [ZH] [RU] ...              │   │
│ │                                                   │   │
│ │ Starter Code:                                     │   │
│ │ ┌───────────────────────────────────────────────┐ │   │
│ │ │ import pandas as pd                           │ │   │
│ │ │                                               │ │   │
│ │ │ # Load the stock prices                       │ │   │
│ │ │ # df = pd.read_csv('prices.csv')              │ │   │
│ │ │                                               │ │   │
│ │ │ # Calculate mean                              │ │   │
│ │ │ # mean = ...                                  │ │   │
│ │ └───────────────────────────────────────────────┘ │   │
│ │                                                   │   │
│ │ Validation (Simple Mode):                         │   │
│ │ ┌───────────────────────────────────────────────┐ │   │
│ │ │ Step 1: Variable 'df' exists (DataFrame)      │ │   │
│ │ │ Step 2: Variable 'mean' = 42.5 (±0.01)        │ │   │
│ │ │ Step 3: Output contains "Mean"                │ │   │
│ │ └───────────────────────────────────────────────┘ │   │
│ │ [+ Add Validation Step]                           │   │
│ └───────────────────────────────────────────────────┘   │
│                                                         │
│ [Preview Python Exercise]                               │
│ [Cancel]                          [Save Section]        │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Validation Configuration Examples

### Simple Validation (Recommended for MVP)

Stored in `python_validation_config` JSONB column:

```json
{
  "validation_type": "simple",
  "steps": [
    {
      "step": 1,
      "type": "variable_exists",
      "name": "df",
      "expected_type": "DataFrame",
      "message_en": "Load the CSV file into a DataFrame called 'df'",
      "message_es": "Carga el archivo CSV en un DataFrame llamado 'df'"
    },
    {
      "step": 2,
      "type": "variable_value",
      "name": "mean_price",
      "expected": 42.5,
      "tolerance": 0.01,
      "message_en": "Calculate the mean price using df['price'].mean()",
      "message_es": "Calcula el precio medio usando df['price'].mean()"
    },
    {
      "step": 3,
      "type": "output_contains",
      "pattern": "Mean.*\\d+\\.\\d+",
      "message_en": "Print the mean value",
      "message_es": "Imprime el valor medio"
    }
  ]
}
```

### Advanced Validation (pythonwhat - Future)

```json
{
  "validation_type": "pythonwhat",
  "sct_code": "Ex().check_object('df').has_equal_value()\nEx().check_object('mean_price').has_equal_value()"
}
```

---

## 📦 Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Python Runtime** | Pyodide (WebAssembly) | Execute Python in browser |
| **Code Editor** | CodeMirror 6 or Monaco | Syntax highlighting, autocomplete |
| **Validation** | Custom (Phase 1) → pythonwhat (Phase 2) | Check student code |
| **Data Files** | Supabase Storage | Host CSV/datasets |
| **Backend** | Supabase Edge Functions (existing) | XP awards, progress tracking |

---

## 🎯 Implementation Timeline

### Week 1: Core Infrastructure ✅
- [x] Database migration
- [x] Section model updates
- [ ] Apply migration to Supabase
- [ ] Create PyodideService POC

### Week 2: Student Interface
- [ ] PythonExerciseWidget
- [ ] Section screen integration
- [ ] Simple validation engine
- [ ] Testing with sample exercise

### Week 3: Admin Interface
- [ ] Section editor Python fields
- [ ] Validation step builder UI
- [ ] Data file upload
- [ ] Preview functionality

### Week 4: Polish & Advanced Features
- [ ] Error handling
- [ ] Loading states
- [ ] Mobile responsive
- [ ] pythonwhat integration (optional)

---

## 🔍 Testing Strategy

### Test Cases

1. **Exercise with Python only**
   - supportsSpreadsheet: false
   - supportsPython: true
   - Verify only Python tab shows

2. **Exercise with Both options**
   - supportsSpreadsheet: true
   - supportsPython: true
   - Verify user can choose
   - Verify XP awarded correctly

3. **Multilingual starter code**
   - Set different starter code for EN and ES
   - Switch app locale
   - Verify correct code loads

4. **Validation**
   - Correct solution → XP awarded
   - Incorrect solution → feedback shown
   - Hint used → 30% XP penalty

---

## 📚 Sample Exercise: Statistics Mean & Std Dev

### Starter Code (English)
```python
import pandas as pd
import numpy as np

# Load the stock prices from the CSV file
# The file has columns: 'date', 'price'
# df = pd.read_csv(...)

# Calculate the mean (average) price
# mean_price = ...

# Calculate the standard deviation
# std_price = ...

# Print the results
# print(f"Mean: {mean_price:.2f}")
# print(f"Std Dev: {std_price:.2f}")
```

### Solution Code (Admin Only)
```python
import pandas as pd
import numpy as np

df = pd.read_csv('https://example.com/stock_prices.csv')
mean_price = df['price'].mean()
std_price = df['price'].std()

print(f"Mean: {mean_price:.2f}")
print(f"Std Dev: {std_price:.2f}")
```

### Validation Config
```json
{
  "validation_type": "simple",
  "steps": [
    {
      "step": 1,
      "type": "variable_exists",
      "name": "df",
      "expected_type": "DataFrame"
    },
    {
      "step": 2,
      "type": "variable_value",
      "name": "mean_price",
      "expected": 42.5,
      "tolerance": 0.01
    },
    {
      "step": 3,
      "type": "variable_value",
      "name": "std_price",
      "expected": 12.34,
      "tolerance": 0.01
    },
    {
      "step": 4,
      "type": "output_contains",
      "pattern": "Mean.*42\\.5"
    }
  ]
}
```

---

## 🚀 Next Actions

1. **Apply the database migration** in Supabase SQL Editor
2. **Test the Section model** by fetching a section with the new fields
3. **Create PyodideService** proof-of-concept
4. **Build PythonExerciseWidget** basic version
5. **Integrate into Section screen**
6. **Update Admin section editor**

---

## 📖 Resources

- [Pyodide Documentation](https://pyodide.org/en/stable/)
- [pythonwhat Documentation](https://pythonwhat.readthedocs.io/en/latest/)
- [CodeMirror 6](https://codemirror.net/)
- [Supabase Storage](https://supabase.com/docs/guides/storage)

---

## Questions or Issues?

- Check the pythonwhat research report for validation options
- See the exploration report for current codebase architecture
- Pyodide compatibility: All dependencies are pure Python ✅

---

**Status:** Phase 1 Complete - Ready for Database Migration
**Last Updated:** 2026-01-08
