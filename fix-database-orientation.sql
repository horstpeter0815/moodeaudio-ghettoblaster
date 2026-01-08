-- Fix Video Display Issues - Database Update
-- Updates hdmi_scn_orient from portrait to landscape

-- Check current value
SELECT param, value FROM cfg_system WHERE param='hdmi_scn_orient';

-- Update to landscape
UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';

-- Verify update
SELECT param, value FROM cfg_system WHERE param='hdmi_scn_orient';

