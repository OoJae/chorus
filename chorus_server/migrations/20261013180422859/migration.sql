BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ai_usage" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "day" text NOT NULL,
    "calls" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ai_usage_circle_day_idx" ON "ai_usage" USING btree ("circleSpace", "day");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "media_object" (
    "id" bigserial PRIMARY KEY,
    "circleSpace" uuid NOT NULL,
    "sha256" text NOT NULL,
    "kind" text NOT NULL,
    "path" text NOT NULL,
    "bytes" bigint NOT NULL,
    "createdBy" uuid NOT NULL,
    "verifiedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "media_object_circle_hash_idx" ON "media_object" USING btree ("circleSpace", "sha256");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "shared_snapshot" (
    "id" bigserial PRIMARY KEY,
    "token" text NOT NULL,
    "circleSpace" uuid NOT NULL,
    "boardJson" text NOT NULL,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "shared_snapshot_token_idx" ON "shared_snapshot" USING btree ("token");


--
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261013180422859', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261013180422859', "timestamp" = now();

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
