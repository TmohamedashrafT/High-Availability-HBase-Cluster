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

### 🛡️ HMaster Failover

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
## 📸 Screenshots
### Before Failover:
![image](https://github.com/TmohamedashrafT/High-Availability-HBase-Cluster/blob/main/readme_image/Before_Failover.png)
### hmaster2 is active; hmaster1 is standby.

### After Failover (hmaster1 stopped)
![image](https://github.com/TmohamedashrafT/High-Availability-HBase-Cluster/blob/main/readme_image/After_Failover.png)
### hmaster1 becomes the active master.

### 📦 RegionServer Failover

HBase data is divided into **Regions**, which are managed by **RegionServers**. HBase supports automatic recovery when a RegionServer fails.

#### 🔁 How Region Failover Works

1. **Failure Detection**:  
   - When a RegionServer fails, its regions are marked as **unassigned**.
   
2. **Recovery Process**:  
  -  When a RegionServer fails, its regions are marked unassigned.
  -  The active HMaster detects the failure and reassigns the regions to healthy RegionServers.
  -  When the failed RegionServer is restarted, HBase can rebalance the regions automatically. 

---

#### 🧪 Verifying Region Failover

### Before Failure
- Both RegionServers are **active** and running.  
- Regions are **evenly distributed** across them.  

### After Failure
- The failed RegionServer is marked as **dead**.  
- Its regions are **reassigned** to the remaining healthy RegionServer.  

### After Recovery and Load Balancing
- Restart the failed RegionServer:
- HBase rebalances and redistributes some regions back to it.

## 📸 Screenshots
### Before RegionServer Failure
![image](https://github.com/TmohamedashrafT/High-Availability-HBase-Cluster/blob/main/readme_image/RS_Before_Failover.png)
### Both RegionServers are healthy and balanced.

### After rs_worker1 Fails
![image](https://github.com/TmohamedashrafT/High-Availability-HBase-Cluster/blob/main/readme_image/RS_After_Failover.png)
### Regions are reassigned to rs_worker2.

### After Restarting rs_worker1 and Load Balancing
![image](https://github.com/TmohamedashrafT/High-Availability-HBase-Cluster/blob/main/readme_image/RS_After_load_balancing.png)
### Some regions are migrated back to rs_worker1.











