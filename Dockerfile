# Stage 1: Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Install build essentials for native modules like better-sqlite3
RUN apk add --no-cache python3 make g++

# Copy all source files
COPY . .

# Install all dependencies (including devDependencies for tsc)
RUN npm ci

# Build the project (creates dist folders in workspaces)
RUN npm run build

# Stage 2: Production runtime image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# better-sqlite3 requires node-gyp dependencies at runtime sometimes
RUN apk add --no-cache python3 make g++

# Copy workspace package files and root package.json for npm workspaces to function
COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/

# Install only production dependencies
RUN npm ci --omit=dev

# Copy compiled build artifacts from the builder stage
COPY --from=builder /app/server/dist ./server/dist
COPY --from=builder /app/client/dist ./client/dist

EXPOSE 3001

# Start the server workspace
CMD ["npm", "run", "start", "-w", "server"]
