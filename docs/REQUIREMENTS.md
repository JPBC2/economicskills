# Software Requirements Specification (SRS)
## EconomicSkills Flutter Web Application

**Project Name:** EconomicSkills  
**Project Repository:** https://github.com/JPBC2/economicskills  
**Version:** 1.0  
**Date:** October 31, 2025  
**Document Status:** Draft

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) document provides a comprehensive description of the requirements for the EconomicSkills Flutter web application. The application is an interactive educational platform designed to teach applied economic theory through Google Sheets exercises. This document is intended for use by the development team, stakeholders, and future maintainers of the system.

The EconomicSkills application is being developed at the Acatlán School of Higher Studies, BA in International Relations, for the course "Introduction to Economic Theory."

### 1.2 Document Conventions

- **SHALL/MUST**: Indicates mandatory requirements that must be implemented
- **SHOULD**: Indicates recommended requirements that are highly desirable
- **MAY**: Indicates optional requirements
- **TBD**: To be determined - information pending future decisions

### 1.3 Project Scope

EconomicSkills is a Flutter web application that provides:

- User authentication via email/password and Google OAuth
- Interactive Google Sheets exercises for learning economic theory
- Automated assessment and validation of student work
- Experience Points (XP) system for progression
- Personalized student dashboards tracking course progress
- Public user profiles (optional visibility)
- Administrative capabilities for content management and analytics

The application uses Supabase for backend services including authentication, database, and user data management.

### 1.4 Intended Audience

This document is intended for:

- The sole developer/administrator of the application
- Future developers who may maintain or extend the system
- Academic stakeholders at Acatlán School of Higher Studies
- Students who will use the platform

### 1.5 References

- Flutter Documentation: https://flutter.dev/docs
- Supabase Documentation: https://supabase.com/docs
- Google Sheets API Documentation: https://developers.google.com/sheets/api
- Google Apps Script Documentation: https://developers.google.com/apps-script
- DataCamp Google Sheets Visualization Course (reference implementation)

---

## 2. Overall Description

### 2.1 Product Perspective

EconomicSkills is a self-contained educational web application that integrates with:

- **Supabase**: Authentication, database, and backend services
- **Google Sheets API**: Spreadsheet creation, management, and validation
- **Google Apps Script**: Exercise validation and automated grading
- **Google OAuth**: Social authentication
- **YouTube**: Embedded video content for lessons

The application is currently available at: https://jpbc2.github.io/economicskills/

### 2.2 Product Features

The major features of EconomicSkills include:

1. **User Authentication & Management**
   - Email/password authentication
   - Google OAuth integration
   - User profile management
   - Public profile visibility controls

2. **Course Management System**
   - 5 initial courses: Microeconomics, Macroeconomics, Statistics, Mathematics, Finance
   - Course structure: Courses → Units → Lessons → Exercises → Sections
   - Premium unit unlocking via XP points

3. **Interactive Google Sheets Exercises**
   - Just-in-time spreadsheet creation
   - Personal spreadsheet copies for each student
   - Exercise reset functionality
   - Multiple sections per exercise

4. **Automated Assessment System**
   - Cell value validation (numerical)
   - Formula validation
   - Calculated result verification
   - Chart/graph validation (type, formatting, data ranges)
   - Pass/Fail scoring with unlimited retries

5. **Experience Points (XP) System**
   - 10 XP per completed section/spreadsheet
   - XP-based unit unlocking (150 XP per premium unit)
   - Progress tracking

6. **Student Dashboard**
   - Personal metrics and progress visualization
   - Course, unit, and lesson completion tracking
   - Expandable progress trees
   - XP balance display

7. **Public Profiles**
   - Optional profile visibility
   - Customizable profile information
   - Progress sharing capabilities

8. **Administrative Functions**
   - Content creation and management
   - Spreadsheet template management
   - Analytics and reporting
   - Student performance insights

### 2.3 User Classes and Characteristics

#### 2.3.1 Students (Primary Users)

**Characteristics:**
- University students enrolled in economic theory courses
- Basic to intermediate computer literacy
- Access to modern web browsers
- Expected usage: 2-4 hours per week during semester

**Needs:**
- Clear learning objectives and instructions
- Immediate feedback on exercises
- Progress tracking and motivation (XP system)
- Accessible from various devices

**Technical Expertise:** Low to medium

#### 2.3.2 Administrator (Single User)

**Characteristics:**
- Course instructor and application developer
- Full technical knowledge of system architecture
- Content creator and maintainer

**Needs:**
- Content management capabilities
- Student analytics and reporting
- Template management for exercises
- System monitoring and maintenance tools

**Technical Expertise:** High

### 2.4 Operating Environment

**Client-Side Requirements:**
- Modern web browser (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+)
- Minimum screen resolution: 1024x768
- Internet connection: 1 Mbps minimum, 5 Mbps recommended
- JavaScript enabled

**Server-Side Environment:**
- Supabase cloud infrastructure
- Google Cloud Platform (for Sheets API and Apps Script)
- Flutter web hosting (GitHub Pages)

**Supported Platforms:**
- Web browsers on desktop (Windows, macOS, Linux)
- Web browsers on tablets (iPad, Android tablets)
- Mobile web browsers (limited support, future enhancement)

### 2.5 Design and Implementation Constraints

**Technology Stack Constraints:**
- Flutter web framework (current version as of October 2025)
- Supabase for backend (PostgreSQL database)
- Google Sheets API v4
- Google Apps Script for validation logic

**Performance Constraints:**
- Maximum concurrent users: 500
- Expected first cohort: 200 students
- Spreadsheet copy creation: < 5 seconds
- Exercise validation: < 3 seconds
- Dashboard loading: < 2 seconds

**Security Constraints:**
- Row Level Security (RLS) must be enabled on all Supabase tables
- Students can only access their own data
- Spreadsheet copies must be private to individual students
- Google OAuth must follow security best practices

**Business Constraints:**
- Development by single developer/administrator
- No payment processing in initial version
- Free tier limitations of Supabase and Google APIs must be considered

### 2.6 User Documentation

The following user documentation will be provided:

1. **Student User Guide** (embedded in application)
   - Getting started tutorial
   - How to complete exercises
   - Understanding the XP system
   - Dashboard navigation

2. **Inline Help**
   - Tooltips for key features
   - Exercise instructions within lessons
   - Video tutorials (YouTube embeds)

3. **Administrator Documentation** (separate document)
   - Content creation guidelines
   - Template management procedures
   - Analytics interpretation
   - System maintenance procedures

### 2.7 Assumptions and Dependencies

**Assumptions:**
1. Students have reliable internet access
2. Students are familiar with basic spreadsheet concepts
3. YouTube is accessible to all users
4. Google Sheets service remains available and stable
5. Students use devices with adequate screen size (tablets or larger)

**Dependencies:**
1. Supabase service availability and API stability
2. Google Sheets API availability and quota limits
3. Google Apps Script execution environment
4. Google OAuth service functionality
5. Flutter web framework compatibility with target browsers
6. GitHub Pages hosting availability

---

## 3. System Features and Requirements

### 3.1 User Authentication and Authorization

#### 3.1.1 Description and Priority

**Priority:** HIGH (Critical)

User authentication is the foundation of the application, enabling personalized learning experiences, progress tracking, and secure data management.

#### 3.1.2 Functional Requirements

**FR-AUTH-001:** The system SHALL provide email/password registration
- Users must provide valid email address
- Password must meet minimum security requirements (8+ characters)
- Email addresses must be unique in the system
- No email verification required for initial release

**FR-AUTH-002:** The system SHALL provide Google OAuth authentication
- Users can sign in using Google account
- Google profile information (name, email, photo) is captured
- OAuth token management handled by Supabase

**FR-AUTH-003:** The system SHALL maintain user sessions
- Sessions persist across browser refreshes
- Automatic session renewal
- Secure session token storage
- Session timeout after 7 days of inactivity

**FR-AUTH-004:** The system SHALL support user logout
- Clear session data on logout
- Redirect to home/login page after logout
- Revoke authentication tokens

**FR-AUTH-005:** The system SHALL NOT require student ID during signup
- Open registration for any user
- No approval process required
- Immediate access to content after registration

**FR-AUTH-006:** The system SHALL designate one administrator account
- Administrator role assigned to specific email address
- Administrator has elevated permissions
- All other accounts are student accounts

**FR-AUTH-007:** The system SHALL implement Row Level Security (RLS)
- All database tables must have RLS enabled
- Students can only read/write their own data
- Administrator can access necessary data for management
- Security policies enforced at database level

#### 3.1.3 Non-Functional Requirements

**NFR-AUTH-001:** Password storage must use industry-standard hashing (handled by Supabase Auth)

