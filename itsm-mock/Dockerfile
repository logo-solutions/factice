FROM node:20-alpine

WORKDIR /app
COPY package.json server.js ./
COPY ui ./ui

ENV ITSM_HOST=0.0.0.0 \
    ITSM_PORT=8095 \
    ITSM_DATA_DIR=/data

RUN mkdir -p /data && chown node:node /data
USER node
VOLUME /data
EXPOSE 8095

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:8095/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]
