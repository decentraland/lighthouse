FROM node:16-alpine as base
WORKDIR /app
RUN apk add --no-cache bash

COPY package.json .
COPY yarn.lock .

# get production dependencies
FROM base as dependencies
RUN yarn install --prod --frozen-lockfile

# build sources
FROM base as catalyst-builder
RUN yarn install --frozen-lockfile

COPY . .
FROM catalyst-builder as comms-builder
RUN yarn build

# build final image with transpiled code and runtime dependencies
FROM base

COPY --from=dependencies /app/node_modules ./node_modules/

COPY --from=comms-builder /app/dist/src .

# https://docs.docker.com/engine/reference/builder/#arg
ARG LIGHTHOUSE_VERSION=4.0.0-ci
ENV LIGHTHOUSE_VERSION=${LIGHTHOUSE_VERSION:-4.0.0}

# https://docs.docker.com/engine/reference/builder/#arg
ARG COMMIT_HASH=local
ENV COMMIT_HASH=${COMMIT_HASH:-local}

EXPOSE 9000

ENTRYPOINT [ "node", "--max-old-space-size=8192", "server.js" ]