**NFR-AUTH-002:** OAuth implementation must follow Google's security guidelines

**NFR-AUTH-003:** Authentication operations must complete within 2 seconds

**NFR-AUTH-004:** The system must protect against common authentication attacks (SQL injection, brute force)

### 3.2 User Profile Management

#### 3.2.1 Description and Priority

**Priority:** MEDIUM

User profiles store student information and enable personalized dashboards and optional public profiles.

#### 3.2.2 Functional Requirements

**FR-PROFILE-001:** The system SHALL create a user profile upon registration
- Profile linked to authentication user ID
- Automatic profile creation via database trigger
- Initial profile populated with registration data

**FR-PROFILE-002:** The system SHALL store the following profile data:
- User ID (foreign key to auth.users)
- Full name
- Email address
- Profile photo URL (optional, from Google OAuth or uploaded)
- Program/degree (optional, future feature)
- University/institution (optional, future feature)
- Professional bio (optional, 150-250 characters, future feature)
- Social media links: LinkedIn, GitHub, X, website (optional, future feature)
- Public profile visibility flag (boolean)
- Created timestamp
- Last updated timestamp

**FR-PROFILE-003:** The system SHALL NOT allow profile editing in initial release
- Profile editing is a future feature
- Name and photo captured at registration
- Changes require administrator intervention in v1.0

**FR-PROFILE-004:** The system SHALL NOT allow password changes in initial release
- Password change is a future feature
- Users must use password reset via email (Supabase feature)

#### 3.2.3 Database Schema

**Table: public.profiles**

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  profile_photo_url TEXT,
  program_degree TEXT,
  university_institution TEXT,
  professional_bio TEXT CHECK (char_length(professional_bio) BETWEEN 150 AND 250),
  linkedin_url TEXT,
  github_url TEXT,
  x_url TEXT,
  website_url TEXT,
  public_profile_visible BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Users can read public profiles
CREATE POLICY "Anyone can view public profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public_profile_visible = TRUE);

-- Policy: Users can update their own profile (future)
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### 3.3 Course Structure and Content Management

#### 3.3.1 Description and Priority

**Priority:** HIGH (Critical)

The course structure defines the hierarchy of learning content and manages course, unit, lesson, and exercise organization.

#### 3.3.2 Functional Requirements

**FR-COURSE-001:** The system SHALL support multiple courses
- Initial release: 5 courses (Microeconomics, Macroeconomics, Statistics, Mathematics, Finance)
- Future expansion: Marketing, Accounting (out of scope for v1.0)
- All courses visible to all authenticated students

**FR-COURSE-002:** The system SHALL organize content in hierarchical structure:
- **Course** → Contains multiple Units (~10 units per course)
- **Unit** → Contains multiple Lessons (~3 lessons per unit)
- **Lesson** → Contains explanatory content + 1 Exercise
- **Exercise** → Contains 1-3 Sections/Spreadsheets
- **Section** → Represents one interactive spreadsheet

**FR-COURSE-003:** Each lesson SHALL contain:
- Lesson title
- Explanatory text (rich text format)
- Source references (books or websites)
- YouTube video URL (embedded player)
- One exercise with instructions

**FR-COURSE-004:** Each exercise SHALL contain:
- Exercise title
- Detailed instructions/tasks
- 1 to 3 sections (spreadsheets)
- Reference to spreadsheet template(s)

**FR-COURSE-005:** The system SHALL support premium unit access control
- Units can be marked as "free" or "premium"
- Premium units require 150 XP to unlock
- Students can unlock premium units using earned XP
- Unlock is permanent once purchased

**FR-COURSE-006:** The system SHALL NOT implement prerequisites
- All units accessible based only on XP availability
- No forced sequential progression
- Students can choose learning path

**FR-COURSE-007:** The administrator SHALL be able to create/edit/delete courses
- Full CRUD operations on courses, units, lessons, exercises
- Spreadsheet template management
- Content visible immediately after creation

**FR-COURSE-008:** The administrator SHALL be able to designate units as premium
- Toggle premium status on units
- Set unlock cost (default 150 XP)
- View unlock statistics

#### 3.3.3 Database Schema

**Table: public.courses**

```sql
CREATE TABLE public.courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view active courses"
  ON public.courses FOR SELECT
  TO authenticated
  USING (is_active = TRUE);
```

**Table: public.units**

```sql
CREATE TABLE public.units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  display_order INTEGER NOT NULL,
  is_premium BOOLEAN DEFAULT FALSE,
  unlock_cost INTEGER DEFAULT 150,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view active units"
  ON public.units FOR SELECT
  TO authenticated
  USING (is_active = TRUE);
```

**Table: public.lessons**

```sql
CREATE TABLE public.lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  explanation_text TEXT NOT NULL,
  source_references TEXT,
  youtube_video_url TEXT,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view active lessons"
  ON public.lessons FOR SELECT
  TO authenticated
  USING (is_active = TRUE);
```

**Table: public.exercises**

```sql
CREATE TABLE public.exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  instructions TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view exercises"
  ON public.exercises FOR SELECT
  TO authenticated
  USING (TRUE);
```

**Table: public.sections**

```sql
CREATE TABLE public.sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  display_order INTEGER NOT NULL,
  template_spreadsheet_id TEXT NOT NULL,
  xp_reward INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view sections"
  ON public.sections FOR SELECT
  TO authenticated
  USING (TRUE);
```

### 3.4 Google Sheets Integration

#### 3.4.1 Description and Priority

**Priority:** HIGH (Critical)

Google Sheets integration enables the core interactive learning experience through spreadsheet exercises.

#### 3.4.2 Functional Requirements

**FR-SHEETS-001:** The system SHALL create spreadsheet template for each section
- Administrator creates master template in Google Drive
- Template stored with "Anyone with link can view" permissions
- Template ID stored in sections table
- Template contains starter data and structure

**FR-SHEETS-002:** The system SHALL create personal spreadsheet copies just-in-time
- Copy created when student clicks "Start Lesson" button
- Copy created when student accesses lesson URL for first time
- One copy per student per section
- Copy named: "CourseTitle_UnitTitle_LessonTitle_SectionTitle_UserID"

**FR-SHEETS-003:** The system SHALL use Google Sheets API for copy operations
- Service account authentication
- Drive API for copy creation
- Sheets API for data manipulation
- Permission management to restrict access

**FR-SHEETS-004:** The system SHALL store spreadsheet copy metadata
- User ID
- Section ID  
- Google Sheets file ID
- Creation timestamp
- Completion status
- Last accessed timestamp

**FR-SHEETS-005:** The system SHALL provide "Reset" functionality
- Reset button available on exercise page
- Deletes current spreadsheet from Google Drive
- Creates new copy from template
- Resets completion status
- Preserves XP already earned

**FR-SHEETS-006:** The system SHALL embed spreadsheets in Flutter app
- Use WebView widget for display
- Optimize iframe parameters for mobile viewing
- Ensure proper authentication flow
- Enable full spreadsheet editing capabilities

**FR-SHEETS-007:** The system SHALL allow students to access completed spreadsheets
- Students can return to view/edit old spreadsheets
- No time limit on access
- Spreadsheet accessible from lesson page

**FR-SHEETS-008:** The system SHALL implement spreadsheet retention policy
- Incomplete spreadsheets retained for 5 months
- Completed spreadsheets deleted after validation (optional)
- Automated cleanup job runs monthly

**FR-SHEETS-009:** The system SHALL manage spreadsheet permissions
- Only the owning student can access their spreadsheet
- Administrator service account has access for validation
- No public sharing links
- Permissions verified on each access

#### 3.4.3 Database Schema

**Table: public.user_spreadsheets**

```sql
CREATE TABLE public.user_spreadsheets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  section_id UUID REFERENCES public.sections(id) ON DELETE CASCADE NOT NULL,
  spreadsheet_id TEXT NOT NULL,
  spreadsheet_url TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, section_id)
);

ALTER TABLE public.user_spreadsheets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own spreadsheets"
  ON public.user_spreadsheets FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own spreadsheets"
  ON public.user_spreadsheets FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

#### 3.4.4 Technical Implementation Notes

**Google Sheets API Setup:**
1. Create Google Cloud Project
2. Enable Google Sheets API and Google Drive API
3. Create Service Account with Editor role
4. Download service account JSON key
5. Share template spreadsheets with service account email
6. Implement authentication in Flutter app

**Spreadsheet Copy Process:**
```
1. Student clicks "Start Lesson"
2. System checks if copy exists in user_spreadsheets table
3. If no copy exists:
   a. Call Google Drive API files.copy()
   b. Set permissions (private to student)
   c. Store metadata in user_spreadsheets table
   d. Return spreadsheet URL
