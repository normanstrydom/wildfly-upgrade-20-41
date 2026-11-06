# wildfly-upgrade-20-41

## Implementation Prompt & Requirements

Build a Docker Compose environment and supporting automation scripts to simulate an in-place, side-by-side migration and upgrade from WildFly 20 to WildFly 41 in Domain Mode using the Strangler Fig pattern.

### 1. Objective
Create an end-to-end sandbox demonstrating a smooth, low-risk upgrade transition from legacy WildFly 20 to WildFly 41. The environment must host both versions simultaneously in Domain Mode across shared host nodes, route specific application paths incrementally from WildFly 20 to WildFly 41 without breaking external API contracts, and support instant rollback if an upgraded deployment fails.

### 2. Architecture & Clustering
- **Domain Mode Topology:**
  - Simulate a distributed Domain Controller (DC) and Host Controller (HC) architecture for both WildFly 20 and WildFly 41.
  - Domain members of both versions must run alongside each other on shared container hosts/nodes to mimic an on-premises physical or VM server co-location scenario.
- **Profiles & High Availability:**
  - All application server groups must use High Availability (`ha` / `full-ha`) profiles with clustering, session replication, and discovery configured.
- **Ingress & Load Balancing:**
  - Dedicated WildFly load balancer(s) (using Undertow proxy or `mod_cluster`) must serve as the primary ingress entrypoint for all incoming HTTP/HTTPS traffic.

### 3. Port Offset & Conflict Prevention Strategy
- **WildFly 20:** Configured on standard base ports (HTTP `8080`, HTTPS `8443`, Management `9990`, Clustering `7600/55200`, etc.) or standard offset `0`.
- **WildFly 41:** Configured with a dedicated port offset (e.g., `port-offset="100"` or `port-offset="1000"`) across all socket bindings and management interfaces to guarantee zero port collisions when running concurrently on the same host nodes.

### 4. Traffic Routing, Strangler Pattern & Rollback
- **Virtual Path Proxying:**
  - Configure the ingress load balancer and/or WildFly 20 Undertow reverse proxy to route traffic based on URL context paths.
  - By default, all application requests route to WildFly 20 server groups.
  - As individual services/WARs are modernized and deployed to WildFly 41, specific virtual paths/context roots (e.g., `/api/v2/*` or specific migrated endpoints) must be forwarded directly to WildFly 41.
  - Upstream clients and external callers must continue using the original ingress host and URI structure without modification.
- **Zero-Downtime Rollback:**
  - Provide a mechanism (CLI scripts or configuration switches) to immediately revert path routing from WildFly 41 back to WildFly 20 if a deployment fails or exhibits defects.

### 5. Required Deliverables
1. **Docker Compose Orchestration:**
   - `docker-compose.yml` defining the Domain Controllers, Host Controllers, and Ingress Load Balancer services, connected via a dedicated Docker network.
   - Resource configurations, volume mounts for persistent configurations/deployments, and container health checks.
2. **Configuration & Customization:**
   - Base `domain.xml` and `host.xml` templates for both WildFly 20 and WildFly 41.
   - Ingress load balancer configuration (Undertow reverse proxy / `mod_cluster`).
3. **Automation & Management Scripts:**
   - JBoss CLI scripts (`.cli`) for configuring socket binding offsets, proxy rules, server groups, and datasources/resources.
   - Shell and/or PowerShell lifecycle scripts (`start.sh`/`start.ps1`, `stop.sh`/`stop.ps1`, `switch-route.sh`, `rollback.sh`).
4. **Sample Application & Verification:**
   - Minimal test application (or mock WARs/endpoints) deployed to both WildFly 20 and WildFly 41 displaying version and host metadata.
   - Automated smoke test / curl verification script demonstrating request routing to WF20, cutover of a virtual path to WF41, and successful rollback.

### 6. Docker images to use
1. jboss/wildfly:20.0.1.Final (jdk 11)
2. quay.io/wildfly/wildfly:41.0.1.Final-jdk21

