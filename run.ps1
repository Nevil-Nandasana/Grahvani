# Grahvani Environment Startup Script (Windows PowerShell)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Grahvani Backend Startup Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Check if Docker is installed and daemon is running
Write-Host "[1/4] Checking Docker status..." -ForegroundColor Yellow
$dockerCheck = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Docker Engine is not running!" -ForegroundColor Red
    Write-Host "        Details: Docker Desktop is closed or daemon is inaccessible." -ForegroundColor Red
    Write-Host ""
    Write-Host "How to fix:" -ForegroundColor Yellow
    Write-Host "  Option A: Open 'Docker Desktop' on your PC, wait for it to start, then re-run .\run.ps1" -ForegroundColor Yellow
    Write-Host "  Option B: Run FastAPI locally using Python:" -ForegroundColor Yellow
    Write-Host "            cd services\api" -ForegroundColor Cyan
    Write-Host "            poetry run uvicorn app.main:app --reload --port 8000" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
Write-Host "[OK] Docker Engine is running." -ForegroundColor Green

# 2. Determine compose command syntax
$composeCmd = "docker compose"
$composeCheck = docker compose version 2>&1
if ($LASTEXITCODE -ne 0) {
    $composeCmd = "docker-compose"
}

# 3. Build and start containers
Write-Host "[2/4] Starting PostgreSQL, Redis, API, and Background Worker containers..." -ForegroundColor Yellow
if ($composeCmd -eq "docker compose") {
    docker compose up --build -d
} else {
    docker-compose up --build -d
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Failed to start Docker containers." -ForegroundColor Red
    exit 1
}

# 4. Wait for database and services to be ready
Write-Host "[3/4] Waiting 10 seconds for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 5. Apply Alembic DB migrations
Write-Host "[4/4] Applying database migrations using Alembic..." -ForegroundColor Yellow
if ($composeCmd -eq "docker compose") {
    docker compose exec api alembic upgrade head
} else {
    docker-compose exec api alembic upgrade head
}

# 6. Display Status
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Containers Status:" -ForegroundColor Cyan
if ($composeCmd -eq "docker compose") {
    docker compose ps
} else {
    docker-compose ps
}
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "[SUCCESS] Grahvani Backend is running!" -ForegroundColor Green
Write-Host "  API Base URL    : http://localhost:8000" -ForegroundColor Green
Write-Host "  Interactive Docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "  ReDoc           : http://localhost:8000/redoc" -ForegroundColor Green
Write-Host ""
Write-Host "To view container logs, run: $composeCmd logs -f" -ForegroundColor Yellow