4. If copy exists:
   a. Return existing spreadsheet URL
5. Embed spreadsheet in WebView
```

### 3.5 Exercise Validation and Assessment

#### 3.5.1 Description and Priority

**Priority:** HIGH (Critical)

Automated validation and assessment enable immediate feedback and XP rewards for student work.

#### 3.5.2 Functional Requirements

**FR-VALIDATION-001:** The system SHALL validate cell values (numerical)
- Check if specific cells contain correct numerical values
- Support for exact matches and ranges (e.g., 42.5 ± 0.1)
- Multiple cells can be validated per section
- Validation rules defined in template configuration

**FR-VALIDATION-002:** The system SHALL validate formulas
- Check if cell contains specific formula (e.g., =SUM(A1:A10))
- Formula structure verification
- Support for equivalent formulas (e.g., =A1+A2 vs =SUM(A1:A2))
- Case-insensitive formula matching

**FR-VALIDATION-003:** The system SHALL validate calculated results
- Verify results of formulas in specific cells
- Compare calculated value against expected result
- Support for tolerance in floating-point comparisons
- Chain of formula dependencies validated

**FR-VALIDATION-004:** The system SHALL validate charts and graphs
- **Chart existence**: Verify chart exists in spreadsheet
- **Chart type**: Validate chart type (column, line, pie, histogram, candlestick, scatter)
- **Data range**: Check correct data range selected (e.g., A1:A9,C1:E9)
- **Chart title**: Verify title text matches expected value
- **Title formatting**: Check title color, font size, bold/italic
- **Series colors**: Validate data series colors
- **Axis titles**: Check horizontal and vertical axis titles
- **Legend**: Verify legend position (bottom, right, top, left, labeled)
- **Legend formatting**: Check legend font, size, color
- **Series configuration**: Validate which data series are displayed/hidden

**FR-VALIDATION-005:** The system MAY validate additional chart properties (reasonable assumptions):
- Grid lines visibility and formatting
- Chart background color
- Data labels presence and format
- Trendlines (if applicable)
- Chart position and size (approximate)
- Multiple charts per spreadsheet

**FR-VALIDATION-006:** The system SHALL use Apps Script for validation
- Apps Script attached to template spreadsheets
- Validation function callable via custom menu or programmatically
- Returns validation results as JSON
- Logs validation attempts

**FR-VALIDATION-007:** The system SHALL implement "Submit Answer" functionality
- Submit button on exercise page
- Triggers validation via Apps Script
- Displays validation results to student
- Updates completion status if passed

**FR-VALIDATION-008:** The system SHALL use Pass/Fail scoring
- Binary assessment: exercise either passes or fails
- All validation criteria must pass for overall pass
- Partial credit not supported
- Clear feedback on which validations failed

**FR-VALIDATION-009:** The system SHALL allow unlimited retries
- Students can retry failed exercises indefinitely
- No penalty for failed attempts
- Progress saved between attempts
- Attempt count tracked (for analytics)

**FR-VALIDATION-010:** The system SHALL award XP upon completion
- 10 XP awarded per section when all validations pass
- XP awarded only once per section (first completion)
- XP added immediately to user balance
- Completion status updated in database

**FR-VALIDATION-011:** The system SHALL track completion at all levels
- **Section completion**: All validations pass
- **Exercise completion**: All sections completed
- **Lesson completion**: Exercise completed (1 exercise per lesson)
- **Unit completion**: All lessons in unit completed
- **Course completion**: All units in course completed

#### 3.5.3 Database Schema

**Table: public.validation_rules**

```sql
CREATE TABLE public.validation_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id UUID REFERENCES public.sections(id) ON DELETE CASCADE NOT NULL,
  rule_type TEXT NOT NULL, -- 'cell_value', 'formula', 'calculated_result', 'chart'
  rule_config JSONB NOT NULL, -- Flexible config for different rule types
  display_order INTEGER NOT NULL,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.validation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view validation rules"
  ON public.validation_rules FOR SELECT
  TO authenticated
  USING (TRUE);
```

**Example validation_rules.rule_config for different types:**

```json
// Cell value validation
{
  "cell": "B5",
  "expected_value": 42.5,
  "tolerance": 0.1
}

// Formula validation
{
  "cell": "C10",
  "expected_formula": "=SUM(A1:A9)",
  "allow_equivalent": true
}

// Calculated result validation
{
  "cell": "D15",
  "expected_result": 125.75,
  "tolerance": 0.01
}

// Chart validation
{
  "chart_title": "Fatal, Injured, and Uninjured Statistics",
  "chart_type": "COLUMN",
  "data_range": "A1:A9,C1:E9",
  "title_color": "#000000",
  "title_bold": true,
  "legend_position": "BOTTOM",
  "series_colors": ["#FF0000", "#00FF00", "#0000FF"],
  "horizontal_axis_title": "State",
  "vertical_axis_title": "Number of Cases"
}
```

**Table: public.user_progress**

```sql
CREATE TABLE public.user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  section_id UUID REFERENCES public.sections(id) ON DELETE CASCADE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  xp_earned INTEGER DEFAULT 0,
  attempt_count INTEGER DEFAULT 0,
  first_attempt_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  last_attempt_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, section_id)
);

ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON public.user_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON public.user_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

#### 3.5.4 Apps Script Implementation

**Template Spreadsheet Apps Script Requirements:**

1. **Validation Function Structure:**
```javascript
function validateExercise() {
  var results = {
    overall_pass: true,
    validations: [],
    timestamp: new Date().toISOString()
  };
  
  // Run all validation rules
  results.validations.push(validateCellValue('B5', 42.5, 0.1));
  results.validations.push(validateFormula('C10', '=SUM(A1:A9)'));
  results.validations.push(validateChart('Chart 1', chartConfig));
  
  // Determine overall pass/fail
  results.overall_pass = results.validations.every(v => v.passed);
  
  return results;
}
```

2. **Chart Validation Function:**
```javascript
function validateChart(chartTitle, expectedConfig) {
  var sheet = SpreadsheetApp.getActiveSheet();
  var charts = sheet.getCharts();
  var result = {
    rule: 'chart_validation',
    passed: false,
    details: {}
  };
  
  // Find chart by title
  var chart = charts.find(c => c.getOptions().get('title') === chartTitle);
  if (!chart) {
    result.details.error = 'Chart not found';
    return result;
  }
  
  // Validate chart type
  var chartType = chart.getChartType();
  if (chartType !== expectedConfig.chart_type) {
    result.details.chart_type = {
      expected: expectedConfig.chart_type,
      actual: chartType,
      passed: false
    };
    return result;
  }
  
  // Validate data range
  var ranges = chart.getRanges();
  var rangeA1Notation = ranges.map(r => r.getA1Notation()).join(',');
  if (rangeA1Notation !== expectedConfig.data_range) {
    result.details.data_range = {
      expected: expectedConfig.data_range,
      actual: rangeA1Notation,
      passed: false
    };
    return result;
  }
  
  // Validate title formatting
  var titleTextStyle = chart.getOptions().get('titleTextStyle');
  if (titleTextStyle.color !== expectedConfig.title_color) {
    result.details.title_color = {
      expected: expectedConfig.title_color,
      actual: titleTextStyle.color,
      passed: false
    };
    return result;
  }
  
  if (titleTextStyle.bold !== expectedConfig.title_bold) {
    result.details.title_bold = {
      expected: expectedConfig.title_bold,
      actual: titleTextStyle.bold,
      passed: false
    };
    return result;
  }
  
  // Validate legend position
  var legendPosition = chart.getOptions().get('legend').get('position');
  if (legendPosition !== expectedConfig.legend_position) {
    result.details.legend_position = {
      expected: expectedConfig.legend_position,
      actual: legendPosition,
      passed: false
    };
    return result;
  }
  
  // All validations passed
  result.passed = true;
  return result;
}
```

3. **Web App Endpoint:**
```javascript
function doPost(e) {
  var params = JSON.parse(e.postData.contents);
  var action = params.action;
  
  if (action === 'validate') {
    var results = validateExercise();
    return ContentService
      .createTextOutput(JSON.stringify(results))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
```

### 3.6 Experience Points (XP) System

#### 3.6.1 Description and Priority

**Priority:** HIGH (Critical)

The XP system gamifies learning progression and enables premium content unlocking.

#### 3.6.2 Functional Requirements

**FR-XP-001:** The system SHALL award 10 XP per completed section
- XP awarded when all validation rules pass
- One-time award per section (no re-earning)
- Immediate credit to user XP balance

