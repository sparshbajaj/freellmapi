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

# Create a data directory for persistent storage
RUN mkdir -p /app/data

# Copy workspace package files and root package.json for npm workspaces to function
COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/

# Install only production dependencies
RUN npm ci --omit=dev

# Copy compiled build artifacts from the builder stage
COPY --from=builder /app/server/dist ./server/dist
COPY --from=builder /app/client/dist ./client/dist

# Expose port
EXPOSE 3001

# The application naturally looks for its database at /app/server/data/freeapi.db
# (relative to /app/server/dist/db/index.js). 
# To make it persistent, we will symlink that directory to /app/data
RUN mkdir -p /app/server/data && rm -rf /app/server/data && ln -s /app/data /app/server/data

# Volume for persistence
VOLUME /app/data

# Start the server workspace
CMD ["npm", "run", "start", "-w", "server"]
