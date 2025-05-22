# 🐘 Highly Available Hadoop + HBase Cluster (Docker-based)

This project sets up a **highly available (HA)** Hadoop + HBase cluster using Docker and Docker Compose. It includes:

- 3 Hadoop masters simulating HA NameNodes and ResourceManagers
- 2 HBase HMasters for HBase master failover
- 2 HBase RegionServers with failover support
- Shared network and persistent volumes for inter-container communication and data durability

---

## 📦 Cluster Components

### 🔧 Hadoop Base Image

**Dockerfile (Stage 1)**: Builds a base image with Hadoop and ZooKeeper

- **Ubuntu 24.04**
- **Hadoop 3.3.6**
- **ZooKeeper 3.8.4**
- **Java 8**
- Configured user: `hadoop` with passwordless sudo
- Hadoop and ZooKeeper are placed under `/home/hadoop/packages/`

### 🔧 HBase Extension Image

**Dockerfile (Stage 2)**: Adds HBase to the base image

- **HBase 2.4.9**
- Installs HBase in `/home/hadoop/packages/hbase`
- Uses a custom `hbase-site.xml` and `entrypoint.sh` to control startup

---

## 🧱 Services (from `docker-compose.yml`)

### Hadoop Masters

| Service   | Ports (Web UI) | Role                  | Notes                                          |
|-----------|----------------|-----------------------|------------------------------------------------|
| master1   | 9871, 8071     | NameNode / RM         | Includes healthcheck for HA state             |
| master2   | 9872, 8072     | Standby NameNode / RM | Joins HA group                                 |
| master3   | 9873, 8073     | Standby NameNode / RM | Joins HA group                                 |

> 🧠 Healthcheck: Ensures both HDFS and YARN HA are in expected states (`active` or `standby`) before dependent services like HBase start.

### HBase Masters

| Service   | Ports (Web UI) | Role           | Failover |
|-----------|----------------|----------------|----------|
| hmaster1  | 16001, 16011    | Active/Standby | ✅       |
| hmaster2  | 16002, 16012    | Standby        | ✅       |

> Uses ZooKeeper for coordination and failover. Only one HMaster will be active at a time.

### HBase RegionServers

| Service     | Volume             | Notes                          |
|-------------|--------------------|--------------------------------|
| rs_worker1  | `rs_worker1_data`  | Primary RegionServer           |
| rs_worker2  | `rs_worker2_data`  | Failover or load-balanced node |

---

## 🔄 Failover Behavior

### 🔸 HMaster Failover

## 🛡️ HMaster Failover

HBase is designed with high availability in mind. Only **one HMaster is active** at a time; the others remain in **standby mode**.

- If `hmaster1` fails  **`hmaster2` automatically becomes the active master**.
- **ZooKeeper** handles the failover and coordinates the transition between masters.
- The system continues to operate without downtime as the standby takes control.


You can verify the failover by:

- Visiting the **HBase Master UI** on:
  - `http://localhost:16011` (for hmaster1)
  - `http://localhost:16012` (for hmaster2)
- HBase Shell:
   Run inside an HBase container:
   ```
     hbase shell
     status 'datailed'
   ```




