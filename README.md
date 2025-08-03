# 🔧 VM Health Check with Puppet Bolt

This project uses [Puppet Bolt](https://puppet.com/docs/bolt/latest/bolt.html) to perform **health checks** on virtual machines. It provides a lightweight, agentless way to monitor key system parameters like CPU usage, memory usage, disk availability, and uptime.

## 📁 Project Structure
.
├── plans/
│ └── health_check.pp # Bolt plan that performs system health checks
├── tasks/
│ └── get_health.sh # Bash script run on target VMs
├── inventory.yaml # Defines your target VMs
├── bolt-project.yaml # Bolt project config
└── README.md # You're here


## ✅ Features

- Checks for:
  - CPU usage
  - Memory usage
  - Disk usage
  - System uptime
- Works agentlessly over SSH
- Easy to plug into CI/CD or cron jobs

---

## 🚀 Getting Started

### 1. Prerequisites

- [Install Puppet Bolt](https://puppet.com/docs/bolt/latest/bolt_installing.html)
- SSH access to your target Linux VMs
- Bolt installed locally

### 2. Setup Your Inventory

Edit `inventory.yaml`:

```yaml
targets:
  - name: vm1
    uri: 192.168.0.101
    config:
      transport: ssh
      ssh:
        user: ubuntu
        private-key: ~/.ssh/id_rsa
****

bolt plan run health_check -i inventory.yaml
bolt task run get_health -t vm1

Sample Output
json
Copy
Edit
{
  "cpu": "12.5%",
  "memory": "64% used",
  "disk": "78% used on /",
  "uptime": "1 day, 3:45"
}