**FR-XP-002:** The system SHALL maintain user XP balance
- Running total of all earned XP
- Separate tracking of total earned vs. available XP
- Available XP = Total earned - XP spent on unlocks

**FR-XP-003:** The system SHALL enable premium unit unlocking
- Units marked as premium cost 150 XP
- Student can unlock if available XP ≥ 150
- Unlock is permanent (one-time purchase)
- Available XP reduced by unlock cost

**FR-XP-004:** The system SHALL display XP balance on dashboard
- Current available XP prominently displayed
- Total earned XP shown
- XP earned per course/unit/lesson

**FR-XP-005:** The system SHALL show XP requirements for locked units
- Locked units display "Unlock for 150 XP" badge
- Indication of how much more XP needed
- Preview of unit content (title, description)

**FR-XP-006:** The system SHALL NOT allow negative XP balances
- Prevent unlocking if insufficient XP
- Clear error message when XP insufficient
- Suggestion to earn more XP

#### 3.6.3 Database Schema

**Table: public.user_xp**

```sql
CREATE TABLE public.user_xp (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  total_xp_earned INTEGER DEFAULT 0,
  total_xp_spent INTEGER DEFAULT 0,
  available_xp INTEGER GENERATED ALWAYS AS (total_xp_earned - total_xp_spent) STORED,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.user_xp ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own XP"
  ON public.user_xp FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

**Table: public.unit_unlocks**

```sql
CREATE TABLE public.unit_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE NOT NULL,
  xp_cost INTEGER NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, unit_id)
);

ALTER TABLE public.unit_unlocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own unlocks"
  ON public.unit_unlocks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own unlocks"
  ON public.unit_unlocks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

**Table: public.xp_transactions**

```sql
CREATE TABLE public.xp_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  transaction_type TEXT NOT NULL, -- 'earned', 'spent'
  amount INTEGER NOT NULL,
  source_type TEXT NOT NULL, -- 'section_completion', 'unit_unlock'
  source_id UUID NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.xp_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON public.xp_transactions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

### 3.7 Student Dashboard

#### 3.7.1 Description and Priority

**Priority:** HIGH (Critical)

The student dashboard is the central hub for tracking progress and accessing courses.

#### 3.7.2 Functional Requirements

**FR-DASH-001:** The system SHALL display the dashboard as the default landing page
- Redirect to dashboard after login
- Dashboard is home screen for authenticated users
- Quick navigation to courses from dashboard

**FR-DASH-002:** The dashboard SHALL display personal information
- User's full name
- Profile photo (if available)

**FR-DASH-003:** The dashboard SHALL display completion metrics
- Total courses completed (count)
- Total units completed (count)
- Total lessons completed (count)

**FR-DASH-004:** The dashboard SHALL display XP information
- Current available XP (prominent)
- Total XP earned
- XP earned today/this week (optional enhancement)

**FR-DASH-005:** The dashboard SHALL list courses in progress
- Expandable/collapsible list of started courses
- Each course shows:
  - Course title
  - Progress bar (% complete)
  - Progress percentage (numerical)
  - Number of units completed / total units
  - Expandable unit list

**FR-DASH-006:** Course expansion SHALL show unit details
- List of units in the course
- Each unit shows:
  - Unit title
  - Lock icon (if premium and not unlocked)
  - Progress bar (% complete)
  - Progress percentage (numerical)
  - Number of lessons completed / total lessons
  - Expandable lesson list

**FR-DASH-007:** Unit expansion SHALL show lesson details
- List of lessons in the unit
- Each lesson shows:
  - Lesson title
  - Checkmark if completed
  - XP earned for lesson
  - Link to lesson page

**FR-DASH-008:** The dashboard SHALL have a "Course Catalog" widget
- Prominent call-to-action below dashboard metrics
- Button/link to browse all available courses
- Invitation text for new users

**FR-DASH-009:** The system SHALL calculate completion percentages
- Course % = (completed lessons / total lessons in course) × 100
- Unit % = (completed lessons / total lessons in unit) × 100

**FR-DASH-010:** The dashboard SHALL load efficiently
- Load time < 2 seconds for typical user (30 courses progress)
- Lazy loading for expanded sections
- Cached data where appropriate

#### 3.7.3 UI/UX Requirements

**Dashboard Layout:**

```
┌─────────────────────────────────────────────────────────┐
│ [App Logo]  EconomicSkills                              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Profile Photo] Hey, [User Name]!                      │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ Available XP│  │   Courses   │  │    Units    │      │
│  │     250     │  │  Completed  │  │  Completed  │      │
│  │             │  │      3      │  │     12      │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │                                                           │
│  ┌─────────────┐                                        │
│  │   Lessons   │                                        │
│  │  Completed  │                                        │
│  │     45      │                                        │
│  └─────────────┘                                        │
│                                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                         │
│  My Courses                                             │
│                                                         │
│  ▼ Microeconomics                    [Progress: 65%]    │
│    ████████████░░░░░                                    │
│                                                         │
│    ▼ Unit 1: Supply and Demand       [Progress: 100%]   │
│      ✓ Lesson 1: Introduction        10 XP              │
│      ✓ Lesson 2: Equilibrium         10 XP              │
│      ✓ Lesson 3: Elasticity          10 XP              │
│                                                         │
│    ▶ Unit 2: Consumer Theory         [Progress: 33%]    │
│                                                         │
│    🔒 Unit 3: Production (Premium)   [Unlock: 150 XP]   │
│                                                         │
│  ▶ Macroeconomics                    [Progress: 20%]    │
│                                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                         │
│  [Explore Course Catalog]                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.8 Course Catalog and Navigation

#### 3.8.1 Description and Priority

**Priority:** MEDIUM

Course catalog enables discovery and access to all available courses.

#### 3.8.2 Functional Requirements

**FR-NAV-001:** The system SHALL provide a "Courses" page
- Lists all available courses
- Shows course cards with:
  - Course title
  - Course description
  - Number of units
  - Estimated completion time (optional)
  - "Start Course" or "Continue" button

**FR-NAV-002:** The system SHALL provide a "My Library" page
- Shows only courses the user has started
- Same course card format as Courses page
- Quick access to in-progress courses
- Empty state message if no courses started

**FR-NAV-003:** The system SHALL provide navigation between pages
- Top navigation bar with:
  - Dashboard
  - Courses
  - My Library
  - Profile (future)
- Active page highlighted
- Mobile-responsive navigation (hamburger menu)

**FR-NAV-004:** The system SHALL provide course detail pages
- Click on course card opens detail page
- Shows complete course structure (units, lessons)
- Shows user's progress on this course
- Start/continue buttons for lessons

**FR-NAV-005:** The system SHALL provide lesson pages
- Displays lesson content (text, video, exercise)
- Embedded YouTube video player
- Source references
- Exercise instructions
- Embedded Google Sheets (if exercise started)
- "Start Exercise" or "Submit Answer" button
- "Reset" button (if exercise started)

**FR-NAV-006:** The system SHALL implement breadcrumb navigation
- Shows current location in hierarchy
- Clickable breadcrumbs to navigate back
- Example: Home > Microeconomics > Unit 1 > Lesson 1

### 3.9 Public Profiles

#### 3.9.1 Description and Priority

**Priority:** LOW

Public profiles enable optional sharing of progress and achievements.

#### 3.9.2 Functional Requirements

**FR-PUBLIC-001:** The system SHALL allow users to toggle profile visibility
- Profile visibility setting in user profile
- Default: Profile is private (not visible)
- Toggle switch to make public

**FR-PUBLIC-002:** Public profiles SHALL display selected information
- User's full name (always shown if public)
- Profile photo (optional)
- Program and university (optional, future)
- Professional bio (optional, future, 150-250 chars)
- Social media links (optional, future)
- Completion metrics (optional):
  - Courses completed count
  - Units completed count
  - Lessons completed count
- Course progress (optional):
  - Expandable list of courses started
  - Course progress bars and percentages
  - Unit progress (expandable)
  - Unit progress bars and percentages
  - Lesson list with completion checkmarks

**FR-PUBLIC-003:** The system SHALL provide public profile URLs
- Format: /profile/{username} or /profile/{user_id}
- Shareable link
- Accessible without authentication

**FR-PUBLIC-004:** The system SHALL respect privacy settings
- Private profiles return "Profile not found" or "Private profile"
- No data leakage for private profiles
- Students cannot view other private profiles

**FR-PUBLIC-005:** The system SHALL NOT display sensitive information
- Email addresses not shown on public profiles
- XP balance not shown
- Attempt counts not shown
- Spreadsheet access not provided

### 3.10 Administrator Functions

#### 3.10.1 Description and Priority

**Priority:** MEDIUM