---

## Environment Setup & Testing Documentation

### 1. Overview
This setup provides a fully automated Docker Compose environment and Windows scripts to test an in-place, side-by-side migration from **WildFly 20.0.1.Final** (Java 11) to **WildFly 41.0.1.Final** (Java 21) in **Domain Mode** using the **Strangler Fig pattern**.

The environment allows both major versions of WildFly to run concurrently on the same network without port collisions, provides an Ingress Load Balancer with Undertow reverse proxying, and demonstrates dynamic path-based cutover and instant zero-downtime rollback using JBoss CLI.

```
                           +-------------------------------------+
                           |        Ingress Load Balancer        |
                           |   (WildFly Undertow Reverse Proxy)  |
                           |        http://localhost:8080/       |
                           +-------------------+-----------------+
                                               |
                        Default Route (/)      | Migrated Route (/api/v2)
                                               v
            +----------------------------------+----------------------------------+
            |                                                                     |
            v                                                                     v
+-----------------------+                                             +-----------------------+
|    WildFly 20 Domain  |                                             |    WildFly 41 Domain  |
|  (Full-HA, Offset 0)  | ----- Dynamic Undertow Proxy (/api/v2) ---> | (Full-HA, Offset 100) |
| http://localhost:8081 |                                             | http://localhost:8180 |
|  Admin Mgmt: :9990    |                                             |  Admin Mgmt: :10090   |
+-----------------------+                                             +-----------------------+
```

---

### 2. Port Allocation & Topology

| Service | Container Name | Profile / Mode | Internal Port | Host Port | Management Console / Port | Credentials |
|---|---|---|---|---|---|---|
| **Ingress Load Balancer** | `wf-load-balancer` | Standalone Undertow Proxy | `8080` (HTTP)<br>`9990` (Mgmt) | `8080`<br>`9992` | `http://localhost:9992/` | `admin` / `Admin123!` |
| **WildFly 20 Domain** | `wf20-domain` | Domain Mode (`full-ha`, offset `0`) | `8080` (HTTP)<br>`9990` (Mgmt) | `8081`<br>`9990` | `http://localhost:9990/` | `admin` / `Admin123!` |
| **WildFly 41 Domain** | `wf41-domain` | Domain Mode (`full-ha`, offset `100`) | `8180` (HTTP)<br>`10090` (Mgmt) | `8180`<br>`10090` | `http://localhost:10090/` | `admin` / `Admin123!` |

- All services communicate over the internal Docker bridge network `wildfly-net`.
- Ingress requests sent to `http://localhost:8080/` are routed by default to `wf20-domain:8080`.
- Direct access to WildFly 20 is available on `http://localhost:8081/`.
- Direct access to WildFly 41 is available on `http://localhost:8180/`.

---

### 3. Repository & Artifact Layout

```
.
├── .env                                # Environment variables and customizable ports
├── docker-compose.yml                  # Service orchestration with healthchecks and network
├── apps/                               # Test application source and build artifacts
│   ├── wf20-app/                       # Servlet 3.1 sample app (Java 11 / WF20)
│   ├── wf41-app/                       # Jakarta EE 10/11 sample app (Java 21 / WF41)
│   ├── wf20-app.war                    # Packaged WAR for WildFly 20
│   ├── wf41-app.war                    # Packaged WAR for WildFly 41
│   ├── build-apps.ps1                  # PowerShell script to package WARs
│   └── build-apps.bat                  # Batch wrapper to package WARs
├── docker/                             # Dockerfiles and JBoss CLI provisioning scripts
│   ├── load-balancer/                  # Ingress Undertow reverse proxy configuration
│   │   ├── Dockerfile
│   │   └── setup-lb.cli
│   ├── wf20/                           # WildFly 20 Domain configuration & routing scripts
│   │   ├── Dockerfile
│   │   ├── setup-wf20.cli              # HA configuration & outbound socket to WF41
│   │   ├── route-to-wf41.cli           # Switch /api/v2 to WildFly 41
│   │   └── rollback-route.cli          # Rollback /api/v2 to WildFly 20
│   └── wf41/                           # WildFly 41 Domain configuration
│       ├── Dockerfile
│       └── setup-wf41.cli              # HA configuration & port-offset 100
└── scripts/                            # Windows automation & verification scripts
    ├── start-environment.ps1 / .bat    # Builds apps, launches compose, awaits healthy state
    ├── stop-environment.ps1 / .bat     # Stops containers and tears down network
    ├── switch-route.ps1 / .bat         # Activates Strangler cutover for /api/v2 -> WF41
    ├── rollback.ps1 / .bat             # Reverts /api/v2 routing -> WF20 with zero downtime
    ├── test-routing.ps1 / .bat         # Automated HTTP smoke test verifying all endpoints
    └── check-status.ps1 / .bat         # Displays container health and active Undertow routes
```

