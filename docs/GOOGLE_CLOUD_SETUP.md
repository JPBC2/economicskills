# Google Cloud Project Setup Guide

This guide walks you through setting up Google Cloud services for EconomicSkills Google Sheets integration.

## Prerequisites

- A Google account
- Access to the template spreadsheets you want to use

---

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)

2. Click the project dropdown at the top of the page (next to "Google Cloud")

3. Click **New Project** in the dialog that appears

4. Enter project details:
   - **Project name**: `EconomicSkills` (or your preferred name)
   - **Organization**: Leave as default or select your organization
   - **Location**: Leave as default

5. Click **Create**

6. Wait for the project to be created (you'll see a notification)

7. Select the new project from the dropdown

---

## Step 2: Enable Required APIs

### Enable Google Sheets API

1. In the Cloud Console, go to **APIs & Services** → **Library**

2. Search for "Google Sheets API"

3. Click on **Google Sheets API**

4. Click **Enable**

### Enable Google Drive API

1. Go back to **APIs & Services** → **Library**

2. Search for "Google Drive API"

3. Click on **Google Drive API**

4. Click **Enable**

---

## Step 3: Create a Service Account

1. Go to **APIs & Services** → **Credentials**

2. Click **Create Credentials** → **Service Account**

3. Enter service account details:
   - **Service account name**: `economicskills-sheets`
   - **Service account ID**: auto-filled (e.g., `economicskills-sheets`)
   - **Description**: `Service account for EconomicSkills Google Sheets operations`

4. Click **Create and Continue**

5. Grant this service account access to project:
   - Click **Select a role**
   - Choose **Editor** (or search for it)
   
   > **Note**: For production, you might want to create a custom role with only the necessary permissions (Drive and Sheets).

6. Click **Continue**

7. Skip the "Grant users access" step and click **Done**

---

## Step 4: Generate Service Account Key

1. In the **Credentials** page, find your new service account in the "Service Accounts" section

2. Click on the service account name to open its details

3. Go to the **Keys** tab

4. Click **Add Key** → **Create new key**

5. Select **JSON** format

6. Click **Create**

7. A JSON file will be downloaded automatically. **Save this file securely!**

   > ⚠️ **IMPORTANT**: This file contains sensitive credentials. Never commit it to Git or share it publicly.

---

## Step 5: Configure Supabase Secrets

The service account credentials need to be stored as Supabase secrets for the Edge Functions.

### Using Supabase Dashboard

1. Go to your [Supabase Dashboard](https://app.supabase.com/)

2. Select your project

3. Go to **Settings** → **Vault** (or **Project Settings** → **Secrets**)

4. Add the following secrets from your service account JSON file:

   | Secret Name | Value |
   |-------------|-------|
   | `GOOGLE_SERVICE_ACCOUNT_EMAIL` | The `client_email` from the JSON file |
   | `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` | The `private_key` from the JSON file |
   | `GOOGLE_PROJECT_ID` | The `project_id` from the JSON file |

### Using Supabase CLI

```bash
supabase secrets set GOOGLE_SERVICE_ACCOUNT_EMAIL="your-service-account@your-project.iam.gserviceaccount.com"
supabase secrets set GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
supabase secrets set GOOGLE_PROJECT_ID="your-project-id"
```

---

## Step 6: Share Template Spreadsheets

For each template spreadsheet you want to use:

1. Open the spreadsheet in Google Sheets

2. Click the **Share** button (top right)

3. In the "Add people and groups" field, paste your service account email:
   - Find this in your service account JSON file under `client_email`
   - It looks like: `economicskills-sheets@your-project.iam.gserviceaccount.com`

4. Set permission to **Editor**

5. Uncheck "Notify people"

6. Click **Share**

### For Your Specific Spreadsheet

Share the following spreadsheet with your service account:

- **Template**: `https://docs.google.com/spreadsheets/d/1PurIyjOPS3G2mHNTcx1GGZgycTzyiIR6tvNfp4a5cUg/edit`
- **Solution**: `https://docs.google.com/spreadsheets/d/19y_MmAzGWimBGZ_TFiRvsPMRoTTYZ7r1p2vbSJl7S1s/edit`

---

## Step 7: Verify Setup

### Test API Access

You can verify the setup by making a test API call. First, install the Google APIs client:

```bash
npm install googleapis
```

Create a test script (`test-sheets.js`):

```javascript
const { google } = require('googleapis');

const auth = new google.auth.GoogleAuth({
  keyFile: './path-to-your-service-account.json',
  scopes: [
    'https://www.googleapis.com/auth/spreadsheets.readonly',
    'https://www.googleapis.com/auth/drive.readonly',
  ],
});

async function testAccess() {
  const sheets = google.sheets({ version: 'v4', auth });
  
  try {
    const response = await sheets.spreadsheets.get({
      spreadsheetId: '1PurIyjOPS3G2mHNTcx1GGZgycTzyiIR6tvNfp4a5cUg',
    });
    console.log('✅ Successfully accessed spreadsheet:', response.data.properties.title);
  } catch (error) {
    console.error('❌ Error accessing spreadsheet:', error.message);
  }
}

testAccess();
```

Run the test:

```bash
node test-sheets.js
```

---

## Summary of Credentials

After completing this setup, you should have:

| Item | Description |
|------|-------------|
| **Google Cloud Project** | Project containing your APIs and service account |
| **Service Account Email** | Email address to share spreadsheets with |
| **Service Account JSON Key** | Credentials file for API authentication |
| **Supabase Secrets** | Service account credentials stored in Supabase |

---

## Troubleshooting

### "The caller does not have permission"

- Make sure the spreadsheet is shared with the service account email
- Verify the service account has the correct role (Editor)

### "Google Sheets API has not been used in project"

- Enable the Google Sheets API in the Cloud Console
- Wait a few minutes for the change to propagate

### "Request had insufficient authentication scopes"

- Ensure your authentication includes the correct scopes:
  - `https://www.googleapis.com/auth/spreadsheets`
  - `https://www.googleapis.com/auth/drive`

---

## Next Steps

After completing this setup:

1. Deploy the Supabase Edge Functions (see implementation plan)
2. Add your first content through the Admin CMS
3. Test the spreadsheet copy functionality