Administrator functions enable content management and system monitoring.

#### 3.10.2 Functional Requirements

**FR-ADMIN-001:** The system SHALL identify the administrator account
- Single administrator email address configured
- Administrator role automatically assigned at login
- Administrator has access to admin panel

**FR-ADMIN-002:** The administrator SHALL be able to manage courses
- Create new courses
- Edit existing courses (title, description, order)
- Delete courses
- Activate/deactivate courses

**FR-ADMIN-003:** The administrator SHALL be able to manage units
- Create units within courses
- Edit units (title, description, order)
- Mark units as premium
- Set unlock cost for premium units
- Delete units

**FR-ADMIN-004:** The administrator SHALL be able to manage lessons
- Create lessons within units
- Edit lessons (title, content, video URL, sources)
- Reorder lessons
- Delete lessons

**FR-ADMIN-005:** The administrator SHALL be able to manage exercises
- Create exercises for lessons
- Edit exercise instructions
- Create sections within exercises
- Link sections to spreadsheet templates
- Define validation rules for sections
- Delete exercises

**FR-ADMIN-006:** The administrator SHALL be able to manage spreadsheet templates
- Upload template spreadsheets to Google Drive
- Associate templates with sections
- Update template IDs
- View template usage statistics

**FR-ADMIN-007:** The administrator SHALL be able to access analytics
- Course completion rates
- Unit completion rates
- Lesson completion rates
- Average time per lesson (future)
- Student engagement metrics
- Common failure points in exercises

**FR-ADMIN-008:** The administrator SHALL be able to view student progress
- Aggregate progress across all students
- Course-level progress breakdown
- Export progress reports (CSV)

**FR-ADMIN-009:** The administrator SHALL NOT be able to:
- Manually adjust student XP (not in scope)
- View individual student spreadsheets (privacy)
- Modify student completion records directly
- Access student login credentials

#### 3.10.3 UI/UX Requirements

**Admin Panel Structure:**

```
Admin Panel
├── Dashboard (analytics overview)
├── Content Management
│   ├── Courses
│   ├── Units
│   ├── Lessons
│   └── Exercises
├── Template Management
│   └── Spreadsheet Templates
└── Reports
    ├── Course Analytics
    ├── Student Progress
    └── System Health
```

---

## 4. External Interface Requirements

### 4.1 User Interfaces

#### 4.1.1 General UI Requirements

**UIR-001:** The application SHALL use responsive design
- Adapts to screen sizes 1024px and above
- Mobile-friendly layout (tablet and desktop)
- Touch-friendly interface elements

**UIR-002:** The application SHALL follow Material Design principles
- Consistent with Flutter Material widgets
- Clear visual hierarchy
- Intuitive navigation patterns

**UIR-003:** The application SHALL use consistent branding
- Defined color palette
- Typography standards
- Logo and imagery guidelines

**UIR-004:** The application SHALL provide loading indicators
- Spinner or progress bar during async operations
- Skeleton screens for initial page loads
- Disable buttons during processing

**UIR-005:** The application SHALL display error messages clearly
- User-friendly error messages
- Specific guidance on how to resolve errors
- Non-blocking error notifications

#### 4.1.2 Screen Specifications

**Authentication Screens:**
- Login page with email/password form
- Google OAuth button
- "Forgot password" link
- Registration page with email/password/name fields
- Password strength indicator

**Dashboard Screen:**
- Metrics cards (XP, completions)
- Expandable course progress tree
- Course catalog call-to-action
- User profile summary

**Course Catalog Screen:**
- Grid or list of course cards
- Search/filter functionality (future)

**Lesson Screen:**
- Lesson content area (text, video)
- Embedded YouTube player
- Exercise instructions
- Embedded Google Sheets (WebView)
- Action buttons (Start, Submit, Reset)

**Admin Panel:**
- Content management forms (CRUD)
- Analytics dashboards
- Template management interface

### 4.2 Hardware Interfaces

**HIR-001:** The system SHALL support standard input devices
- Keyboard input for text entry
- Mouse/trackpad for navigation and spreadsheet interaction
- Touch input for tablet devices

**HIR-002:** The system SHALL support standard display resolutions
- Minimum: 1024x768
- Optimal: 1920x1080 and above
- Support for high-DPI displays

### 4.3 Software Interfaces

#### 4.3.1 Supabase Integration

**SWI-001:** The system SHALL integrate with Supabase Auth
- Authentication API for login/logout
- OAuth 2.0 integration
- Session management
- User management API

**SWI-002:** The system SHALL integrate with Supabase Database
- PostgreSQL database access via Supabase client
- Real-time subscriptions for live updates (optional)
- RESTful API for CRUD operations
- Row Level Security enforcement

**SWI-003:** The system SHALL integrate with Supabase Storage (future)
- File upload for profile photos
- File storage for course materials

#### 4.3.2 Google APIs Integration

**SWI-004:** The system SHALL integrate with Google Sheets API v4
- Read spreadsheet data
- Write spreadsheet data
- Format cells and ranges
- Manage sheets within spreadsheets

**SWI-005:** The system SHALL integrate with Google Drive API v3
- Copy files (spreadsheet templates)
- Manage file permissions
- Delete files
- List files and folders

**SWI-006:** The system SHALL integrate with Google Apps Script
- Execute validation scripts
- Receive validation results
- Call custom functions
- Deploy as web app endpoints

**SWI-007:** The system SHALL integrate with YouTube Embed API
- Embed videos in lesson pages
- Player controls
- Responsive sizing

#### 4.3.3 Authentication Flow

**SWI-008:** Google OAuth flow:
1. User clicks "Sign in with Google"
2. Redirect to Google OAuth consent screen
3. User authorizes application
4. Google redirects back with authorization code
5. Supabase exchanges code for tokens
6. User session established
7. Redirect to dashboard

### 4.4 Communication Interfaces

**CI-001:** The system SHALL use HTTPS for all communications
- TLS 1.2 or higher
- Valid SSL certificates
- Encrypted data transmission

**CI-002:** The system SHALL communicate with Supabase via REST API
- JSON data format
- Standard HTTP methods (GET, POST, PUT, DELETE)
- API rate limiting compliance

**CI-003:** The system SHALL communicate with Google APIs via REST
- JSON data format
- OAuth 2.0 authentication
- API quota management

**CI-004:** The system SHALL handle network failures gracefully
- Retry logic for transient failures
- Offline detection and messaging
- Request timeout handling (30 seconds max)

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements

**NFR-PERF-001:** The system SHALL support 500 concurrent users
- No degradation in performance
- Response times maintained under load

**NFR-PERF-002:** Page load times SHALL be optimized
- Dashboard: < 2 seconds
- Course pages: < 1.5 seconds
- Lesson pages (without spreadsheet): < 2 seconds
- Spreadsheet embed: < 5 seconds

**NFR-PERF-003:** Database queries SHALL be optimized
- Complex queries < 500ms
- Simple queries < 100ms
- Proper indexing on foreign keys
- Query result caching where appropriate

**NFR-PERF-004:** API calls SHALL be rate-limited appropriately
- Google Sheets API: 100 requests per 100 seconds per user
- Supabase: Within free tier limits (50,000 rows, 500MB storage)
- Implement exponential backoff for retries

**NFR-PERF-005:** Assets SHALL be optimized
- Images compressed and served in modern formats (WebP)
- Code minification and bundling
- Lazy loading for non-critical resources
- CDN usage for static assets (if applicable)

### 5.2 Safety and Security Requirements

**NFR-SEC-001:** Authentication SHALL be secure
- Passwords hashed using bcrypt (Supabase default)
- OAuth tokens stored securely (Supabase handles)
- Session tokens have limited lifetime (7 days)
- HTTPS required for all authentication flows

**NFR-SEC-002:** Data access SHALL be restricted
- Row Level Security enforced on all tables
- Students access only their own data
- Admin access properly scoped
- No SQL injection vulnerabilities

**NFR-SEC-003:** API keys SHALL be protected
- Service account keys stored securely (environment variables)
- No keys in source code
- Keys rotated periodically
- Separate keys for dev/staging/production

**NFR-SEC-004:** User data SHALL be protected
- GDPR compliance considerations (future)
- Data encryption at rest (Supabase default)
- Data encryption in transit (HTTPS)
- Regular security audits (recommended)

**NFR-SEC-005:** Spreadsheets SHALL be private
- Each student's spreadsheet accessible only by that student
- No public sharing links
- Service account access for validation only
- Spreadsheet cleanup for old/abandoned files

**NFR-SEC-006:** The system SHALL prevent common attacks
- XSS (Cross-Site Scripting) protection
- CSRF (Cross-Site Request Forgery) tokens
- SQL injection prevention (parameterized queries)
- Rate limiting on authentication endpoints

