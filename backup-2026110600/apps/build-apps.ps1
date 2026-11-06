# Rebuild the sample WAR applications for WildFly 20 and WildFly 41
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Building sample applications..." -ForegroundColor Cyan

# Package using docker with jar tool
docker run --rm -v "${ScriptDir}:/workspace" jboss/wildfly:20.0.1.Final bash -c "
    cd /workspace/wf20-app && jar -cvf /workspace/wf20-app.war * >/dev/null
    cd /workspace/wf41-app && jar -cvf /workspace/wf41-app.war * >/dev/null
"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully packaged wf20-app.war and wf41-app.war" -ForegroundColor Green
} else {
    Write-Error "Failed to package WAR files."
}
