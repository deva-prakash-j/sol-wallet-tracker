# Multi-stage Dockerfile for GraalVM Native Image with Agent

# Stage 1: Build stage with GraalVM
FROM ghcr.io/graalvm/native-image-community:24-ol9 AS build

# Install required build tools
RUN microdnf install -y findutils which

# Set working directory
WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradlew gradlew.bat ./
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Make gradlew executable
RUN chmod +x gradlew

# Copy source code
COPY src src

# Build the application JAR
RUN ./gradlew bootJar --no-daemon

# Stage 2: Generate native-image configuration using agent
FROM ghcr.io/graalvm/native-image-community:24-ol9 AS agent

WORKDIR /app

# Copy the built JAR from previous stage
COPY --from=build /app/build/libs/*.jar app.jar

# Create directories for agent output
RUN mkdir -p /app/agent-output

# Run the application with native-image-agent to generate configuration
# This runs the app briefly to collect reflection, JNI, and other metadata
RUN timeout 30s java -agentlib:native-image-agent=config-output-dir=/app/agent-output \
    -jar app.jar || true

# Stage 3: Build native image with agent configuration
FROM ghcr.io/graalvm/native-image-community:24-ol9 AS native-build

# Install required build tools
RUN microdnf install -y findutils which

WORKDIR /app

# Copy everything from build stage
COPY --from=build /app ./

# Copy agent configuration
COPY --from=agent /app/agent-output ./build/native/agent-output/main

# Build native image using Gradle
RUN if [ -d "./build/native/agent-output/main" ] && [ "$(ls -A ./build/native/agent-output/main 2>/dev/null)" ]; then \
        echo "Using agent configuration"; \
        ./gradlew nativeCompile --no-daemon; \
    else \
        echo "Building without agent configuration"; \
        ./gradlew nativeCompile --no-daemon; \
    fi && \
    cp build/native/nativeCompile/sol-wallet-tracker sol-wallet-tracker

# Stage 4: Runtime stage with minimal base image
FROM oraclelinux:9-slim

# Install required runtime libraries for GraalVM native images
RUN microdnf install -y \
    curl \
    && microdnf clean all \
    && groupadd -g 1001 appgroup \
    && useradd -u 1001 -g appgroup -s /bin/bash appuser

# Set working directory
WORKDIR /app

# Copy the native executable
COPY --from=native-build /app/sol-wallet-tracker /app/sol-wallet-tracker

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the port (adjust if your app uses a different port)
EXPOSE 8080

# Health check (optional) - using curl instead of wget
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the native executable
ENTRYPOINT ["/app/sol-wallet-tracker"]