### 5.3 Reliability and Availability

**NFR-REL-001:** The system SHALL have high availability
- Target uptime: 99% (allows ~7 hours downtime/month)
- Supabase infrastructure reliability
- Graceful degradation when services unavailable

**NFR-REL-002:** The system SHALL handle errors gracefully
- User-friendly error messages
- Automatic error logging
- Recovery suggestions provided
- No unhandled exceptions exposed to users

**NFR-REL-003:** The system SHALL backup data regularly
- Supabase automated backups (daily)
- Backup retention: 30 days minimum
- Point-in-time recovery capability
- Backup testing procedures

**NFR-REL-004:** The system SHALL recover from failures
- Database connection retry logic
- API call retry with exponential backoff
- Transaction rollback on errors
- State recovery after crashes

### 5.4 Scalability

**NFR-SCALE-001:** The system SHALL scale to support growth
- Initial: 200 users (first cohort)
- Target: 500 concurrent users
- Future: 2,000+ total users
- Architecture supports horizontal scaling

**NFR-SCALE-002:** Database design SHALL support growth
- Efficient schema design
- Proper indexing strategy
- Partitioning strategy for large tables (future)
- Archive strategy for old data

**NFR-SCALE-003:** The system SHALL monitor resource usage
- Database storage monitoring
- API quota tracking
- Performance metrics collection
- Alerts for threshold breaches

### 5.5 Maintainability

**NFR-MAINT-001:** Code SHALL be maintainable
- Clear code structure and organization
- Comprehensive inline comments
- Consistent naming conventions
- Modular architecture (separation of concerns)

**NFR-MAINT-002:** The system SHALL be documented
- API documentation
- Database schema documentation
- Deployment procedures
- Troubleshooting guides

**NFR-MAINT-003:** The system SHALL use version control
- Git repository on GitHub
- Meaningful commit messages
- Branch strategy (main, develop, feature branches)
- Pull request reviews (self-review for solo dev)

**NFR-MAINT-004:** The system SHALL support easy updates
- Environment-based configuration
- Feature flags for gradual rollouts
- Database migration scripts
- Rollback procedures

### 5.6 Usability

**NFR-USE-001:** The system SHALL be intuitive
- Clear navigation
- Consistent UI patterns
- Minimal learning curve
- Contextual help available

**NFR-USE-002:** The system SHALL provide feedback
- Confirmation messages for actions
- Progress indicators during operations
- Success/error notifications
- Clear status indicators

**NFR-USE-003:** The system SHALL be accessible
- Keyboard navigation support
- Sufficient color contrast (WCAG 2.1 AA)
- Alt text for images
- Screen reader compatibility (future enhancement)

**NFR-USE-004:** The system SHALL handle user errors gracefully
- Input validation with helpful messages
- Undo capability where appropriate (future)
- Confirmation for destructive actions
- Auto-save for user work (where applicable)

### 5.7 Compatibility

**NFR-COMPAT-001:** The system SHALL support modern browsers
- Chrome 90+ (primary target)
- Firefox 88+
- Safari 14+
- Edge 90+

**NFR-COMPAT-002:** The system SHALL work across operating systems
- Windows 10+
- macOS 10.15+
- Linux (Ubuntu 20.04+)
- iOS 14+ (tablet browsers)
- Android 10+ (tablet browsers)

**NFR-COMPAT-003:** The system SHALL support different screen sizes
- Desktop: 1920x1080, 1366x768, 1280x720
- Tablet: 1024x768, 768x1024
- Mobile web support limited (future enhancement)

---

## 6. Technical Architecture

### 6.1 System Architecture Overview

**Architecture Pattern:** Client-Server with Serverless Backend

```
┌─────────────────────────────────────────────────────────┐
│                     Client Layer                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Flutter Web Application (Dart)            │  │
│  │  - UI Components (Material Design)                │  │
│  │  - State Management (Provider/Riverpod/Bloc)      │  │
│  │  - Routing (go_router)                            │  │
│  │  - HTTP Client (dio/http)                         │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                  Backend Services Layer                 │
│  ┌──────────────────────┐  ┌─────────────────────────┐  │
│  │   Supabase Stack     │  │    Google Cloud APIs    │  │
│  │  - Auth              │  │  - Sheets API v4        │  │
│  │  - PostgreSQL DB     │  │  - Drive API v3         │  │
│  │  - REST API          │  │  - Apps Script          │  │
│  │  - Row Level Sec.    │  │  - YouTube Embed        │  │
│  └──────────────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                          │
│  ┌─────────────────────┐  ┌─────────────────────────┐   │
│  │  Supabase Postgres  │  │    Google Drive         │   │
│  │  - User data        │  │  - Spreadsheet files    │   │
│  │  - Course data      │  │  - Templates            │   │
│  │  - Progress data    │  │  - User copies          │   │
│  └─────────────────────┘  └─────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Technology Stack

**Frontend:**
- Framework: Flutter Web (latest stable)
- Language: Dart 3.x
- State Management: TBD (Provider, Riverpod, or Bloc)
- Routing: go_router package
- HTTP Client: dio or http package
- Local Storage: shared_preferences (for caching)

**Backend:**
- BaaS: Supabase (PostgreSQL, Auth, Storage)
- Database: PostgreSQL 14+ (via Supabase)
- Authentication: Supabase Auth + Google OAuth
- APIs: Google Sheets API v4, Google Drive API v3
- Validation: Google Apps Script

**Development Tools:**
- IDE: Visual Studio Code or Android Studio
- Version Control: Git + GitHub
- Hosting: GitHub Pages (Flutter web build)
- Package Manager: pub (Dart/Flutter)

**Third-Party Services:**
- Supabase (backend)
- Google Cloud Platform (APIs)
- YouTube (video hosting)

### 6.3 Data Model

**Core Entities and Relationships:**

```
auth.users (Supabase managed)
  ↓ 1:1
public.profiles
  ↓ 1:1
public.user_xp
  ↓ 1:many
public.xp_transactions

public.courses
  ↓ 1:many
public.units
  ↓ 1:many  
public.lessons
  ↓ 1:1
public.exercises
  ↓ 1:many
public.sections
  ↓ 1:many
public.validation_rules

public.sections
  ↓ many:many
public.user_progress (tracks completion)
  
public.sections  
  ↓ 1:many
public.user_spreadsheets (stores copies)

public.units (premium)
  ↓ many:many
public.unit_unlocks (user purchases)
```

**Key Database Indexes:**

```sql
-- Frequently queried foreign keys
CREATE INDEX idx_units_course_id ON public.units(course_id);
CREATE INDEX idx_lessons_unit_id ON public.lessons(unit_id);
CREATE INDEX idx_exercises_lesson_id ON public.exercises(lesson_id);
CREATE INDEX idx_sections_exercise_id ON public.sections(exercise_id);
CREATE INDEX idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX idx_user_progress_section_id ON public.user_progress(section_id);
CREATE INDEX idx_user_spreadsheets_user_id ON public.user_spreadsheets(user_id);
CREATE INDEX idx_unit_unlocks_user_id ON public.unit_unlocks(user_id);

-- Composite indexes for common queries
CREATE INDEX idx_user_progress_user_section ON public.user_progress(user_id, section_id);
CREATE INDEX idx_user_spreadsheets_user_section ON public.user_spreadsheets(user_id, section_id);
```

### 6.4 API Specifications

#### 6.4.1 Supabase Client Initialization

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

final supabase = Supabase.instance.client;
```

#### 6.4.2 Google Sheets API Client Initialization

```dart
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

final accountCredentials = ServiceAccountCredentials.fromJson(
  serviceAccountJson,
);

final scopes = [
  SheetsApi.spreadsheetsScope,
  DriveApi.driveFileScope,
];

final authClient = await clientViaServiceAccount(
  accountCredentials,
  scopes,
);

final sheetsApi = SheetsApi(authClient);
final driveApi = DriveApi(authClient);
```

#### 6.4.3 Key API Endpoints

**Supabase REST API (auto-generated):**

- `POST /auth/v1/signup` - User registration
- `POST /auth/v1/token?grant_type=password` - Email/password login
- `POST /auth/v1/logout` - User logout
- `GET /rest/v1/courses` - List courses
- `GET /rest/v1/user_progress?user_id=eq.{id}` - User progress
- `POST /rest/v1/user_spreadsheets` - Create spreadsheet record
- `POST /rest/v1/unit_unlocks` - Unlock premium unit

**Google Sheets API:**

