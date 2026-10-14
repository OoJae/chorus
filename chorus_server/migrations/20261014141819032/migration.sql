BEGIN;

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
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014141819032', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014141819032', "timestamp" = now();

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
