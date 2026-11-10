FROM node:22-bookworm AS deps
WORKDIR /app
ENV NODE_ENV=development
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ pkg-config libsqlite3-dev && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
COPY server/package*.json server/
COPY web/package*.json web/
RUN npm ci --include=dev

FROM node:22-bookworm AS build
WORKDIR /app
ENV NODE_ENV=development
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package*.json ./
COPY --from=build /app/server/package*.json server/
COPY --from=build /app/web/package*.json web/
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/server server
COPY --from=build /app/web web
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["npm","run","start"]
