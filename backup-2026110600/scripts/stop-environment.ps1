<#
.SYNOPSIS
    Stops the WildFly 20/41 side-by-side migration testing environment.
.DESCRIPTION
    Tears down running containers and networks. Optionally removes volumes.
#>
[CmdletBinding()]
param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Set-Location $RootDir

Write-Host "Stopping WildFly test environment..." -ForegroundColor Yellow

if ($Clean) {
    docker compose down -v --remove-orphans
} else {
    docker compose down --remove-orphans
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Environment successfully stopped." -ForegroundColor Green
} else {
    Write-Error "Failed to stop containers cleanly."
}
