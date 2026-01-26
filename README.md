# mayday-idp
Platform Engineering lab project focused on GitOps and developer self-service.

# 🧪 Laboratory IDP (Internal Developer Platform)

## 📌 Overview

This repository represents a **laboratory Internal Developer Platform (IDP)** created to **standardize, automate, and scale** the creation and management of Kubernetes applications.

The main goal is to provide a **self-service developer experience**, reducing operational friction while ensuring **consistency across environments** (staging and production), following Platform Engineering and DevOps best practices.

This is an **experimental/lab project**, but designed with a **real-world, enterprise mindset**.

---

## 🎯 IDP Goals

* Standardize Kubernetes application creation
* Reduce manual work and platform team dependency
* Ensure consistency between **STG** and **PRD**
* Simplify onboarding of new applications
* Apply modern GitOps practices
* Serve as a continuous learning and evolution platform

---

## 🧩 Core Components

The IDP is composed of the following pillars:

### 🔹 Kubernetes

The base runtime environment for applications, running in a local laboratory cluster.

### 🔹 Helm

Responsible for:

* Standardized Kubernetes resource templates
* Clear separation between logic and configuration
* Chart reuse and versioning

Each application is created from a **base Helm Chart**, with specific values for **staging** and **production**.

### 🔹 Backstage

Acts as the **developer portal**, providing:

* Application creation via templates
* Standardized metadata
* Centralized visibility of services

Backstage is the entry point for the IDP self-service experience.

### 🔹 Argo CD

Responsible for:

* GitOps workflows
* Declarative synchronization between Git and Kubernetes
* Automated deployments to STG and PRD

Argo CD ensures the cluster state always reflects what is versioned in Git.

---

## 🧱 Standardization Concept

Every application created through the IDP starts with:

* **Staging** and **Production** environments
* Standardized Kubernetes resources (Deployment, Service, Ingress, etc.)
* Predefined rollout strategies
* Baseline observability and reliability practices

This approach minimizes repetitive decisions and configuration errors.

---

## 🔄 Application Creation Flow

1. A "client" (developer or team) requests a new application
2. Backstage generates the project skeleton from a template
3. The application repository includes:

   * Base Helm Chart
   * STG and PRD values files
4. Argo CD detects the changes
5. The application is automatically deployed to the cluster

No direct manual interaction with the cluster is required.

---

## 🧪 Laboratory Environment

This IDP runs in a local lab environment using:

* Docker
* kind (Kubernetes in Docker)

The goal is to simulate **real platform scenarios** with low cost and high flexibility for experimentation.

---

## 📚 Project Status

* 🔧 Under development
* 🧪 Educational and experimental usage
* 🚀 Continuously evolving based on best practices

---

## 🧠 Motivation

This project reflects a natural evolution of studies and hands-on practice in:

* Platform Engineering
* DevOps
* SRE
* GitOps

Beyond being a technical lab, the IDP also serves as a **portfolio asset**, demonstrating platform design skills — not just tool usage.

---

## 🔮 Next Steps (High Level)

* Evolve Backstage templates
* Refine base Helm Charts
* Improve deployment strategies
* Add policies and validations
* Enhance developer experience

---

## 📎 Final Notes

This repository is **not just about tools**, but about **architecture, standardization, and developer experience**.

It provides a solid foundation for future evolution, whether for advanced studies or real corporate use cases.