- `POST /v4/spreadsheets/{spreadsheetId}:batchUpdate` - Update spreadsheet
- `GET /v4/spreadsheets/{spreadsheetId}` - Get spreadsheet metadata
- `GET /v4/spreadsheets/{spreadsheetId}/values/{range}` - Get cell values

**Google Drive API:**

- `POST /v3/files/{fileId}/copy` - Copy template spreadsheet
- `DELETE /v3/files/{fileId}` - Delete spreadsheet
- `PATCH /v3/files/{fileId}/permissions` - Manage permissions

**Google Apps Script (custom endpoints):**

- `POST {scriptUrl}?action=validate` - Validate exercise

### 6.5 Security Architecture

**Authentication Flow:**
1. User authenticates via Supabase Auth
2. Supabase issues JWT access token
3. Token included in all API requests (Authorization header)
4. Supabase validates token and enforces RLS policies
5. Application uses `auth.uid()` in RLS policies to identify user

**Data Access Control:**
- Row Level Security enforced on all tables
- Students can only access their own records
- RLS policies use `auth.uid()` to match user_id
- Admin role checked via email comparison in policies

**Spreadsheet Access Control:**
- Service account has Editor access to all spreadsheets
- Individual student spreadsheets shared only with that student's Google account
- Permission verification before displaying embedded sheets
- Spreadsheet URLs not exposed in public APIs

**API Key Security:**
- Service account JSON stored as environment variable
- Supabase keys (URL, anon key) in environment config
- No keys committed to source control
- `.env` file for local development
- GitHub Secrets for production deployment

---

## 7. Development Phases and Milestones

### Phase 1: Foundation (Completed)
- ✅ Flutter web project setup
- ✅ Supabase authentication implementation
- ✅ Email/password login
- ✅ Google OAuth integration
- ✅ Basic navigation structure (home, elasticity test pages)

### Phase 2: Data Model and User Management (Weeks 1-2)

#### Core Database Tasks (COMPLETED)

- ✅ Define and create Supabase database schema
  - ✅ 12 core tables with proper relationships
  - ✅ Foreign key constraints and integrity
  - ✅ Column definitions and data types
  - ✅ Exported to `supabase/migrations/20231123_initial_schema.sql`

- ✅ Implement Row Level Security policies
  - ✅ RLS enabled on all 12 tables
  - ✅ Student access control policies implemented
  - ✅ Authorization enforced at database level
  - ✅ Privacy protections for user data

- ✅ Create user profiles table and trigger
  - ✅ `public.profiles` table with complete schema
  - ✅ `on_auth_user_created` trigger for automatic profile creation
  - ✅ Trigger verified and tested with user signup
  - ✅ Auto-population of user data on registration

- ✅ Implement XP tracking tables
  - ✅ `public.user_xp` table (balance tracking)
  - ✅ `public.xp_transactions` table (audit log)
  - ✅ `public.unit_unlocks` table (premium access)
  - ✅ `public.user_progress` table (completion tracking)

- ✅ Create course/unit/lesson/exercise/section tables
  - ✅ `public.courses` table (5 courses)
  - ✅ `public.units` table (content organization)
  - ✅ `public.lessons` table (lesson content)
  - ✅ `public.exercises` table (exercise definitions)
  - ✅ `public.sections` table (spreadsheet templates)
  - ✅ `public.validation_rules` table (answer validation)

#### Seed Data Tasks (PARTIAL - 5 courses seeded, units/lessons pending)

- [~] Seed initial course data (5 courses structure)
  - ✅ 5 courses created and seeded:
    - ✅ Microeconomics
    - ✅ Macroeconomics
    - ✅ Statistics
    - ✅ Mathematics
    - ✅ Finance
  - ✅ Course data backed up to `supabase/seed.sql`
  - [ ] ~50 units to be created (in Week 2)
  - [ ] ~150 lessons to be created (in Week 2)
  - [ ] ~150 exercises to be created (in Week 2)
  - [ ] ~200-300 sections to be created (in Week 2)
  - [ ] Validation rules for each section (in Week 2)

#### Database Infrastructure and Version Control (NEW SECTION)

- ✅ Export database schema from Supabase
  - ✅ Complete schema dump generated
  - ✅ All 12 tables with relationships included
  - ✅ RLS policies exported
  - ✅ Triggers exported
  - ✅ Indexes exported

- ✅ Create migration file for version control
  - ✅ `supabase/migrations/20231123_initial_schema.sql` created (60 KB)
  - ✅ Contains complete database structure
  - ✅ Ready for production deployment
  - ✅ Enables database recreation on new environments

- ✅ Commit schema to GitHub repository
  - ✅ Migration file added to Git
  - ✅ Committed with descriptive message
  - ✅ Pushed to origin/main
  - ✅ Now part of version control

- ✅ Create seed file for courses data
  - ✅ `supabase/seed.sql` created
  - ✅ Contains 5 course INSERT statements
  - ✅ Preserves course IDs, timestamps, descriptions
  - ✅ Excludes user data (privacy protection)

- ✅ Commit seed data to GitHub repository
  - ✅ Seed file added to Git
  - ✅ Committed with descriptive message
  - ✅ Pushed to origin/main
  - ✅ Reproducible content initialization

- ✅ Update .gitignore to protect sensitive data
  - ✅ Added rule: `supabase/seed_users.sql` (prevent user data commits)
  - ✅ Added rule: `supabase/seed_production.sql` (prevent production data commits)
  - ✅ Added rule: `*.sql.backup` (prevent backup file commits)
  - ✅ Added rules for sensitive keys and files
  - ✅ Protects public repository from exposing sensitive information

- ✅ Commit .gitignore update to GitHub repository
  - ✅ Updated .gitignore added to Git
  - ✅ Committed with descriptive message
  - ✅ Pushed to origin/main
  - ✅ Security rules now active for future commits

### Phase 3: Google Sheets Integration (Weeks 3-4)
- [ ] Setup Google Cloud Project and APIs
- [ ] Create service account and configure permissions
- [ ] Implement spreadsheet template management
- [ ] Develop spreadsheet copy functionality (just-in-time)
- [ ] Implement spreadsheet embedding in lesson pages
- [ ] Create reset functionality
- [ ] Implement spreadsheet retention policy

### Phase 4: Exercise Validation System (Weeks 5-7)
- [ ] Design validation rules data structure
- [ ] Create Google Apps Script validation functions
  - [ ] Cell value validation
  - [ ] Formula validation  
  - [ ] Calculated result validation
  - [ ] Chart validation (all properties)
- [ ] Implement validation API endpoints (Apps Script web app)
- [ ] Create validation UI in Flutter app
- [ ] Implement "Submit Answer" functionality
- [ ] Develop XP award system
- [ ] Implement completion tracking

### Phase 5: Student Dashboard and Progress (Weeks 8-9)
- [ ] Design dashboard UI/UX
- [ ] Implement dashboard data fetching
- [ ] Create expandable progress tree
- [ ] Display XP balance and metrics
- [ ] Implement course catalog page
- [ ] Implement "My Library" page
- [ ] Create lesson detail pages with embedded content

### Phase 6: Premium Content and XP System (Week 10)
- [ ] Implement unit unlock UI
- [ ] Create XP transaction system
- [ ] Develop unlock purchase flow
- [ ] Add XP requirement indicators
- [ ] Test premium content access control

### Phase 7: Public Profiles (Week 11)
- [ ] Create profile visibility toggle
- [ ] Implement public profile page
- [ ] Design public profile layout
- [ ] Implement privacy controls
- [ ] Test public profile sharing

### Phase 8: Administrator Panel (Weeks 12-13)
- [ ] Design admin panel UI
- [ ] Implement course management CRUD
- [ ] Implement unit/lesson/exercise management
- [ ] Create template management interface
- [ ] Develop analytics dashboards
- [ ] Implement progress reports
- [ ] Create export functionality (CSV)

### Phase 9: Testing and Refinement (Weeks 14-15)
- [ ] Unit testing for critical functions
- [ ] Integration testing for API interactions
- [ ] User acceptance testing with students
- [ ] Performance testing (500 concurrent users)
- [ ] Security testing
- [ ] Bug fixes and refinements
- [ ] Documentation updates

### Phase 10: Deployment and Launch (Week 16)
- [ ] Production environment setup
- [ ] Database migration to production
- [ ] Deploy Flutter web app to GitHub Pages
- [ ] Configure production API keys
- [ ] Final security audit
- [ ] Create user documentation
- [ ] Launch to first cohort (200 students)
- [ ] Monitoring and support setup

---

## 8. Testing Requirements

### 8.1 Unit Testing

**UT-001:** Authentication functions
- Login with valid credentials
- Login with invalid credentials
- OAuth flow simulation
- Logout functionality
- Session persistence

