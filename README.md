# Ansible Kubernetes Deployment on OpenStack

## Project Overview
This project provides an automated solution to deploy a **Kubernetes cluster** on a private cloud using **OpenStack** and **Ansible**.  

It provisions a cluster composed of **1 master node and 2 worker nodes**, and integrates a **monitoring stack (Prometheus & Grafana)** for observability.  

The infrastructure is fully automated and designed for deploying and managing **containerized applications** in a scalable and reproducible environment.

---

## Key Features
- Automated Kubernetes cluster deployment using **Ansible roles**
- Provisioning on **OpenStack private cloud infrastructure**
- Cluster architecture: **1 master node + 2 worker nodes**
- Monitoring setup with **Prometheus and Grafana**
- Modular and reusable Ansible playbooks
- Ready environment for deploying containerized applications
- Scalable and reproducible infrastructure setup

---

## Architecture Overview
- OpenStack instances are used as nodes:
  - 1 Master Node
  - 2 Worker Nodes  
- Kubernetes is installed and configured via Ansible  
- Monitoring stack is deployed on the cluster  
- Applications run inside **containers within Kubernetes pods**

---


---

## Technologies Used
- **Kubernetes** – Container orchestration  
- **Ansible** – Automation & configuration management  
- **OpenStack** – Private cloud infrastructure  
- **Docker** – Container runtime  
- **Prometheus** – Monitoring & metrics collection  
- **Grafana** – Data visualization and dashboards  

---

## Prerequisites
- OpenStack environment with running instances  
- SSH access to all nodes  
- Ansible installed on control machine  
- Python installed on remote nodes  
- Kubernetes dependencies (automated via Ansible roles)  

