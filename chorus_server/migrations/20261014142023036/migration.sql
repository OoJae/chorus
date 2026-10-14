BEGIN;

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
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014142023036', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014142023036', "timestamp" = now();

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
