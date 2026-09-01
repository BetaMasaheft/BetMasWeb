# syntax=docker/dockerfile:1
# Local/CI image: the published BetMas app image + this repo's own package.
# `docker compose up --build` should serve without a cold package install.
#
# BetMasService, parser, and the expanded corpus are already in
# BETMAS_APP_IMAGE (BetMas CI publishes release-expanded). This repo only
# builds its own xar. Point BETMAS_APP_IMAGE at a local tag to test against
# an unpublished base image.
#
#   docker compose up --build

ARG BETMAS_APP_IMAGE=ghcr.io/betamasaheft/betamasaheft:release-expanded
ARG BUILDER_IMAGE=ghcr.io/eeditiones/builder:latest

# ---- build this repo's xar ----
FROM ${BUILDER_IMAGE} AS build-stage

WORKDIR /src/BetMasWeb
COPY . .
RUN ant && mv build/*.xar build/BetMasWeb.xar

# ---- the published app image + this repo's package ----
FROM ${BETMAS_APP_IMAGE}

# Not autodeploy: exist-db/exist#5579 skips already-installed package names
# even when the xar version is newer (enforceDeps=false). One client -F
# evals the admin seed secret then overlays via repo:* (repo.xml permissions).
COPY --from=build-stage /src/BetMasWeb/build/BetMasWeb.xar /exist/overlay/BetMasWeb.xar
COPY docker/overlay-web.xq /exist/overlay/overlay-web.xq
COPY expath-pkg.xml /exist/overlay/expath-pkg.xml

# seed.xq (admin password) is a build secret. CI writes it from SEED_XQ;
# overlay-web.xq util:eval's it, then replaces BetMasWeb.
RUN --mount=type=secret,id=seed,target=/run/secrets/seed.xq,required=true ["java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-F", "/exist/overlay/overlay-web.xq"]
