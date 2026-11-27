# NeuroFit API image (Node 22). Used by deploy/docker-compose.yml on the Hostinger VPS.
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY src ./src
USER node
EXPOSE 5000
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=10 \
  CMD wget -qO- http://127.0.0.1:5000/api/health || exit 1
CMD ["node", "src/index.js"]
