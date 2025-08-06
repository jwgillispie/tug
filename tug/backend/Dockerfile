# Multi-stage Docker build for enhanced security and smaller image size
# Stage 1: Build stage
FROM python:3.11-slim AS builder

# Set build arguments
ARG BUILD_ENV=production

# Install system dependencies and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for build
RUN groupadd -r builduser && useradd -r -g builduser builduser

# Set working directory
WORKDIR /build

# Copy requirements first for better cache utilization
COPY requirements.txt requirements-security.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Install security tools in build stage only
RUN if [ "$BUILD_ENV" != "production" ]; then \
        pip install --no-cache-dir --user -r requirements-security.txt; \
    fi

# Stage 2: Runtime stage
FROM python:3.11-slim AS runtime

# Set build arguments
ARG BUILD_ENV=production
ARG APP_VERSION=1.0.0

# Add labels for better maintainability
LABEL maintainer="Tug Development Team <dev@tug-app.com>" \
      version="${APP_VERSION}" \
      description="Tug application backend API" \
      build_env="${BUILD_ENV}"

# Install only runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    dumb-init \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for runtime
RUN groupadd -r tuguser && useradd -r -g tuguser tuguser \
    && mkdir -p /app /app/logs \
    && chown -R tuguser:tuguser /app

# Set working directory
WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /root/.local /home/tuguser/.local

# Make sure scripts in .local are usable
ENV PATH=/home/tuguser/.local/bin:$PATH

# Copy application code
COPY --chown=tuguser:tuguser . .

# Remove sensitive files that shouldn't be in production
RUN rm -rf tests/ migrations/ *.md requirements-security.txt \
    && find . -name "*.pyc" -delete \
    && find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Create necessary directories and set permissions
RUN mkdir -p logs tmp \
    && chown -R tuguser:tuguser logs tmp \
    && chmod 755 logs tmp

# Switch to non-root user
USER tuguser

# Set environment variables for security
ENV PYTHONPATH=/app \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    BUILD_ENV=${BUILD_ENV}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Command to run the application (no --reload in production)
CMD if [ "$BUILD_ENV" = "production" ]; then \
        uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4; \
    else \
        uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload; \
    fi
