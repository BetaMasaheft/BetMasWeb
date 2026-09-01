# Local dev image: the published betmas-data base (eXist + registry deps +
# the real corpus already installed and indexed) + BetMasService + parser
# (still built from source - neither is a standalone registry-published repo
# yet) + this package.
#
#   docker compose up --build

ARG BETMAS_DATA_IMAGE=ghcr.io/betamasaheft/betmas-data:latest
ARG BUILDER_IMAGE=ghcr.io/eeditiones/builder:latest

# ---- build xars from source ----
FROM ${BUILDER_IMAGE} AS build-stage

ADD https://github.com/BetaMasaheft/BetMas.git /src/BetMas
RUN ant -f /src/BetMas/db/apps/BetMasService/build.xml && \
	mv /src/BetMas/db/apps/BetMasService/build/*.xar /src/BetMas/db/apps/BetMasService/build/BetMasService.xar
# Ge'ez morphological parser - queries.xqm imports it unconditionally, so
# BetMasWeb won't even compile without it installed
RUN ant -f /src/BetMas/db/apps/parser/build.xml && \
	mv /src/BetMas/db/apps/parser/build/*.xar /src/BetMas/db/apps/parser/build/parser.xar

WORKDIR /src/BetMasWeb
COPY . .
RUN ant && mv build/*.xar build/BetMasWeb.xar

# ---- eXist, with everything installed ----
FROM ${BETMAS_DATA_IMAGE}

# monex and functx are declared dependencies (expath-pkg.xml); betmas-data
# already ships both, so nothing to fetch here.

# Not autodeploy: exist-db/exist#5579 skips already-installed package names
# even when the xar version is newer (enforceDeps=false). One client -F
# evals the admin seed secret then overlays via repo:* (repo.xml permissions).
# Install order still matters: BetMasWeb post-install expects BetMasService.
COPY --from=build-stage /src/BetMas/db/apps/BetMasService/build/BetMasService.xar /exist/overlay/BetMasService.xar
COPY --from=build-stage /src/BetMas/db/apps/parser/build/parser.xar /exist/overlay/parser.xar
COPY --from=build-stage /src/BetMasWeb/build/BetMasWeb.xar /exist/overlay/BetMasWeb.xar
COPY --from=build-stage /src/BetMas/db/apps/BetMasService/expath-pkg.xml /exist/overlay/BetMasService-expath-pkg.xml
COPY --from=build-stage /src/BetMas/db/apps/parser/expath-pkg.xml /exist/overlay/parser-expath-pkg.xml
COPY expath-pkg.xml /exist/overlay/BetMasWeb-expath-pkg.xml
COPY docker/overlay-packages.xq /exist/overlay/overlay-packages.xq

# seed.xq (admin password) is a build secret, not baked into the image.
# overlay-packages.xq util:eval's it, then replaces Service → parser → Web.
RUN --mount=type=secret,id=seed,target=/run/secrets/seed.xq,required=true ["java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-F", "/exist/overlay/overlay-packages.xq"]
