// Shared Google Sheets API client for Supabase Edge Functions
// Uses service account authentication via JWT

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// Google API endpoints
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GOOGLE_SHEETS_API = "https://sheets.googleapis.com/v4/spreadsheets";
const GOOGLE_DRIVE_API = "https://www.googleapis.com/drive/v3/files";

// Environment variables (set via supabase secrets)
const SERVICE_ACCOUNT_EMAIL = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL") || "";
const SERVICE_ACCOUNT_PRIVATE_KEY = (Deno.env.get("GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY") || "").replace(/\\n/g, "\n");
const GOOGLE_PROJECT_ID = Deno.env.get("GOOGLE_PROJECT_ID") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

// Supabase client with service role for database operations
export const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Create a JWT for Google API authentication
 */
async function createJWT(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600; // 1 hour expiry

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const payload = {
    iss: SERVICE_ACCOUNT_EMAIL,
    scope: "https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive",
    aud: GOOGLE_TOKEN_URL,
    iat: now,
    exp: exp,
  };

  // Base64url encode
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signInput = `${headerB64}.${payloadB64}`;

  // Import the private key for signing
  const pemContents = SERVICE_ACCOUNT_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign the JWT
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signInput)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  return `${signInput}.${signatureB64}`;
}

/**
 * Get an access token from Google using service account JWT
 */
async function getAccessToken(): Promise<string> {
  const jwt = await createJWT();

  const response = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const data = await response.json();
  return data.access_token;
}

/**
 * Copy a spreadsheet using Google Drive API
 * Copies are stored in a shared folder to avoid service account storage limits
 */
export async function copySpreadsheet(
  templateId: string,
  newName: string
): Promise<{ spreadsheetId: string; spreadsheetUrl: string }> {
  const accessToken = await getAccessToken();

  // Shared folder ID for storing copies (owned by user, shared with service account)
  const COPIES_FOLDER_ID = "13IcsEazqRtcaddtQkkJ7c6g0BadRVOP0";

  // Copy the file into the shared folder
  const copyResponse = await fetch(`${GOOGLE_DRIVE_API}/${templateId}/copy`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      name: newName,
      parents: [COPIES_FOLDER_ID], // Store in shared folder
    }),
  });

  if (!copyResponse.ok) {
    const error = await copyResponse.text();
    throw new Error(`Failed to copy spreadsheet: ${error}`);
  }

  const copyData = await copyResponse.json();
  const spreadsheetId = copyData.id;

  // Set permissions to anyone with link can edit
  await fetch(`${GOOGLE_DRIVE_API}/${spreadsheetId}/permissions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      role: "writer",
      type: "anyone",
    }),
  });

  return {
    spreadsheetId,
    spreadsheetUrl: `https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`,
  };
}

/**
 * Read values from a spreadsheet range
 */
export async function readSpreadsheetRange(
  spreadsheetId: string,
  range: string
): Promise<string[][]> {
  const accessToken = await getAccessToken();

  const response = await fetch(
    `${GOOGLE_SHEETS_API}/${spreadsheetId}/values/${encodeURIComponent(range)}`,
    {
      headers: { Authorization: `Bearer ${accessToken}` },
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to read spreadsheet: ${error}`);
  }

  const data = await response.json();
  return data.values || [];
}

/**
 * Delete a spreadsheet using Google Drive API
 */
export async function deleteSpreadsheet(spreadsheetId: string): Promise<void> {
  const accessToken = await getAccessToken();

  const response = await fetch(`${GOOGLE_DRIVE_API}/${spreadsheetId}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok && response.status !== 404) {
    const error = await response.text();
    throw new Error(`Failed to delete spreadsheet: ${error}`);
  }
}

/**
 * Compare two values with tolerance for numbers
 */
export function compareValues(
  studentValue: string | number | undefined,
  solutionValue: string | number | undefined,
  tolerance: number = 0.01
): boolean {
  if (studentValue === undefined || solutionValue === undefined) {
    return studentValue === solutionValue;
  }

  // Try to parse as numbers
  const studentNum = parseFloat(String(studentValue));
  const solutionNum = parseFloat(String(solutionValue));

  if (!isNaN(studentNum) && !isNaN(solutionNum)) {
    // Compare numbers with tolerance
    return Math.abs(studentNum - solutionNum) <= tolerance * Math.abs(solutionNum);
  }

  // Compare as strings (case-insensitive, trimmed)
  return String(studentValue).trim().toLowerCase() === String(solutionValue).trim().toLowerCase();
}

/**
 * CORS headers for Edge Functions
 */
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/**
 * Handle CORS preflight requests
 */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}

/**
 * Create error response
 */
export function errorResponse(message: string, status: number = 400): Response {
  return new Response(
    JSON.stringify({ error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

/**
 * Create success response
 */
export function successResponse(data: unknown): Response {
  return new Response(
    JSON.stringify(data),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}
