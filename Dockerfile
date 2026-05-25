# Stage 1: Build the frontend and backend dependencies
FROM node:20-alpine AS builder
WORKDIR /app

# Install build essentials for native modules like better-sqlite3
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Production runtime image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# better-sqlite3 requires node-gyp dependencies at runtime sometimes, or prebuilt binaries
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci --only=production

# Copy built assets from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/.env.example ./.env.example

EXPOSE 3001

CMD ["npm", "run", "start"]
