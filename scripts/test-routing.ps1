<#
.SYNOPSIS
    Runs automated HTTP tests against the Ingress Load Balancer and backend clusters.
.DESCRIPTION
    Validates availability and routing targets for both default routing, legacy endpoints,
    and modernized endpoints.
#>
[CmdletBinding()]
param()

$tests = @(
    @{
        Name = "Ingress: Root (/)";
        Url = "http://localhost:8080/";
        ExpectedBackend = "WildFly 20";
        Description = "Ingress proxy default pass-through to WildFly 20"
    },
    @{
        Name = "Ingress: Legacy (/legacy)";
        Url = "http://localhost:8080/legacy";
        ExpectedBackend = "WildFly 20";
        Description = "Unmigrated legacy endpoint on WildFly 20"
    },
    @{
        Name = "Ingress: API v2 (/api/v2)";
        Url = "http://localhost:8080/api/v2";
        ExpectedBackend = "Dynamic (WF20 or WF41)";
        Description = "Strangler route - serves WF41 if cutover active, WF20 otherwise"
    },
    @{
        Name = "Direct WF20: Root (/)";
        Url = "http://localhost:8081/";
        ExpectedBackend = "WildFly 20";
        Description = "Direct access to WildFly 20 server-one (port 8080 inside container)"
    },
    @{
        Name = "Direct WF41: Root (/)";
        Url = "http://localhost:8180/";
        ExpectedBackend = "WildFly 41";
        Description = "Direct access to WildFly 41 server-one (port-offset 100 -> 8180)"
    },
    @{
        Name = "Direct WF41: API v2 (/api/v2)";
        Url = "http://localhost:8180/api/v2";
        ExpectedBackend = "WildFly 41";
        Description = "Direct access to WildFly 41 modernized endpoint"
    }
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Running Automated Routing & Health Verification Tests    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$results = @()

foreach ($t in $tests) {
    $status = "FAIL"
    $detected = "Unreachable"
    $statusCode = 0
    $responseTime = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $resp = Invoke-WebRequest -Uri $t.Url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $sw.Stop()
        $responseTime = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
        $statusCode = $resp.StatusCode

        if ($resp.Content -match "WildFly 41|WF41") {
            $detected = "WildFly 41"
        } elseif ($resp.Content -match "WildFly 20|WF20") {
            $detected = "WildFly 20"
        } else {
            $detected = "Unknown HTTP $statusCode"
        }

        if ($t.ExpectedBackend -eq "Dynamic (WF20 or WF41)") {
            if ($detected -in @("WildFly 20", "WildFly 41")) {
                $status = "PASS"
            }
        } elseif ($detected -eq $t.ExpectedBackend) {
            $status = "PASS"
        }
    } catch {
        $sw.Stop()
        $responseTime = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $detected = "HTTP $statusCode"
        } else {
            $detected = $_.Exception.Message
        }
    }

    $color = if ($status -eq "PASS") { "Green" } else { "Red" }
    Write-Host ("[{0}] {1,-32} -> {2,-12} ({3}ms)" -f $status, $t.Name, $detected, $responseTime) -ForegroundColor $color

    $results += [PSCustomObject]@{
        Test = $t.Name
        Url = $t.Url
        Status = $status
        Backend = $detected
        Expected = $t.ExpectedBackend
        "Time(ms)" = $responseTime
    }
}

Write-Host "`nTest Summary Table:" -ForegroundColor Cyan
$results | Format-Table -AutoSize
