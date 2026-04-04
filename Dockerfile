# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

FROM oven/bun:1.2.21-alpine@sha256:02564b43c26a0dc156ff4b70d7ccb68ebae5c486771d699ed1520c42e6ac5cb0 AS build
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun run build

FROM oven/bun:1.2.21-alpine@sha256:02564b43c26a0dc156ff4b70d7ccb68ebae5c486771d699ed1520c42e6ac5cb0 AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NITRO_SERVER_URL=http://127.0.0.1:3000

COPY --from=build /app/.output ./.output

EXPOSE 3000

CMD ["bun", ".output/server/index.mjs"]
