FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .  # This assumes public/, server.js, etc. exist here

EXPOSE 3000

CMD ["node", "server.js"]
