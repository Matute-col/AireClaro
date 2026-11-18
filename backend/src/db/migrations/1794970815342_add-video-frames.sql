-- US-23 · Video frames (approved by Mateo on 17-nov-2026).
-- The app extracts 4 frames of each video (10 %, 35 %, 65 % and 90 % of its duration)
-- and sends them with the video. They are stored as DERIVED evidence:
--   kind = 'frame', source_media_id = the video, position = 1..4 (keeps the order).
-- Additive migration: two new NULLable columns, the `kind` CHECK is widened (existing
-- rows stay valid) and photo/video rows keep both new columns NULL.

-- Up Migration
ALTER TABLE report_media DROP CONSTRAINT report_media_kind_check;
ALTER TABLE report_media
  ADD CONSTRAINT report_media_kind_check CHECK (kind IN ('photo', 'video', 'frame'));

ALTER TABLE report_media
  ADD COLUMN source_media_id uuid NULL REFERENCES report_media(id) ON DELETE CASCADE,
  ADD COLUMN position smallint NULL;

-- A frame always has its video and a position 1..4; photos and videos have neither.
ALTER TABLE report_media ADD CONSTRAINT report_media_frame_check CHECK (
  (kind = 'frame' AND source_media_id IS NOT NULL AND position BETWEEN 1 AND 4)
  OR (kind <> 'frame' AND source_media_id IS NULL AND position IS NULL)
);

-- At most one frame per position of each video.
CREATE UNIQUE INDEX idx_media_frame_position
  ON report_media (source_media_id, position)
  WHERE kind = 'frame';

-- Down Migration
DROP INDEX IF EXISTS idx_media_frame_position;
ALTER TABLE report_media DROP CONSTRAINT IF EXISTS report_media_frame_check;
DELETE FROM report_media WHERE kind = 'frame';
ALTER TABLE report_media DROP COLUMN IF EXISTS position, DROP COLUMN IF EXISTS source_media_id;
ALTER TABLE report_media DROP CONSTRAINT report_media_kind_check;
ALTER TABLE report_media
  ADD CONSTRAINT report_media_kind_check CHECK (kind IN ('photo', 'video'));
