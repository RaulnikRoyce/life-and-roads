FROM node:20-bookworm-slim

WORKDIR /app

COPY api/package.json api/package-lock.json ./
RUN npm ci --omit=dev

COPY api/ ./
COPY docs/openapi.yaml /docs/openapi.yaml

ENV NODE_ENV=production
ENV APP_ENV=staging
EXPOSE 3001

CMD ["npm", "start"]
