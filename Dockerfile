FROM m.daocloud.io/docker.io/library/node:18-alpine
WORKDIR /app
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "reminder.js"]