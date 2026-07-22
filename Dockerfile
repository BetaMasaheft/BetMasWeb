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
RUN ant -f /src/BetMas/db/apps/BetMasService/build.xml
# Ge'ez morphological parser - queries.xqm imports it unconditionally, so
# BetMasWeb won't even compile without it installed
RUN ant -f /src/BetMas/db/apps/parser/build.xml

WORKDIR /src/BetMasWeb
COPY . .
RUN ant

# ---- eXist, with everything installed ----
FROM ${BETMAS_DATA_IMAGE}

# monex and functx are declared dependencies (expath-pkg.xml); betmas-data
# already ships both, so nothing to fetch here.

# Install order matters: post-install.xq invokes BetMasService's
# registerRESTXQ.xql. Numbered to make the order explicit.
COPY --from=build-stage /src/BetMas/db/apps/BetMasService/build/*.xar /exist/autodeploy/01-BetMasService.xar
COPY --from=build-stage /src/BetMas/db/apps/parser/build/*.xar /exist/autodeploy/02-parser.xar
COPY --from=build-stage /src/BetMasWeb/build/*.xar /exist/autodeploy/03-BetMasWeb.xar

# Autodeploys everything above and seeds the test admin account.
# seed.xq (admin password) is a build secret, not baked into the image.
RUN --mount=type=secret,id=seed,target=/run/secrets/seed.xq,required=true ["java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-F", "/run/secrets/seed.xq"]
