// delete-spreadsheet Edge Function
// Deletes a spreadsheet when resetting an exercise

import {
    deleteSpreadsheet,
    supabaseAdmin,
    corsHeaders,
    handleCors,
    errorResponse,
    successResponse,
} from "../_shared/google-sheets.ts";

interface DeleteRequest {
    spreadsheet_id: string;
    section_id: string;
    user_id: string;
}

Deno.serve(async (req) => {
    // Handle CORS preflight
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    try {
        // Parse request body
        const body: DeleteRequest = await req.json();
        const { spreadsheet_id, section_id, user_id } = body;

        // Validate required fields
        if (!spreadsheet_id || !section_id || !user_id) {
            return errorResponse("Missing required fields: spreadsheet_id, section_id, user_id");
        }

        // Verify user owns this spreadsheet
        const { data: record, error: fetchError } = await supabaseAdmin
            .from("user_spreadsheets")
            .select("id")
            .eq("spreadsheet_id", spreadsheet_id)
            .eq("user_id", user_id)
            .eq("section_id", section_id)
            .single();

        if (fetchError || !record) {
            return errorResponse("Spreadsheet not found or you don't have permission to delete it");
        }

        // Delete from Google Drive
        try {
            await deleteSpreadsheet(spreadsheet_id);
        } catch (driveError) {
            console.warn("Google Drive delete error (may already be deleted):", driveError);
            // Continue anyway - spreadsheet might already be deleted
        }

        // Delete database record
        await supabaseAdmin
            .from("user_spreadsheets")
            .delete()
            .eq("spreadsheet_id", spreadsheet_id)
            .eq("user_id", user_id);

        // Reset progress (keep attempt count, reset completion)
        await supabaseAdmin
            .from("user_progress")
            .update({
                is_completed: false,
                xp_earned: 0,
                completed_at: null,
            })
            .eq("user_id", user_id)
            .eq("section_id", section_id);

        return successResponse({
            message: "Spreadsheet deleted and progress reset successfully",
            spreadsheet_id,
        });

    } catch (error) {
        console.error("Error in delete-spreadsheet:", error);
        return errorResponse(`Internal error: ${error.message}`, 500);
    }
});
