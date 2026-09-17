FROM node:alpine3.24 AS stage_1
ARG LANGGRAPH_DEPLOYMENT_URL
ENV LANGGRAPH_DEPLOYMENT_URL=${LANGGRAPH_DEPLOYMENT_URL}
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
WORKDIR /home/swordfish/
COPY swordfish/ .
RUN echo "[*] LANGGRAPH_DEPLOYMENT_URL has been set to '$LANGGRAPH_DEPLOYMENT_URL'" &&\
    npm install && npm run build

FROM node:alpine3.24
LABEL image.authors="Victor Fernandez III, @cyberphor"
WORKDIR /home/swordfish/
COPY --from=stage_1 /home/swordfish/.next/standalone/ .
COPY --from=stage_1 /home/swordfish/.next/static/ .next/static/
COPY --from=stage_1 /home/swordfish/public/ public/
ENV PORT=3000
EXPOSE 3000
USER node
CMD ["node", "server.js"]
