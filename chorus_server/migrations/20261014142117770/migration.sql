BEGIN;

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
-- MIGRATION VERSION FOR chorus
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('chorus', '20261014142117770', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014142117770', "timestamp" = now();

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
