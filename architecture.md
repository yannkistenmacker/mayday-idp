# Architecture

This document describes how the **mayday-idp** lab is structured and how a change
flows from source code to a running deployment via GitOps.

## Layers

| Layer | Path | Role |
|-------|------|------|
| Bootstrap | `env-up.sh`, `env-up2.sh` | Provision the cluster + platform controllers (k3s, kubectl, Helm, Argo CD, Sealed Secrets, Argo Rollouts, Traefik). |
| Delivery (GitOps) | `argocd/` | Argo CD `Application`s that reconcile Git → cluster. |
| App — portal | `charts/backstage/` | Helm chart for the Backstage portal (Argo Rollout, Service, Ingress, ConfigMap). |
| App — database | `postgresql/` | Postgres backing store for Backstage. |
| Secrets | `scripts/seal-backstage-secret.sh` → `charts/backstage/templates/sealedsecret.yaml` | Encrypted `backstage-secrets` via Sealed Secrets (no plaintext in Git). |
| CI | `.github/workflows/build.yaml` | Build & push the Backstage image, then open a PR bumping `values.image.tag`. |
| Self-service | `app-template/` | Base Helm chart used by Backstage software templates to scaffold new apps (STG/PRD values). |
| Source | `backstage/` | Backstage monorepo (portal source; `packages/backend/Dockerfile` is what CI builds). |

## Platform components (bootstrap)

```mermaid
flowchart TB
    subgraph VM["VM (k3s node)"]
        k3s["k3s (traefik bundled = disabled)"]
        argocd["Argo CD\n(NodePort 30080)"]
        rollouts["Argo Rollouts\ncontroller"]
        sealed["Sealed Secrets\ncontroller (kube-system)"]
        traefik["Traefik\n(ingress controller, LoadBalancer)"]
    end
    envup["env-up.sh"] --> k3s
    envup --> argocd
    envup --> rollouts
    envup --> sealed
    envup --> traefik
```

## GitOps delivery

Argo CD watches this repo and reconciles two applications into the `backstage` namespace:

```mermaid
flowchart LR
    repo["Git repo\nmayday-idp (main)"]
    subgraph argo["Argo CD"]
        appPg["Application: postgres\npath: postgresql/"]
        appBs["Application: backstage\npath: charts/backstage/"]
    end
    repo --> appPg
    repo --> appBs
    appPg --> pg["Postgres\n(Deployment + Service + PVC + Secret)"]
    appBs --> ro["Argo Rollout: backstage\n(canary 20% -> 50%)"]
    ro --> pg
    sealed["SealedSecret\n(charts/backstage/templates)"] --> ssctl["sealed-secrets-controller"]
    ssctl --> secret["Secret: backstage-secrets"]
    ro --> secret
    traefik["Traefik Ingress\nbackstage.local"] --> ro
```

## End-to-end change flow

```mermaid
flowchart TB
    dev["Developer pushes to main\n(backstage/**)"]
    ci["CI: build.yaml"]
    img["Image pushed\nkisten/backstage:SHA"]
    pr["CI opens PR\nbump values.image.tag"]
    merge["Human reviews + merges PR\n(main protected by ruleset)"]
    sync["Argo CD detects new values.yaml"]
    deploy["Argo Rollouts canary\ndeploys new image"]
    dev --> ci --> img --> pr --> merge --> sync --> deploy
```

> The bump PR only touches `charts/backstage/values.yaml`, which is outside the
> build workflow's `paths` filter (`backstage/**`, `.github/workflows/*`), so
> merging it does not re-trigger the build — no deploy loop.

## Access

- **Argo CD UI:** `http://<node-ip>:30080` (Service type NodePort).
- **Backstage:** `http://backstage.local` via the Traefik Ingress
  (add `<node-ip> backstage.local` to `/etc/hosts`).

## Bootstrap order

1. `env-up.sh` — cluster + controllers (Argo CD, Sealed Secrets, Argo Rollouts, Traefik).
2. Rotate the GitHub credentials, then `scripts/seal-backstage-secret.sh` to create the `SealedSecret`.
3. Apply `argocd/postgres-application.yaml` (database first — Backstage depends on it).
4. Apply `argocd/backstage-application.yaml`.
5. Add the `/etc/hosts` entry and set the GitHub App callback to
   `http://backstage.local/api/auth/github/handler/frame`.
