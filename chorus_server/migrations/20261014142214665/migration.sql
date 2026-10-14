BEGIN;

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
-- ACTION ALTER TABLE
--
ALTER TABLE "word_use" ADD COLUMN "modelled" boolean NOT NULL DEFAULT false;

--
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014142214665', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014142214665', "timestamp" = now();

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
