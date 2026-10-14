BEGIN;

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
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014142332485', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014142332485', "timestamp" = now();

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
