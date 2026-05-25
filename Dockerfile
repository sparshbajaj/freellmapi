# Stage 1: Build the frontend and backend dependencies
FROM node:20-alpine AS builder
WORKDIR /app

# Install build essentials for native modules like better-sqlite3
RUN apk add --no-cache python3 make g++

# Copy the entire project first so npm workspaces are detected correctly
COPY . .
RUN npm ci
RUN npm run build

# Stage 2: Production runtime image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# better-sqlite3 requires node-gyp dependencies at runtime sometimes, or prebuilt binaries
RUN apk add --no-cache python3 make g++

# Copy the entire project for production install to detect workspaces
COPY . .
RUN npm ci --omit=dev

EXPOSE 3001

# The start script is inside the server workspace
CMD ["npm", "run", "start", "-w", "server"]
