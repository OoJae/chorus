BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "shared_snapshot" ADD COLUMN "kind" text NOT NULL DEFAULT 'print'::text;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "weekly_summary" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "weekStart" timestamp without time zone NOT NULL,
    "report" json NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "weekly_summary_circle_week_idx" ON "weekly_summary" USING btree ("circleSpace", "weekStart");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "word_log_setting" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "enabled" boolean NOT NULL,
    "changedBy" uuid NOT NULL,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "word_log_setting_circle_idx" ON "word_log_setting" USING btree ("circleSpace");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "word_use" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "tileId" uuid NOT NULL,
    "boardId" uuid NOT NULL,
    "spokenAt" timestamp without time zone NOT NULL,
    "receivedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "word_use_circle_spoken_idx" ON "word_use" USING btree ("circleSpace", "spokenAt", "tileId");


--
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014094307220', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014094307220', "timestamp" = now();

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
