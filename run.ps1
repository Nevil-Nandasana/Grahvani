# Grahvani Environment Startup Script

Write-Host "Starting Grahvani Backend Environment..." -ForegroundColor Cyan

# 1. Build and start the docker-compose stack in detached mode
Write-Host "Starting PostgreSQL, Redis, API, and Background Worker containers..." -ForegroundColor Yellow
docker-compose up --build -d

# 2. Wait for the database to be ready
Write-Host "Waiting for the database to initialize (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 3. Run database migrations
Write-Host "Applying database migrations using Alembic..." -ForegroundColor Yellow
docker-compose exec api alembic upgrade head

# 4. Display running containers
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Containers Running:" -ForegroundColor Cyan
docker-compose ps
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Grahvani Backend is running!" -ForegroundColor Green
Write-Host "API URL: http://localhost:8000" -ForegroundColor Green
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "To view logs, run: docker-compose logs -f" -ForegroundColor Yellow
