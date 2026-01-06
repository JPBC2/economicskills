// validate-spreadsheet Edge Function
// Compares student answers against solution and awards XP

import {
    readSpreadsheetRange,
    compareValues,
    supabaseAdmin,
    corsHeaders,
    handleCors,
    errorResponse,
    successResponse,
} from "../_shared/google-sheets.ts";

interface ValidateRequest {
    user_spreadsheet_id: string;
    section_id: string;
    user_id: string;
    hint_used?: boolean;
}

interface ValidationResult {
    is_valid: boolean;
    score: number;
    total_cells: number;
    correct_cells: number;
    errors: Array<{ cell: string; expected: string; actual: string }>;
    xp_earned: number;
    message: string;
}

Deno.serve(async (req) => {
    // Handle CORS preflight
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    try {
        // Parse request body
        const body: ValidateRequest = await req.json();
        const { user_spreadsheet_id, section_id, user_id, hint_used = false } = body;

        // Validate required fields
        if (!user_spreadsheet_id || !section_id || !user_id) {
            return errorResponse("Missing required fields: user_spreadsheet_id, section_id, user_id");
        }

        // Get section info and validation rules
        const { data: section, error: sectionError } = await supabaseAdmin
            .from("sections")
            .select("*, validation_rules(*)")
            .eq("id", section_id)
            .single();

        if (sectionError || !section) {
            return errorResponse("Section not found");
        }

        // Check if there are validation rules
        const rules = section.validation_rules || [];
        if (rules.length === 0) {
            return errorResponse("No validation rules configured for this section");
        }

        // Get the first rule (main validation)
        const rule = rules[0];
        const config = rule.rule_config;

        if (!config.solution_spreadsheet_id || !config.range) {
            return errorResponse("Validation rule missing solution_spreadsheet_id or range");
        }

        const tolerance = config.tolerance || 0.01;

        // Read values from both spreadsheets
        const [studentValues, solutionValues] = await Promise.all([
            readSpreadsheetRange(user_spreadsheet_id, config.range),
            readSpreadsheetRange(config.solution_spreadsheet_id, config.range),
        ]);

        // Compare values
        const errors: Array<{ cell: string; expected: string; actual: string }> = [];
        let correctCells = 0;
        let totalCells = 0;

        // Parse range to get starting cell (e.g., "O3:O102" -> column O, starting row 3)
        const rangeMatch = config.range.match(/([A-Z]+)(\d+):([A-Z]+)(\d+)/);
        const startCol = rangeMatch ? rangeMatch[1] : "A";
        const startRow = rangeMatch ? parseInt(rangeMatch[2]) : 1;

        for (let row = 0; row < Math.max(studentValues.length, solutionValues.length); row++) {
            const studentRow = studentValues[row] || [];
            const solutionRow = solutionValues[row] || [];

            for (let col = 0; col < Math.max(studentRow.length, solutionRow.length); col++) {
                totalCells++;
                const studentVal = studentRow[col];
                const solutionVal = solutionRow[col];

                if (compareValues(studentVal, solutionVal, tolerance)) {
                    correctCells++;
                } else {
                    // Calculate cell reference
                    const cellCol = String.fromCharCode(startCol.charCodeAt(0) + col);
                    const cellRow = startRow + row;
                    errors.push({
                        cell: `${cellCol}${cellRow}`,
                        expected: String(solutionVal ?? ""),
                        actual: String(studentVal ?? ""),
                    });
                }
            }
        }

        const score = totalCells > 0 ? Math.round((correctCells / totalCells) * 100) : 0;
        const isValid = score === 100;

        // Get current progress to check attempt count
        const { data: progress } = await supabaseAdmin
            .from("user_progress")
            .select("attempt_count, is_completed, xp_earned")
            .eq("user_id", user_id)
            .eq("section_id", section_id)
            .single();

        const currentAttempts = progress?.attempt_count || 0;
        const alreadyCompleted = progress?.is_completed || false;
        const previousXP = progress?.xp_earned || 0;

        let xpEarned = 0;

        if (isValid && !alreadyCompleted) {
            // Award XP on first successful completion
            // Apply 30% penalty if hint was used
            const baseXP = section.xp_reward || 10;
            xpEarned = hint_used ? Math.floor(baseXP * 0.7) : baseXP;

            // Update progress
            await supabaseAdmin
                .from("user_progress")
                .upsert({
                    user_id,
                    section_id,
                    is_completed: true,
                    attempt_count: currentAttempts + 1,
                    xp_earned: xpEarned,
                    hint_used: hint_used,
                    completed_at: new Date().toISOString(),
                }, { onConflict: "user_id,section_id" });

            // Add XP to user's total
            await supabaseAdmin.rpc("add_user_xp", {
                p_user_id: user_id,
                p_xp_amount: xpEarned,
            });

            // Record XP transaction
            await supabaseAdmin
                .from("xp_transactions")
                .insert({
                    user_id,
                    amount: xpEarned,
                    transaction_type: "earned",
                    source_type: "section_completion",
                    source_id: section_id,
                    description: `Completed section: ${section.title}`,
                });

        } else {
            // Update attempt count
            await supabaseAdmin
                .from("user_progress")
                .upsert({
                    user_id,
                    section_id,
                    is_completed: alreadyCompleted,
                    attempt_count: currentAttempts + 1,
                    xp_earned: previousXP,
                }, { onConflict: "user_id,section_id" });
        }

        const result: ValidationResult = {
            is_valid: isValid,
            score,
            total_cells: totalCells,
            correct_cells: correctCells,
            errors: errors.slice(0, 10), // Limit to first 10 errors
            xp_earned: xpEarned,
            message: isValid
                ? alreadyCompleted
                    ? "All answers correct! (Already completed)"
                    : hint_used
                        ? `Congratulations! All answers correct! +${xpEarned} XP (hint penalty applied)`
                        : `Congratulations! All answers correct! +${xpEarned} XP`
                : `${correctCells}/${totalCells} correct (${score}%). Please review your answers.`,
        };

        return successResponse(result);

    } catch (error) {
        console.error("Error in validate-spreadsheet:", error);
        return errorResponse(`Internal error: ${error.message}`, 500);
    }
});
