<#
.SYNOPSIS
    Rolls back traffic for /api/v2 to WildFly 20.
.DESCRIPTION
    Removes the Undertow reverse-proxy location override for /api/v2 in WildFly 20,
    instantly reverting traffic back to the legacy WildFly 20 application with zero downtime.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Rollback Migration: Reverting /api/v2 -> WildFly 20       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check if wf20-domain is running
$containerStatus = docker inspect --format='{{.State.Running}}' wf20-domain 2>$null
if ($containerStatus -ne "true") {
    Write-Error "Container 'wf20-domain' is not running. Start the environment first with .\scripts\start-environment.ps1"
    exit 1
}

# 2. Execute JBoss CLI command inside wf20-domain to remove location
Write-Host "Removing Undertow /api/v2 reverse-proxy location via JBoss CLI..." -ForegroundColor Yellow

$cliCommands = @(
    '/profile=full-ha/subsystem=undertow/server=default-server/host=default-host/location="\/api\/v2":remove()',
    '/server-group=other-server-group:reload-servers()'
)

$output = docker exec -i wf20-domain /opt/jboss/wildfly/bin/jboss-cli.sh --connect --commands="$($cliCommands -join ',')" 2>&1
Write-Host ($output -join "`n")

if ($output -match '"outcome" => "success"') {
    Write-Host "`nSuccessfully rolled back /api/v2 to WildFly 20!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} elseif ($output -match "WFLYCTL0216: Management resource.*not found" -or $output -match "not found") {
    Write-Host "`nRoute /api/v2 was not proxied (already handled locally by WildFly 20)." -ForegroundColor Yellow
} else {
    Write-Error "Failed to remove route via JBoss CLI. Output: $output"
    exit 1
}

# 3. Verify endpoint response
Write-Host "`nTesting http://localhost:8080/api/v2 via Ingress Load Balancer..." -ForegroundColor Cyan
try {
    $res = Invoke-WebRequest -Uri "http://localhost:8080/api/v2" -TimeoutSec 5 -UseBasicParsing
    if ($res.Content -match "WildFly 20" -or $res.Content -match "WF20") {
        Write-Host "VERIFIED: http://localhost:8080/api/v2 is now served by WildFly 20!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Unexpected response content:" -ForegroundColor Yellow
        Write-Host $res.Content
    }
} catch {
    Write-Warning "Could not reach http://localhost:8080/api/v2. Error: $_"
}