---

### 4. Strangler Fig Routing Mechanics

The routing cutover and rollback leverage WildFly's embedded **Undertow Reverse Proxy subsystem**:

1. **Outbound Socket Binding & Handler Setup (Pre-configured in WildFly 20):**
   ```cli
   /socket-binding-group=full-ha-sockets/remote-destination-outbound-socket-binding=wf41-outbound:add(host="wf41-domain", port=8180)
   /profile=full-ha/subsystem=undertow/configuration=handler/reverse-proxy=wf41-handler:add()
   /profile=full-ha/subsystem=undertow/configuration=handler/reverse-proxy=wf41-handler/host=wf41-backend:add(outbound-socket-binding="wf41-outbound", scheme="http", instance-id="wf41", path="/")
   ```

2. **Dynamic Cutover (`scripts\switch-route.ps1`):**
   Applies a location mapping on the `default-host` under `full-ha` profile:
   ```cli
   /profile=full-ha/subsystem=undertow/server=default-server/host=default-host/location="\/api\/v2":add(handler="wf41-handler")
   ```
   Traffic sent to `http://localhost:8080/api/v2` is immediately intercepted and proxied to WildFly 41. Unmigrated paths (`/`, `/legacy`) remain served by WildFly 20.

3. **Zero-Downtime Rollback (`scripts\rollback.ps1`):**
   Removes the location mapping and reloads the managed server instances:
   ```cli
   /profile=full-ha/subsystem=undertow/server=default-server/host=default-host/location="\/api\/v2":remove()
   /server-group=other-server-group:reload-servers()
   ```
   Traffic for `http://localhost:8080/api/v2` is instantly restored to the local WildFly 20 application.

---

### 5. Windows Automation Scripts Guide

All scripts are provided as both PowerShell (`.ps1`) and double-clickable Windows Command Prompt / Batch (`.bat`) files.

#### A. Starting the Environment
```powershell
.\scripts\start-environment.ps1
# Or from CMD:
.\scripts\start-environment.bat
```
*What it does:*
- Checks Docker engine availability.
- Packages `wf20-app.war` and `wf41-app.war` if not already built.
- Runs `docker compose up --build -d`.
- Monitors Docker container health until all three containers report `healthy`.
- Prints available URLs and management credentials.

#### B. Testing Routing & Health
```powershell
.\scripts\test-routing.ps1
# Or from CMD:
.\scripts\test-routing.bat
```
*What it does:*
- Tests Ingress Root (`/`), Legacy (`/legacy`), and API v2 (`/api/v2`).
- Tests direct WildFly 20 (`:8081`) and WildFly 41 (`:8180`) endpoints.
- Displays a formatted result table with latency and detected backend versions.

