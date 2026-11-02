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

### 6.  Dockoer images to use
1.  jboss/wildfly:20.0.1.Final (jdk 11)
2.  quay.io/wildfly/wildfly:41.0.1.Final-jdk21

