#!/bin/bash
# Grahvani Environment Startup Script (Linux / macOS)

echo "=================================================="
echo " 🪐 Grahvani Backend Startup Script"
echo "=================================================="

# 1. Check if Docker is running
echo "[1/4] Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    echo ""
    echo "❌ ERROR: Docker Engine is not running!"
    echo "   Details: Docker daemon is stopped or inaccessible."
    echo ""
    echo "👉 How to fix:"
    echo "   Option A: Start Docker Desktop (or 'sudo systemctl start docker') and re-run ./run.sh"
    echo "   Option B: Run FastAPI backend locally using Python:"
    echo "             cd services/api"
    echo "             poetry run uvicorn app.main:app --reload --port 8000"
    echo ""
    exit 1
fi
echo "✔ Docker Engine is running."

# 2. Determine compose command
COMPOSE_CMD="docker compose"
if ! docker compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
fi

# 3. Build and start containers
echo "[2/4] Starting PostgreSQL, Redis, API, and Background Worker containers..."
$COMPOSE_CMD up --build -d
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to start Docker containers."
    exit 1
fi

# 4. Wait for database
echo "[3/4] Waiting for services to initialize (10 seconds)..."
sleep 10

# 5. Apply migrations
echo "[4/4] Applying database migrations using Alembic..."
$COMPOSE_CMD exec api alembic upgrade head

# 6. Display Status
echo "----------------------------------------"
echo "Containers Status:"
$COMPOSE_CMD ps
echo "----------------------------------------"
echo "🚀 Grahvani Backend is successfully running!"
echo "   API Base URL   : http://localhost:8000"
echo "   Interactive Docs: http://localhost:8000/docs"
echo "   ReDoc           : http://localhost:8000/redoc"
echo ""
echo "💡 To view container logs: $COMPOSE_CMD logs -f"
