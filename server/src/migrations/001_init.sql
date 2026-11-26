-- NeuroFit core schema.
-- Content managed in the admin panel lives in `docs` (one JSONB row per item).
-- Everything a user creates on their phone is synced through `user_records`.

CREATE SEQUENCE IF NOT EXISTS rev_seq;

CREATE TABLE IF NOT EXISTS users (
  id                text PRIMARY KEY,
  email             text UNIQUE,
  password_hash     text,
  google_sub        text UNIQUE,
  name              text NOT NULL DEFAULT 'Athlete',
  phone             text NOT NULL DEFAULT '',
  photo_url         text NOT NULL DEFAULT '',
  auth_provider     text NOT NULL DEFAULT 'email',
  role              text NOT NULL DEFAULT 'user',      -- user | trainer | vendor | admin | superadmin
  status            text NOT NULL DEFAULT 'active',    -- active | suspended | banned
  is_premium        boolean NOT NULL DEFAULT false,
  is_verified       boolean NOT NULL DEFAULT false,
  has_completed_onboarding boolean NOT NULL DEFAULT false,
  questionnaire     jsonb NOT NULL DEFAULT '{}'::jsonb,
  addresses         jsonb NOT NULL DEFAULT '[]'::jsonb,
  profile           jsonb NOT NULL DEFAULT '{}'::jsonb, -- anything else the app stores on the profile
  fcm_token         text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  last_active_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS users_created_idx ON users (created_at DESC);
CREATE INDEX IF NOT EXISTS users_active_idx ON users (last_active_at DESC);
CREATE INDEX IF NOT EXISTS users_role_idx ON users (role);
CREATE INDEX IF NOT EXISTS users_name_trgm ON users (lower(name));

CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_hash  text PRIMARY KEY,
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at  timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS refresh_tokens_user_idx ON refresh_tokens (user_id);

-- Generic content store: products, categories, banners, layouts, workouts,
-- exercises, plans, CMS items, orders, posts, trainers, live sessions ...
CREATE TABLE IF NOT EXISTS docs (
  collection  text NOT NULL,
  id          text NOT NULL,
  owner_id    text,
  data        jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order  double precision NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  rev         bigint NOT NULL DEFAULT nextval('rev_seq'),
  PRIMARY KEY (collection, id)
);
CREATE INDEX IF NOT EXISTS docs_sort_idx  ON docs (collection, sort_order, created_at);
CREATE INDEX IF NOT EXISTS docs_owner_idx ON docs (collection, owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS docs_created_idx ON docs (collection, created_at DESC);
CREATE INDEX IF NOT EXISTS docs_rev_idx   ON docs (collection, rev);
CREATE INDEX IF NOT EXISTS docs_data_gin  ON docs USING gin (data jsonb_path_ops);

-- Offline sync: every record the phone keeps in SQLite has a row here.
CREATE TABLE IF NOT EXISTS user_records (
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collection  text NOT NULL,
  id          text NOT NULL,
  data        jsonb NOT NULL DEFAULT '{}'::jsonb,
  deleted     boolean NOT NULL DEFAULT false,
  client_updated_at timestamptz NOT NULL DEFAULT now(),
  rev         bigint NOT NULL DEFAULT nextval('rev_seq'),
  PRIMARY KEY (user_id, collection, id)
);
CREATE INDEX IF NOT EXISTS user_records_rev_idx ON user_records (user_id, rev);
CREATE INDEX IF NOT EXISTS user_records_coll_idx ON user_records (collection, client_updated_at DESC);

-- Community likes / votes (one row per user so counts can't be faked).
CREATE TABLE IF NOT EXISTS reactions (
  target_id  text NOT NULL,
  user_id    text NOT NULL,
  kind       text NOT NULL DEFAULT 'like',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (target_id, user_id, kind)
);

-- Request counters for the admin analytics (one row per day).
CREATE TABLE IF NOT EXISTS daily_stats (
  day         date NOT NULL,
  metric      text NOT NULL,
  value       bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (day, metric)
);
