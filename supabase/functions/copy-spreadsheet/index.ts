// copy-spreadsheet Edge Function
// Copies a template spreadsheet for a student using their OAuth token
// File is created in USER's Drive, then shared with service account for validation

import {
    deleteSpreadsheet,
    supabaseAdmin,
    corsHeaders,
    handleCors,
    errorResponse,
    successResponse,
} from "../_shared/google-sheets.ts";

const GOOGLE_DRIVE_API = "https://www.googleapis.com/drive/v3/files";
const SERVICE_ACCOUNT_EMAIL = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL") || "";

interface CopyRequest {
    template_id: string;
    section_id: string;
    user_id: string;
    new_name: string;
    user_access_token: string; // User's Google OAuth token
    fresh?: boolean;
}

/**
 * Copy spreadsheet using USER's access token (creates in their Drive)
 */
async function copySpreadsheetAsUser(
    templateId: string,
    newName: string,
    userAccessToken: string
): Promise<{ spreadsheetId: string; spreadsheetUrl: string }> {
    // Copy the template using user's token
    const copyResponse = await fetch(`${GOOGLE_DRIVE_API}/${templateId}/copy`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${userAccessToken}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            name: newName,
        }),
    });

    if (!copyResponse.ok) {
        const error = await copyResponse.text();
        throw new Error(`Failed to copy spreadsheet: ${error}`);
    }

    const copyData = await copyResponse.json();
    const spreadsheetId = copyData.id;

    // Share with service account so it can validate
    if (SERVICE_ACCOUNT_EMAIL) {
        await fetch(`${GOOGLE_DRIVE_API}/${spreadsheetId}/permissions`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${userAccessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                role: "reader",
                type: "user",
                emailAddress: SERVICE_ACCOUNT_EMAIL,
            }),
        });
    }

    return {
        spreadsheetId,
        spreadsheetUrl: `https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`,
    };
}

Deno.serve(async (req) => {
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    try {
        const body: CopyRequest = await req.json();
        const { template_id, section_id, user_id, new_name, user_access_token, fresh = true } = body;

        // Validate required fields
        if (!template_id || !section_id || !user_id || !new_name) {
            return errorResponse("Missing required fields: template_id, section_id, user_id, new_name");
        }

        if (!user_access_token) {
            return errorResponse("Missing user_access_token - user must be signed in with Google");
        }

        // Check if user already has a spreadsheet for this section
        const { data: existing } = await supabaseAdmin
            .from("user_spreadsheets")
            .select("id, spreadsheet_id")
            .eq("user_id", user_id)
            .eq("section_id", section_id)
            .single();

        // Fresh each session: delete old copy and create new
        if (existing && fresh) {
            try {
                // Delete old spreadsheet (use service account or user token)
                await deleteSpreadsheet(existing.spreadsheet_id);
                console.log(`Deleted old spreadsheet: ${existing.spreadsheet_id}`);
            } catch (deleteError) {
                console.error("Error deleting old spreadsheet:", deleteError);
            }

            await supabaseAdmin
                .from("user_spreadsheets")
                .delete()
                .eq("id", existing.id);
        } else if (existing && !fresh) {
            return successResponse({
                spreadsheet_id: existing.spreadsheet_id,
                spreadsheet_url: `https://docs.google.com/spreadsheets/d/${existing.spreadsheet_id}/edit`,
                message: "Existing spreadsheet returned",
            });
        }

        // Copy using user's token (creates in their Drive)
        const { spreadsheetId, spreadsheetUrl } = await copySpreadsheetAsUser(
            template_id,
            new_name,
            user_access_token
        );

        // Insert record into user_spreadsheets table
        const { error: insertError } = await supabaseAdmin
            .from("user_spreadsheets")
            .insert({
                user_id,
                section_id,
                spreadsheet_id: spreadsheetId,
                spreadsheet_url: spreadsheetUrl,
            });

        if (insertError) {
            console.error("Database insert error:", insertError);
        }

        // Create or update user progress record
        await supabaseAdmin
            .from("user_progress")
            .upsert({
                user_id,
                section_id,
                is_completed: false,
                attempt_count: 0,
                xp_earned: 0,
            }, { onConflict: "user_id,section_id" });

        return successResponse({
            spreadsheet_id: spreadsheetId,
            spreadsheet_url: spreadsheetUrl,
            message: "Spreadsheet copied to your Drive successfully",
        });

    } catch (error) {
        console.error("Error in copy-spreadsheet:", error);
        return errorResponse(`Internal error: ${error.message}`, 500);
    }
});
