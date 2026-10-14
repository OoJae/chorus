BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "board_copy" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "boardId" uuid NOT NULL,
    "boardName" text NOT NULL,
    "rows" bigint NOT NULL,
    "cols" bigint NOT NULL,
    "name" text NOT NULL,
    "takenBy" uuid NOT NULL,
    "takenByName" text NOT NULL,
    "takenAt" timestamp without time zone NOT NULL,
    "words" json NOT NULL
);

-- Indexes
CREATE INDEX "board_copy_circle_idx" ON "board_copy" USING btree ("circleSpace", "takenAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "circle_language" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "languageCode" text NOT NULL,
    "languageName" text NOT NULL,
    "changedBy" uuid NOT NULL,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "circle_language_space_idx" ON "circle_language" USING btree ("circleSpace");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "circle_voice" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "voiceName" text,
    "rate" double precision NOT NULL,
    "pitch" double precision NOT NULL,
    "changedBy" uuid NOT NULL,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "circle_voice_circle_idx" ON "circle_voice" USING btree ("circleSpace");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "device_seen" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "userName" text NOT NULL,
    "deviceId" text NOT NULL,
    "deviceLabel" text NOT NULL,
    "lastSyncAt" timestamp without time zone NOT NULL,
    "lastSeenAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "device_seen_circle_user_device_idx" ON "device_seen" USING btree ("circleSpace", "userId", "deviceId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "focus_nudge" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "weekStart" timestamp without time zone NOT NULL,
    "tileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "focus_nudge_circle_week_idx" ON "focus_nudge" USING btree ("circleSpace", "weekStart");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "focus_word" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "tileId" uuid NOT NULL,
    "tip" text NOT NULL,
    "weekStart" timestamp without time zone NOT NULL,
    "pinnedBy" uuid NOT NULL,
    "pinnedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "focus_word_circle_week_tile_idx" ON "focus_word" USING btree ("circleSpace", "weekStart", "tileId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "photo_idea_cache" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "imageSha256" text NOT NULL,
    "locale" text NOT NULL,
    "ideasJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "photo_idea_cache_key_idx" ON "photo_idea_cache" USING btree ("circleSpace", "imageSha256", "locale");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "progress_report_link" (
    "id" bigserial PRIMARY KEY,
    "token" text NOT NULL,
    "circleSpace" uuid NOT NULL,
    "report" json NOT NULL,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "progress_report_link_token_idx" ON "progress_report_link" USING btree ("token");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "quick_phrase" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "position" bigint NOT NULL,
    "text" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "quick_phrase_space_position_idx" ON "quick_phrase" USING btree ("circleSpace", "position");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "scene" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "name" text NOT NULL,
    "imageHash" text NOT NULL,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "archivedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "scene_circle_idx" ON "scene" USING btree ("circleSpace");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "scene_spot" (
    "id" bigserial PRIMARY KEY,
    "sceneId" bigint NOT NULL,
    "x" double precision NOT NULL,
    "y" double precision NOT NULL,
    "width" double precision NOT NULL,
    "height" double precision NOT NULL,
    "label" text NOT NULL,
    "speech" text,
    "position" bigint NOT NULL
);

-- Indexes
CREATE INDEX "scene_spot_scene_idx" ON "scene_spot" USING btree ("sceneId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sitter_tap" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "label" text NOT NULL,
    "tappedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "sitter_tap_circle_idx" ON "sitter_tap" USING btree ("circleSpace", "tappedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tile_setting" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "tileId" uuid NOT NULL,
    "hidden" boolean NOT NULL,
    "changedBy" uuid NOT NULL,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tile_setting_space_tile_idx" ON "tile_setting" USING btree ("circleSpace", "tileId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tile_translation" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "tileId" uuid NOT NULL,
    "languageCode" text NOT NULL,
    "label" text NOT NULL,
    "speech" text,
    "changedBy" uuid NOT NULL,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "tile_translation_space_tile_lang_idx" ON "tile_translation" USING btree ("circleSpace", "tileId", "languageCode");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "word_suggestion" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "label" text NOT NULL,
    "speech" text,
    "colorKey" text,
    "suggestedBy" uuid NOT NULL,
    "suggestedByName" text NOT NULL,
    "source" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "resolvedAt" timestamp without time zone,
    "resolution" text,
    "resolvedBy" uuid
);

-- Indexes
CREATE INDEX "word_suggestion_circle_idx" ON "word_suggestion" USING btree ("circleSpace", "resolvedAt");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "word_use" ADD COLUMN "modelled" boolean NOT NULL DEFAULT false;

--
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014151037130', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014151037130', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_offline_sync
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_offline_sync', '20260914143806119', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260914143806119', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
