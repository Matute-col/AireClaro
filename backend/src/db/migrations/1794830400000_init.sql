-- Initial schema (docs/05-modelo-de-datos-y-api.md).
-- gen_random_uuid() is built into PostgreSQL 13+.

-- Up Migration
CREATE TABLE authorities (
  id smallserial PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  email text,
  email_verified boolean NOT NULL DEFAULT false,
  portal_url text,
  note text
);

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  doc_type text NOT NULL CHECK (doc_type IN ('CC','CE','PAS')),
  doc_number text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  password_hash text NOT NULL,
  consent_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  authority_id smallint NOT NULL REFERENCES authorities(id),
  vehicle_type text NOT NULL CHECK (vehicle_type IN ('bus','microbus','camion','tractomula','otro')),
  plate text NOT NULL,
  smoke_color text NOT NULL CHECK (smoke_color IN ('negro','gris','blanco')),
  description text,
  lat double precision NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng double precision NOT NULL CHECK (lng BETWEEN -180 AND 180),
  address text,
  occurred_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'generado' CHECK (status IN ('generado','enviado')),
  requester_name text NOT NULL,
  requester_doc_type text NOT NULL,
  requester_doc_number text NOT NULL,
  requester_email text NOT NULL,
  requester_phone text,
  sent_at timestamptz,
  sent_via text CHECK (sent_via IN ('email','manual')),
  send_mode text CHECK (send_mode IN ('test','live')),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_reports_user_created ON reports (user_id, created_at DESC);
CREATE INDEX idx_reports_occurred ON reports (occurred_at);
CREATE INDEX idx_reports_coords ON reports (lat, lng);

CREATE TABLE report_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('photo','video')),
  file_path text NOT NULL,
  mime_type text NOT NULL,
  size_bytes integer NOT NULL
);
CREATE INDEX idx_media_report ON report_media (report_id);

-- Down Migration
DROP TABLE IF EXISTS report_media;
DROP TABLE IF EXISTS reports;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS authorities;
