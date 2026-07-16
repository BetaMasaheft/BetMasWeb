# Local dev image: eXist + shared-resources + BetMasService + parser + this
# package (BetMasWeb), all pre-installed at build time so `docker run` serves
# immediately.
#
# Staged slow-to-fast so editing BetMasWeb source only invalidates the last
# step - shared-resources/BetMasService/parser stay cached.
#
#   docker compose up --build
#

ARG EXISTDB_VERSION=6.4.1

# ---- build xars from source (needs ant, not present in the eXist image) ----
FROM node:latest AS build-stage
RUN apt-get update && apt-get install -y --no-install-recommends ant && rm -rf /var/lib/apt/lists/*

ADD https://github.com/BetaMasaheft/BetMas.git /src/BetMas
RUN ant -f /src/BetMas/db/apps/BetMasService/build.xml
# Ge'ez morphological parser - queries.xqm imports it unconditionally, so
# BetMasWeb won't even compile without it installed
RUN ant -f /src/BetMas/db/apps/parser/build.xml
# Reference lists (prefixDef, person/place name labels, textparts titles, ...)
# read via doc("/db/apps/lists/*.xml") by exptit.xqm/apprest.xqm/titles.xqm.
# Without this installed those doc() calls silently return the empty
# sequence instead of 404ing, which is what was producing the apparent
# exptit:printTitleID / apprest:decidelink crashes - not a code bug.
RUN ant -f /src/BetMas/db/apps/lists/build.xml

WORKDIR /src/BetMasWeb
COPY . .
RUN ant

# ---- eXist, with everything installed ----
FROM existdb/existdb:${EXISTDB_VERSION}-DEBUG

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_26.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install --global @existdb/xst@4 && \
    rm -rf /var/lib/apt/lists/*

ENV EXISTDB_SERVER=http://localhost:8080 \
    EXISTDB_USER=admin \
    EXISTDB_PASS=

# explode: pre-extract jars into their own cached layer
RUN [ "java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-x", "'HelloWorld!'" ]

# slow-changing deps: shared-resources, BetMasService, parser, lists
COPY --from=build-stage /src/BetMas/db/apps/BetMasService/build/*.xar /install/BetMasService/
COPY --from=build-stage /src/BetMas/db/apps/parser/build/*.xar /install/parser/
COPY --from=build-stage /src/BetMas/db/apps/lists/build/*.xar /install/lists/

RUN java org.exist.start.Main jetty & \
    EXIST_PID=$! && \
    timeout 120 bash -c 'until curl -sf http://localhost:8080/exist/rest/ > /dev/null 2>&1; do echo "Waiting..."; sleep 3; done' && \
    xst package install from-registry shared-resources && \
    xst execute "if (sm:user-exists('BetaMasaheftAdmin')) then () else sm:create-account('BetaMasaheftAdmin', 'test', 'dba')" && \
    xst execute "if (xmldb:collection-available('/db/apps/expanded')) then () else xmldb:create-collection('/db/apps', 'expanded')" && \
    xst execute "for \$c in ('authority-files','manuscripts','institutions','narratives','persons','places','studies','works') where not(xmldb:collection-available('/db/apps/expanded/' || \$c)) return xmldb:create-collection('/db/apps/expanded', \$c)" && \
    xst package install local-files /install/BetMasService/*.xar && \
    xst package install local-files /install/parser/*.xar && \
    xst package install local-files /install/lists/*.xar && \
    kill $EXIST_PID && \
    wait $EXIST_PID; true

# this package: rebuilds fast on every local change
COPY --from=build-stage /src/BetMasWeb/build/*.xar /install/BetMasWeb/
COPY test/fixtures /install/fixtures

RUN java org.exist.start.Main jetty & \
    EXIST_PID=$! && \
    timeout 120 bash -c 'until curl -sf http://localhost:8080/exist/rest/ > /dev/null 2>&1; do echo "Waiting..."; sleep 3; done' && \
    xst package install local-files /install/BetMasWeb/*.xar && \
    xst upload /install/fixtures /db/apps/expanded && \
    kill $EXIST_PID && \
    wait $EXIST_PID; true
