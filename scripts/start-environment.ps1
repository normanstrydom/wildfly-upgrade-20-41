<#
.SYNOPSIS
    Starts the WildFly 20/41 side-by-side migration testing environment.
.DESCRIPTION
    Builds the test applications if needed, launches docker compose services,
    and waits for all containers to report healthy status.
#>
[CmdletBinding()]
param(
    [switch]$RebuildApps,
    [switch]$NoWait
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Set-Location $RootDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Starting WildFly 20 -> 41 Side-by-Side Test Environment " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Verify Docker is running
try {
    docker info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker engine is not running. Please start Docker Desktop first."
    }
} catch {
    Write-Error "Failed to connect to Docker. Ensure Docker Desktop is running."
    exit 1
}

# 2. Check and build WAR files if missing or if -RebuildApps specified
$wf20War = Join-Path $RootDir "apps\wf20-app.war"
$wf41War = Join-Path $RootDir "apps\wf41-app.war"

if ($RebuildApps -or (-not (Test-Path $wf20War)) -or (-not (Test-Path $wf41War))) {
    Write-Host "[1/3] Building sample WAR packages..." -ForegroundColor Yellow
    & "$RootDir\apps\build-apps.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build application packages."
        exit 1
    }
} else {
    Write-Host "[1/3] Application WAR packages already exist." -ForegroundColor Green
}

# 3. Start docker compose
Write-Host "[2/3] Building and starting Docker Compose services..." -ForegroundColor Yellow
docker compose up --build -d
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker compose up failed."
    exit 1
}

if ($NoWait) {
    Write-Host "Containers started in background. Skipping wait." -ForegroundColor Yellow
    exit 0
}

# 4. Wait for healthy containers
Write-Host "[3/3] Waiting for services to become healthy (this may take 30-45 seconds)..." -ForegroundColor Yellow

$timeout = 90
$elapsed = 0
$interval = 3

while ($elapsed -lt $timeout) {
    $unhealthy = @()
    $services = @("wf20-domain", "wf41-domain", "wf-load-balancer")
    
    foreach ($svc in $services) {
        $status = docker inspect --format='{{json .State.Health.Status}}' $svc 2>$null
        if ($null -ne $status) {
            $status = $status.Trim('"')
            if ($status -ne "healthy") {
                $unhealthy += "$svc ($status)"
            }
        } else {
            $unhealthy += "$svc (not running)"
        }
    }

    if ($unhealthy.Count -eq 0) {
        Write-Host "`nAll services are HEALTHY and ready!" -ForegroundColor Green
        break
    }

    Write-Host -NoNewline "."
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($unhealthy.Count -gt 0) {
    Write-Warning "`nTimed out waiting for services: $($unhealthy -join ', ')"
    Write-Host "Check container logs using: docker compose logs" -ForegroundColor Yellow
}

# Display endpoints summary
Write-Host "`nService Endpoints:" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------"
Write-Host " Ingress Load Balancer:     http://localhost:8080/" -ForegroundColor White
Write-Host " WildFly 20 Domain (Direct):http://localhost:8081/" -ForegroundColor White
Write-Host " WildFly 20 Management:     http://localhost:9990/ (admin / Admin123!)" -ForegroundColor White
Write-Host " WildFly 41 Domain (Direct):http://localhost:8180/" -ForegroundColor White
Write-Host " WildFly 41 Management:     http://localhost:10090/ (admin / Admin123!)" -ForegroundColor White
Write-Host "----------------------------------------------------------"
Write-Host "Run .\scripts\test-routing.ps1 to verify traffic routing." -ForegroundColor Green