**UT-002:** Database operations
- CRUD operations for all entities
- RLS policy enforcement
- Foreign key constraints
- Unique constraints
- Data validation

**UT-003:** XP calculations
- XP earning on section completion
- XP deduction on unlock
- Balance calculations
- Transaction logging

**UT-004:** Progress tracking
- Completion status updates
- Percentage calculations
- Aggregate progress queries

### 8.2 Integration Testing

**IT-001:** Supabase integration
- Authentication flow end-to-end
- Database queries with RLS
- Real-time subscriptions (if used)
- Error handling

**IT-002:** Google Sheets API integration
- Spreadsheet copy creation
- Permission management
- Data reading/writing
- Spreadsheet deletion

**IT-003:** Apps Script validation
- Validation function execution
- Result parsing
- Error handling
- Timeout scenarios

**IT-004:** YouTube embed
- Video loading
- Player controls
- Responsive sizing

### 8.3 User Acceptance Testing

**UAT-001:** Student workflows
- Registration and login
- Course browsing
- Starting a lesson
- Completing an exercise
- Earning and spending XP
- Tracking progress on dashboard

**UAT-002:** Administrator workflows
- Creating course content
- Managing templates
- Viewing analytics
- Exporting reports

### 8.4 Performance Testing

**PT-001:** Load testing
- 500 concurrent users
- Response time under load
- Database performance
- API rate limiting

**PT-002:** Stress testing
- Peak load scenarios (all 200 students online)
- Database connection limits
- API quota exhaustion

### 8.5 Security Testing

**ST-001:** Authentication testing
- Brute force protection
- Session hijacking prevention
- Token validation
- OAuth security

**ST-002:** Authorization testing
- RLS bypass attempts
- Unauthorized data access
- Admin privilege escalation

**ST-003:** Input validation
- SQL injection attempts
- XSS attempts
- Malicious file uploads

---

## 9. Deployment Strategy

### 9.1 Development Environment

**Setup:**
- Local Flutter development (VS Code or Android Studio)
- Supabase project (development instance)
- Google Cloud Project (development)
- Git repository on GitHub

**Configuration:**
- Environment variables in `.env` file
- Development API keys
- Test data seeding scripts

### 9.2 Staging Environment (Optional)

**Setup:**
- Separate Supabase project (staging)
- Separate Google Cloud project (staging)
- Staging branch in Git
- Test user accounts

### 9.3 Production Environment

**Hosting:**
- Flutter web app on GitHub Pages
- Custom domain (optional): economicskills.com
- HTTPS enforced

**Backend:**
- Supabase production project
- Production database
- Production API keys (rotated)
- Monitoring and alerts enabled

**Deployment Process:**
1. Build Flutter web app: `flutter build web --release`
2. Deploy to GitHub Pages (gh-pages branch)
3. Run database migrations on production Supabase
4. Update environment variables
5. Smoke test critical flows
6. Monitor for errors

### 9.4 Rollback Plan

**If issues detected:**
1. Revert to previous git commit
2. Rebuild and redeploy Flutter app
3. Rollback database migrations if needed
4. Communicate with users about downtime

### 9.5 Monitoring and Maintenance

**Monitoring:**
- Supabase dashboard for database health
- Google Cloud Console for API quotas
- Application error logging (Sentry or similar)
- User feedback collection

**Maintenance:**
- Weekly database backups verification
- Monthly spreadsheet cleanup job
- Quarterly dependency updates
- Security patch application

---

## 10. Constraints and Limitations

### 10.1 Technical Constraints

**TC-001:** Flutter web limitations
- Limited mobile web support in v1.0
- Performance on older browsers
- Large bundle size considerations

**TC-002:** Supabase free tier limits (as of October 2025)
- 500MB database storage
- 50,000 monthly active users
- 2GB egress bandwidth
- 500MB file storage

**TC-003:** Google API quotas
- Sheets API: 500 requests per 100 seconds per user
- Drive API: 1,000 requests per 100 seconds per user
- Apps Script execution time: 6 minutes max
- Apps Script trigger quotas

**TC-004:** Browser compatibility
- Older browsers (IE11) not supported
- WebView limitations in embedded sheets
- Popup blocker interference with OAuth

### 10.2 Functional Limitations

**FL-001:** Initial release exclusions (future features)
- Profile editing after signup
- Password change functionality
- Mobile iOS/Android apps
- R and Python interactive exercises
- "Show Answer" button
- Multi-language support (Spanish, French, etc.)
- Marketing and Accounting courses
- Email verification

**FL-002:** Spreadsheet limitations
- No collaborative editing (individual copies only)
- Limited to Google Sheets capabilities
- Validation requires specific structure
- No support for complex macros in templates

**FL-003:** Admin panel limitations
- Single administrator only
- No role-based access control (RBAC)
- Manual content creation (no CMS)
- Limited bulk operations

### 10.3 Business Constraints

**BC-001:** Development resources
- Solo developer (instructor)
- Limited development time
- No dedicated QA team
- No dedicated designer

**BC-002:** Budget constraints
- Free tier services preferred
- Minimal third-party costs
- No paid marketing

**BC-003:** Timeline constraints
- 16-week development timeline
- Launch aligned with academic semester
- Iterative releases preferred

---

## 11. Assumptions

**A-001:** Students have reliable internet access during course work

**A-002:** Students use devices with minimum 1024x768 screen resolution

**A-003:** Students are familiar with basic spreadsheet concepts

**A-004:** YouTube is accessible to all users (not blocked)

**A-005:** Google Sheets service remains stable and available

**A-006:** Supabase free tier is sufficient for initial cohort (200 users)

**A-007:** Students will complete exercises honestly (honor system)

**A-008:** Administrator will maintain templates and content quality

**A-009:** Course content (text, videos) is accurate and ready

**A-010:** Institution provides support for students with technical issues

---

## 12. Dependencies

**D-001:** Supabase platform availability and stability

**D-002:** Google Cloud Platform API availability

**D-003:** Google Sheets and Drive API continued support

**D-004:** YouTube platform for video hosting

**D-005:** Flutter web framework stability and updates

**D-006:** GitHub Pages hosting availability

**D-007:** Modern web browser support for Flutter web

**D-008:** Academic calendar alignment for launch timing

---

## 13. Glossary

**Administrator:** The sole instructor and developer with elevated system permissions

**Apps Script:** Google's JavaScript-based scripting platform for automating Google Workspace

**Course:** Top-level content container (e.g., Microeconomics)

**Exercise:** A set of tasks within a lesson, composed of 1-3 sections

**Just-in-Time (JIT):** Creating resources (spreadsheet copies) only when needed, not in advance

**Lesson:** A learning unit within a unit, containing content and one exercise

**Premium Unit:** A unit that requires XP to unlock

**RLS (Row Level Security):** PostgreSQL feature that restricts data access at the row level

**Section:** A single spreadsheet within an exercise, worth 10 XP upon completion

**Service Account:** Google Cloud credential for server-to-server API access

**Student:** Primary user type who completes courses and exercises

**Supabase:** Open-source Firebase alternative providing backend services

**Template:** Master spreadsheet used to create student copies

**Unit:** Collection of lessons within a course

**WebView:** Widget that embeds web content (Google Sheets) in Flutter app

**XP (Experience Points):** Gamification currency earned by completing sections

---

## 14. Appendices

### Appendix A: Database Schema SQL

Complete SQL scripts for creating all database tables, indexes, RLS policies, and triggers are documented separately in the technical documentation. See `database-schema.sql` for the complete implementation.

### Appendix B: Google Apps Script Templates

Sample Apps Script validation functions are provided in the developer documentation. See `apps-script-templates.js` for examples of cell value, formula, and chart validation logic.

### Appendix C: API Integration Examples

Code examples for integrating Supabase and Google APIs in Flutter are provided in the developer guide. See `api-integration-examples.dart`.

### Appendix D: Screen Mockups

UI/UX mockups for key screens (dashboard, lesson page, admin panel) are available in the design documentation folder.

### Appendix E: User Stories

Detailed user stories for student and administrator workflows are documented separately for agile development tracking.

### Appendix F: Change Log

| Version | Date         | Changes                | Author        |
|---------|--------------|------------------------|---------------|
| 0.1     | Oct 31, 2025 | Initial draft          | Administrator |
| 1.0     | TBD          | Final approved version | Administrator |

---

## 15. Approval

**Document Prepared By:**  
Juan Pablo Barrera Castrp  
Student/Developer  
Acatlán School of Higher Studies

**Document Approved By:**  
[Approver Name]  
[Title]  
[Date]

**Next Review Date:** [Date]

---

*End of Software Requirements Specification*