#### C. Switching Route to WildFly 41 (Strangler Fig Cutover)
```powershell
.\scripts\switch-route.ps1
# Or from CMD:
.\scripts\switch-route.bat
```
*What it does:*
- Connects to WildFly 20 Domain Controller via JBoss CLI.
- Adds the Undertow reverse proxy location for `/api/v2` pointing to `wf41-handler`.
- Performs an automated HTTP check against `http://localhost:8080/api/v2` to verify that WildFly 41 handles the request.

#### D. Rolling Back to WildFly 20
```powershell
.\scripts\rollback.ps1
# Or from CMD:
.\scripts\rollback.bat
```
*What it does:*
- Removes the `/api/v2` Undertow location from WildFly 20.
- Reloads the `other-server-group` managed servers.
- Performs an automated HTTP check against `http://localhost:8080/api/v2` to confirm traffic is restored to WildFly 20.

#### E. Checking Environment Status
```powershell
.\scripts\check-status.ps1
# Or from CMD:
.\scripts\check-status.bat
```
*What it does:*
- Reports container runtime and health statuses.
- Queries JBoss CLI to determine whether `/api/v2` is currently proxied to WildFly 41 or handled locally by WildFly 20.
- Previews the response from the ingress endpoint.

#### F. Stopping the Environment
```powershell
.\scripts\stop-environment.ps1
# Or with volume cleanup:
.\scripts\stop-environment.ps1 -Clean
# Or from CMD:
.\scripts\stop-environment.bat
```

---

### 6. Verification Results Walkthrough

#### Step 1: Initial State (All Traffic to WildFly 20)
```text
PS > .\scripts\test-routing.ps1
[PASS] Ingress: Root (/)                -> WildFly 20   (60.1ms)
[PASS] Ingress: Legacy (/legacy)        -> WildFly 20   (42.9ms)
[PASS] Ingress: API v2 (/api/v2)        -> WildFly 20   (40.7ms)
[PASS] Direct WF20: Root (/)            -> WildFly 20   (27.3ms)
[PASS] Direct WF41: Root (/)            -> WildFly 41   (28.3ms)
[PASS] Direct WF41: API v2 (/api/v2)    -> WildFly 41   (42.9ms)
```

#### Step 2: Cutover to WildFly 41 for `/api/v2`
```text
PS > .\scripts\switch-route.ps1
Applying Undertow route configuration via JBoss CLI...
{"outcome" => "success"}
Successfully routed /api/v2 to WildFly 41!
VERIFIED: http://localhost:8080/api/v2 is now served by WildFly 41!

PS > .\scripts\test-routing.ps1
[PASS] Ingress: Root (/)                -> WildFly 20   (53.0ms)
[PASS] Ingress: Legacy (/legacy)        -> WildFly 20   (39.4ms)
[PASS] Ingress: API v2 (/api/v2)        -> WildFly 41   (25.4ms)  <-- Modernized!
[PASS] Direct WF20: Root (/)            -> WildFly 20   (25.2ms)
[PASS] Direct WF41: Root (/)            -> WildFly 41   (25.4ms)
[PASS] Direct WF41: API v2 (/api/v2)    -> WildFly 41   (38.8ms)
```

#### Step 3: Rollback to WildFly 20
```text
PS > .\scripts\rollback.ps1
Removing Undertow /api/v2 reverse-proxy location via JBoss CLI...
{"outcome" => "success"}
Successfully rolled back /api/v2 to WildFly 20!
VERIFIED: http://localhost:8080/api/v2 is now served by WildFly 20!

PS > .\scripts\test-routing.ps1
[PASS] Ingress: Root (/)                -> WildFly 20   (81.6ms)
[PASS] Ingress: Legacy (/legacy)        -> WildFly 20   (82.1ms)
[PASS] Ingress: API v2 (/api/v2)        -> WildFly 20   (49.3ms)  <-- Restored!
[PASS] Direct WF20: Root (/)            -> WildFly 20   (25.8ms)
[PASS] Direct WF41: Root (/)            -> WildFly 41   (31.5ms)
[PASS] Direct WF41: API v2 (/api/v2)    -> WildFly 41   (41.3ms)
```


