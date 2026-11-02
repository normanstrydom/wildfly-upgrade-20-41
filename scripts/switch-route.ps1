<#
.SYNOPSIS
    Switches traffic for /api/v2 to WildFly 41 using the Strangler Fig pattern.
.DESCRIPTION
    Executes JBoss CLI against the WildFly 20 domain controller to route the
    virtual path /api/v2 to the Undertow reverse-proxy handler pointing to WildFly 41.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Strangler Fig Migration: Routing /api/v2 -> WildFly 41   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check if wf20-domain is running
$containerStatus = docker inspect --format='{{.State.Running}}' wf20-domain 2>$null
if ($containerStatus -ne "true") {
    Write-Error "Container 'wf20-domain' is not running. Start the environment first with .\scripts\start-environment.ps1"
    exit 1
}

# 2. Execute JBoss CLI command inside wf20-domain
Write-Host "Applying Undertow route configuration via JBoss CLI..." -ForegroundColor Yellow

$cliCommand = '/profile=full-ha/subsystem=undertow/server=default-server/host=default-host/location="\/api\/v2":add(handler="wf41-handler")'

# Run CLI inside container
$output = docker exec -i wf20-domain /opt/jboss/wildfly/bin/jboss-cli.sh --connect --commands="$cliCommand" 2>&1
Write-Host ($output -join "`n")

if ($output -match '"outcome" => "success"') {
    Write-Host "`nSuccessfully routed /api/v2 to WildFly 41!" -ForegroundColor Green
} elseif ($output -match "WFLYCTL0212: Duplicate resource" -or $output -match "already exists") {
    Write-Host "`nRoute /api/v2 is already mapped to WildFly 41." -ForegroundColor Yellow
} else {
    Write-Error "Failed to update route via JBoss CLI. Output: $output"
    exit 1
}

# 3. Verify endpoint response
Write-Host "`nTesting http://localhost:8080/api/v2 via Ingress Load Balancer..." -ForegroundColor Cyan
try {
    $res = Invoke-WebRequest -Uri "http://localhost:8080/api/v2" -TimeoutSec 5 -UseBasicParsing
    if ($res.Content -match "WildFly 41" -or $res.Content -match "WF41") {
        Write-Host "VERIFIED: http://localhost:8080/api/v2 is now served by WildFly 41!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Unexpected response content:" -ForegroundColor Yellow
        Write-Host $res.Content
    }
} catch {
    Write-Warning "Could not reach http://localhost:8080/api/v2. Error: $_"
}
