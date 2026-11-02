<#
.SYNOPSIS
    Displays the current environment status and active routing rules.
#>
[CmdletBinding()]
param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
Set-Location $RootDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " WildFly 20/41 Environment Status Check                   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Container status
Write-Host "`nContainer Status:" -ForegroundColor Yellow
docker compose ps

# 2. Check current routing of /api/v2 in WildFly 20
Write-Host "`nActive Routing State for /api/v2:" -ForegroundColor Yellow
$wf20Running = docker inspect --format='{{.State.Running}}' wf20-domain 2>$null

if ($wf20Running -eq "true") {
    $cliCmd = '/profile=full-ha/subsystem=undertow/server=default-server/host=default-host/location="\/api\/v2":read-resource'
    $output = docker exec -i wf20-domain /opt/jboss/wildfly/bin/jboss-cli.sh --connect --commands="$cliCmd" 2>&1
    
    if ($output -match '"outcome" => "success"') {
        Write-Host " [ROUTED TO WILDFLY 41] Location /api/v2 is proxied to handler 'wf41-handler'" -ForegroundColor Magenta
    } else {
        Write-Host " [DEFAULT / WILDFLY 20] Location /api/v2 is handled locally by WildFly 20" -ForegroundColor Green
    }
} else {
    Write-Host " WildFly 20 domain container is not currently running." -ForegroundColor Red
}

# 3. Live test of Ingress
Write-Host "`nIngress Response Preview (http://localhost:8080/api/v2):" -ForegroundColor Yellow
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:8080/api/v2" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($resp.Content -match "WildFly 41") {
        Write-Host " Currently serving: WildFly 41" -ForegroundColor Magenta
    } elseif ($resp.Content -match "WildFly 20") {
        Write-Host " Currently serving: WildFly 20" -ForegroundColor Green
    } else {
        Write-Host " Response: HTTP $($resp.StatusCode)" -ForegroundColor White
    }
} catch {
    Write-Host " Ingress currently unreachable." -ForegroundColor DarkGray
}

Write-Host ""
