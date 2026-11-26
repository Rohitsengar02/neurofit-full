-- Expression indexes for the hot lookups inside JSONB.
CREATE INDEX IF NOT EXISTS docs_trainer_idx ON docs ((data->>'trainerId')) WHERE collection IN ('trainer_subscriptions','reviews','checkins','bookings');
CREATE INDEX IF NOT EXISTS docs_thread_idx  ON docs ((data->>'thread'), created_at) WHERE collection = 'messages';
CREATE INDEX IF NOT EXISTS docs_post_idx    ON docs ((data->>'postId'), created_at) WHERE collection = 'comments';
CREATE INDEX IF NOT EXISTS docs_status_idx  ON docs (collection, (data->>'status'));
CREATE INDEX IF NOT EXISTS docs_orderstatus_idx ON docs ((data->>'orderStatus'), created_at DESC) WHERE collection = 'orders';
CREATE INDEX IF NOT EXISTS docs_parentcat_idx ON docs ((data->>'parentCategoryId')) WHERE collection = 'subcategories';
CREATE INDEX IF NOT EXISTS docs_category_idx ON docs (collection, (data->>'categoryId'));
CREATE INDEX IF NOT EXISTS reactions_user_idx ON reactions (user_id, kind);
CREATE INDEX IF NOT EXISTS reactions_kind_idx ON reactions (kind, target_id);
