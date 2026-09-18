FROM node:20-bookworm-slim

WORKDIR /app

COPY --chown=node:node api/package.json api/package-lock.json ./
RUN npm ci --omit=dev

COPY --chown=node:node api/ ./
COPY --chown=node:node docs/openapi.yaml /docs/openapi.yaml

ENV NODE_ENV=production
ENV APP_ENV=production
EXPOSE 3001

USER node
# tsx direto como processo principal: o SIGTERM do Render chega no nosso
# encerrar() e o container sai com 0, sem o "npm error signal SIGTERM".
CMD ["node_modules/.bin/tsx", "src/server.ts"]
