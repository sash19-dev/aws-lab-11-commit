CREATE TABLE IF NOT EXISTS app_state (
  id         INT PRIMARY KEY,
  version    TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO app_state (id, version)
VALUES (1, 'v1.0.0')
ON CONFLICT (id) DO NOTHING;
