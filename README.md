# Helm Chart Demo

Materials for a hands-on Helm chart demo on OpenShift using the Red Hat UBI9 Apache HTTPD image.

## Contents

| File | Description |
|------|-------------|
| `docs/Demo_Directions.md` | Step-by-step participant guide — deploy an Apache HTTPD application on OpenShift using Helm |
| `charts/httpd-demo/` | The Helm chart (Deployment, Service, Route) |

## Demo at a Glance

Participants log into an OpenShift cluster with their own credentials, create a personal project, and deploy a running Apache HTTPD application entirely through Helm. The demo covers:

- Logging into OpenShift with `oc login`
- Creating a personal project/namespace
- Exploring the Helm chart structure (`Chart.yaml`, `values.yaml`, templates)
- Installing the chart with `helm install`
- Verifying the running application via its OpenShift Route
- Overriding values with `--set` (scaling replicas, adjusting resources)
- Reviewing release history and performing rollbacks
- Cleanup with `helm uninstall`

**Estimated time:** ~15 minutes per participant.

## Prerequisites

- **oc** CLI (logged into the target OpenShift cluster)
- **helm** CLI (v3+)
- Access to pull from `registry.access.redhat.com` (no authentication required)

## Getting Started

Open `docs/Demo_Directions.md` and follow the steps in order. An instructor pre-flight checklist is included at the top of the guide.
