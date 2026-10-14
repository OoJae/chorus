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
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014142355883', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014142355883', "timestamp" = now();

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
