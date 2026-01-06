// list-drive-files Edge Function
// Lists all files in the service account's Drive for debugging/cleanup

import {
    corsHeaders,
    handleCors,
    errorResponse,
    successResponse,
} from "../_shared/google-sheets.ts";

// Environment variables
const SERVICE_ACCOUNT_EMAIL = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL") || "";
const SERVICE_ACCOUNT_PRIVATE_KEY = (Deno.env.get("GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY") || "").replace(/\\n/g, "\n");
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GOOGLE_DRIVE_API = "https://www.googleapis.com/drive/v3/files";

async function createJWT(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const exp = now + 3600;

    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
        iss: SERVICE_ACCOUNT_EMAIL,
        scope: "https://www.googleapis.com/auth/drive",
        aud: GOOGLE_TOKEN_URL,
        iat: now,
        exp: exp,
    };

    const encoder = new TextEncoder();
    const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const signInput = `${headerB64}.${payloadB64}`;

    const pemContents = SERVICE_ACCOUNT_PRIVATE_KEY
        .replace("-----BEGIN PRIVATE KEY-----", "")
        .replace("-----END PRIVATE KEY-----", "")
        .replace(/\s/g, "");

    const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
    const cryptoKey = await crypto.subtle.importKey(
        "pkcs8", binaryKey,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false, ["sign"]
    );

    const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, encoder.encode(signInput));
    const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

    return `${signInput}.${signatureB64}`;
}

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
    const data = await response.json();
    return data.access_token;
}

Deno.serve(async (req) => {
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    try {
        const accessToken = await getAccessToken();
        const body = await req.json().catch(() => ({}));
        const { action } = body;

        if (action === "delete-all") {
            // Delete all files
            const listResponse = await fetch(
                `${GOOGLE_DRIVE_API}?pageSize=100&fields=files(id,name,mimeType,size,createdTime)`,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );
            const listData = await listResponse.json();
            const files = listData.files || [];

            let deleted = 0;
            for (const file of files) {
                await fetch(`${GOOGLE_DRIVE_API}/${file.id}`, {
                    method: "DELETE",
                    headers: { Authorization: `Bearer ${accessToken}` },
                });
                deleted++;
            }

            return successResponse({ message: `Deleted ${deleted} files`, deletedCount: deleted });
        }

        // List files
        const response = await fetch(
            `${GOOGLE_DRIVE_API}?pageSize=100&fields=files(id,name,mimeType,size,createdTime,owners)`,
            { headers: { Authorization: `Bearer ${accessToken}` } }
        );

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Failed to list files: ${error}`);
        }

        const data = await response.json();
        const files = data.files || [];

        // Calculate total size
        const totalSize = files.reduce((sum: number, f: any) => sum + (parseInt(f.size) || 0), 0);

        return successResponse({
            fileCount: files.length,
            totalSizeBytes: totalSize,
            totalSizeMB: (totalSize / 1024 / 1024).toFixed(2),
            files: files.map((f: any) => ({
                id: f.id,
                name: f.name,
                mimeType: f.mimeType,
                size: f.size,
                createdTime: f.createdTime,
            })),
        });

    } catch (error) {
        console.error("Error:", error);
        return errorResponse(`Internal error: ${error.message}`, 500);
    }
});
