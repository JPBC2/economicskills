-- EconomicSkills Content Data Seed File
-- Insert 5 Courses

INSERT INTO public.courses (id, title, description, display_order, is_active, created_at, updated_at) VALUES
('0e239b99-e5a9-4e60-baa8-59153328cb70', 'Microeconomics', 'Study how individuals and firms make decisions about allocating scarce resources in response to prices and market structures', 1, true, '2025-11-20 09:35:27.083361+00', '2025-11-20 09:35:27.083361+00'),
('2c8fa0a5-1cdf-424e-9c06-da5727ef4e7a', 'Macroeconomics', 'Study of aggregate economic activity, including long-run growth, short-run fluctuations, and monetary and fiscal policies to maintain stability', 2, true, '2025-11-20 09:35:27.083361+00', '2025-11-20 09:35:27.083361+00'),
('d744e460-c17c-4f41-8eba-66a3f77a5a0a', 'Statistics', 'Collect and interpret data, quantify uncertainty, draw inferences, and create visualizations', 3, true, '2025-11-20 09:35:27.083361+00', '2025-11-20 09:35:27.083361+00'),
('c0ec2e3e-b59f-4c7f-a6f0-e597f2591d0c', 'Mathematics', 'Linear algebra and calculus to model economic relationships, solve optimization problems, and analyze quantitative data', 4, true, '2025-11-20 09:35:27.083361+00', '2025-11-20 09:35:27.083361+00'),
('2db40690-c290-4c28-98c0-fc1812860f23', 'Finance', 'Study financial markets, valuation techniques, and corporate decision-making to optimize capital allocation, manage risk, and maximize shareholder wealth', 5, true, '2025-11-20 09:35:27.083361+00', '2025-11-20 09:35:27.083361+00');

-- Note: units, lessons, exercises, sections, and validation_rules tables are empty
-- These will be populated
