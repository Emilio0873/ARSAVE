-- Verify ownership isolation (run after creating two users with files)
-- Replace IDs with real values from your DB.

-- User A must only see own files:
-- SELECT id, logical_name FROM files WHERE user_id = <user_a_id>;

-- API always filters by authenticated user_id in FileService::getOwnedFile.
-- Cross-user download returns 404, never another user's blob.
