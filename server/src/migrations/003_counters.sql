-- Cheap daily counters (product views etc). One row per key per day, bumped with an upsert.
CREATE TABLE IF NOT EXISTS counters (
  event text NOT NULL,
  ref text NOT NULL DEFAULT '',
  day date NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Kolkata')::date,
  n bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (event, ref, day)
);
CREATE INDEX IF NOT EXISTS counters_event_day ON counters (event, day);
