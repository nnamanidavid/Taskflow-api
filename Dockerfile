# Stage 1 : Build
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src

# Stage 2 : Run
FROM node:24-alpine AS runtime
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node" , "src/server.js"]