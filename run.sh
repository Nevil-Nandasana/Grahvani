#!/bin/bash
# Grahvani Environment Startup Script

echo "Starting Grahvani Backend Environment..."

# 1. Build and start the docker-compose stack in detached mode
echo "Starting PostgreSQL, Redis, API, and Background Worker containers..."
docker-compose up --build -d

# 2. Wait for the database to be ready
echo "Waiting for the database to initialize (10 seconds)..."
sleep 10

# 3. Run database migrations
echo "Applying database migrations using Alembic..."
docker-compose exec api alembic upgrade head

# 4. Display running containers
echo "----------------------------------------"
echo "Containers Running:"
docker-compose ps
echo "----------------------------------------"
echo "Grahvani Backend is running!"
echo "API URL: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo "To view logs, run: docker-compose logs -f"
