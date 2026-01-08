SELECT 
  id,
  title,
  supports_spreadsheet,
  supports_python,
  CASE 
    WHEN python_starter_code_en IS NOT NULL THEN 'Has Python code'
    ELSE 'No Python code'
  END as python_status,
  CASE
    WHEN template_spreadsheet_id IS NOT NULL THEN 'Has template: ' || template_spreadsheet_id
    ELSE 'No template'
  END as spreadsheet_status
FROM sections
WHERE id = '885e7175-30b2-48de-8502-4eeeae7facc2';
