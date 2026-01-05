# Google Cloud Project Setup Guide

This guide walks you through setting up Google Cloud services for EconomicSkills Google Sheets integration.

---

## Step 1: Create a Google Cloud Project

### 1.1 Go to Google Cloud Console
1. Open your browser and go to: **https://console.cloud.google.com/**
2. Sign in with your Google account

### 1.2 Create New Project
1. Click the **project dropdown** at the top left (next to "Google Cloud")
2. In the dialog, click **"New Project"** (top right)
3. Enter:
   - **Project name**: `EconomicSkills`
   - **Organization**: Leave as default
   - **Location**: Leave as default
4. Click **"Create"**
5. Wait for the notification that the project was created
6. Click the notification or use the dropdown to **select your new project**

---

## Step 2: Enable Required APIs

### 2.1 Enable Google Sheets API
1. In the Cloud Console, click the hamburger menu (☰) → **"APIs & Services"** → **"Library"**
2. In the search bar, type: **Google Sheets API**
3. Click on **"Google Sheets API"** in the results
4. Click the blue **"Enable"** button
5. Wait for it to enable (you'll see a checkmark)

### 2.2 Enable Google Drive API
1. Click **"← APIs & Services"** to go back to the library
2. Search for: **Google Drive API**
3. Click on **"Google Drive API"**
4. Click **"Enable"**

---

## Step 3: Create a Service Account

### 3.1 Navigate to Credentials
1. In Cloud Console, go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ Create Credentials"** at the top
3. Select **"Service account"**

### 3.2 Service Account Details
1. **Service account name**: `economicskills-sheets`
2. **Service account ID**: (auto-filled, e.g., `economicskills-sheets`)
3. **Description**: `Service account for EconomicSkills spreadsheet operations`
4. Click **"Create and Continue"**

### 3.3 Grant Permissions
1. Click **"Select a role"**
2. Search for and select: **"Editor"** (under "Project")
3. Click **"Continue"**
4. Skip the "Grant users access" step → Click **"Done"**

---

## Step 4: Generate Service Account Key

### 4.1 Download JSON Key
1. In the **Credentials** page, find your service account under "Service Accounts"
2. Click on the **service account name** (the email address)
3. Go to the **"Keys"** tab
4. Click **"Add Key"** → **"Create new key"**
5. Select **"JSON"** format
6. Click **"Create"**
7. A JSON file downloads automatically - **SAVE THIS SECURELY!**

### 4.2 Key File Contents
Your downloaded JSON file will look like:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "economicskills-sheets@your-project.iam.gserviceaccount.com",
  "client_id": "...",
  ...
}
```

> ⚠️ **IMPORTANT**: Never commit this file to Git! Add it to `.gitignore`.

---

## Step 5: Share Your Spreadsheets

For each template spreadsheet:

1. Open the spreadsheet in Google Sheets
2. Click **"Share"** button (top right)
3. In "Add people and groups", paste your **service account email**:
   - Find in the JSON file under `client_email`
   - Looks like: `economicskills-sheets@your-project.iam.gserviceaccount.com`
4. Set permission to **"Editor"**
5. **Uncheck** "Notify people"
6. Click **"Share"**

### Spreadsheets to Share:
- Template: `https://docs.google.com/spreadsheets/d/1PurIyjOPS3G2mHNTcx1GGZgycTzyiIR6tvNfp4a5cUg/edit`
- Solution: `https://docs.google.com/spreadsheets/d/19y_MmAzGWimBGZ_TFiRvsPMRoTTYZ7r1p2vbSJl7S1s/edit`

---

## Step 6: Configure Supabase Secrets

### 6.1 Using Supabase CLI

From your project directory, run:

```bash
# Set the service account email
supabase secrets set GOOGLE_SERVICE_ACCOUNT_EMAIL="economicskills-sheets@your-project.iam.gserviceaccount.com"

# Set the private key (copy the entire key including -----BEGIN/END PRIVATE KEY-----)
supabase secrets set GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...your key here...
-----END PRIVATE KEY-----"

# Set the project ID
supabase secrets set GOOGLE_PROJECT_ID="your-project-id"
```

### 6.2 Using Supabase Dashboard

1. Go to: **https://app.supabase.com/**
2. Select your project
3. Go to **Settings** → **Edge Functions**
4. Under **Secrets**, add:

| Name | Value |
|------|-------|
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Your service account email |
| `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` | The full private key |
| `GOOGLE_PROJECT_ID` | Your Google Cloud project ID |

---

## Step 7: Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy copy-spreadsheet
supabase functions deploy validate-spreadsheet
supabase functions deploy delete-spreadsheet
```

---

## Step 8: Run Database Migration

Copy and run in Supabase SQL Editor:
- `supabase/migrations/20260104_edge_functions_tables.sql`

This creates the required tables:
- `user_spreadsheets`
- `user_progress`
- `xp_transactions`
- `validation_rules`

---

## Troubleshooting

### "The caller does not have permission"
- Ensure the spreadsheet is shared with the service account email
- Verify the service account has "Editor" permission

### "Google Sheets API has not been used in project"
- Enable the Google Sheets API in Cloud Console
- Wait a few minutes for changes to propagate

### "Invalid JWT"
- Check that the private key is correctly formatted with `\n` for newlines
- Verify the service account email matches the key file

---

## Summary Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google Sheets API
- [ ] Enabled Google Drive API
- [ ] Created Service Account with Editor role
- [ ] Downloaded JSON key file
- [ ] Shared template spreadsheets with service account
- [ ] Configured Supabase secrets
- [ ] Deployed Edge Functions
- [ ] Ran database migration
