FROM node:20-alpine

WORKDIR /usr/src/app
RUN apk update && apk upgrade

COPY server.js .
EXPOSE 8080

CMD ["node", "server.js"]