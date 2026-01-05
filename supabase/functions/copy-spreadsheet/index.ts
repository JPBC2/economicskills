// copy-spreadsheet Edge Function
// Copies a template spreadsheet for a student and records it in the database

import {
    copySpreadsheet,
    supabaseAdmin,
    corsHeaders,
    handleCors,
    errorResponse,
    successResponse,
} from "../_shared/google-sheets.ts";

interface CopyRequest {
    template_id: string;
    section_id: string;
    user_id: string;
    new_name: string;
}

Deno.serve(async (req) => {
    // Handle CORS preflight
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    try {
        // Parse request body
        const body: CopyRequest = await req.json();
        const { template_id, section_id, user_id, new_name } = body;

        // Validate required fields
        if (!template_id || !section_id || !user_id || !new_name) {
            return errorResponse("Missing required fields: template_id, section_id, user_id, new_name");
        }

        // Check if user already has a spreadsheet for this section
        const { data: existing } = await supabaseAdmin
            .from("user_spreadsheets")
            .select("id, spreadsheet_id")
            .eq("user_id", user_id)
            .eq("section_id", section_id)
            .single();

        if (existing) {
            // Return existing spreadsheet
            return successResponse({
                spreadsheet_id: existing.spreadsheet_id,
                spreadsheet_url: `https://docs.google.com/spreadsheets/d/${existing.spreadsheet_id}/edit`,
                message: "Existing spreadsheet returned",
            });
        }

        // Copy the template spreadsheet
        const { spreadsheetId, spreadsheetUrl } = await copySpreadsheet(template_id, new_name);

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
            // Don't fail the request, spreadsheet was created successfully
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
            message: "Spreadsheet copied successfully",
        });

    } catch (error) {
        console.error("Error in copy-spreadsheet:", error);
        return errorResponse(`Internal error: ${error.message}`, 500);
    }
});
