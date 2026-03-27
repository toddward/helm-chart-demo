# Helm Chart Demo — Participant Guide

## Instructor Pre-Flight Checklist

- [ ] Confirm participants have `oc` CLI installed and can reach the OpenShift cluster
- [ ] Confirm `helm` CLI (v3+) is installed on participant workstations
- [ ] Verify the Red Hat registry image is pullable from the cluster:
  ```
  oc run test-pull --image=registry.access.redhat.com/ubi9/httpd-24:latest --restart=Never -o yaml --dry-run=client
  ```
- [ ] Ensure each participant has credentials to log into the OpenShift cluster
- [ ] Clone or distribute this repository to all participants

---

## Step 0 — Log In to OpenShift

Each participant logs into the cluster with their own credentials:

```bash
oc login <cluster-api-url> -u <your-username> -p <your-password>
```

> **Tip:** Your instructor will provide the cluster API URL. You can also copy the login command from the OpenShift web console under your username → **Copy login command**.

Verify you're logged in:

```bash
oc whoami
```

---

## Step 1 — Create Your Own Project

Create a personal namespace to keep your work isolated:

```bash
oc new-project <your-firstname>-helm-demo
```

Confirm you're in the right project:

```bash
oc project
```

---

## Step 2 — Explore the Helm Chart

Take a look at the chart structure before deploying:

```
charts/httpd-demo/
├── Chart.yaml          # Chart metadata (name, version, description)
├── values.yaml         # Default configuration values
└── templates/
    ├── _helpers.tpl    # Reusable template snippets
    ├── deployment.yaml # Pod deployment spec
    ├── service.yaml    # ClusterIP service
    └── route.yaml      # OpenShift Route (exposes the app externally)
```

Open `values.yaml` and review the defaults:

```bash
cat charts/httpd-demo/values.yaml
```

Notice the key values you can override: `replicaCount`, `image.repository`, `image.tag`, `route.enabled`, and `resources`.

---

## Step 3 — Understand Version Control in Helm

Every Helm chart carries its own version in `Chart.yaml`. Open it and look at the key fields:

```bash
cat charts/httpd-demo/Chart.yaml
```

Key fields:

- **`version`** — The chart version (follows SemVer). Bump this every time you change the chart. Store your charts in Git to track changes in PRs and tag releases.
- **`appVersion`** — The version of the application being deployed (e.g., the httpd image tag). This evolves independently from the chart version.

Because charts are version-controlled artifacts, you always know *which* chart is running in *which* environment — and can audit who changed what and when.

---

## Step 4 — Understand Templating

Helm templates aren't static YAML — they use Go's template engine to inject values at render time. Open one of the templates and look at the syntax:

```bash
cat charts/httpd-demo/templates/deployment.yaml
```

Key constructs to notice:

- **Value injection:** `{{ .Values.replicaCount }}` pulls from `values.yaml`
- **Built-in objects:** `{{ .Release.Name }}` inserts the release name you give at install time
- **Conditionals:** `{{- if .Values.route.enabled }}` — the Route template only renders when this is `true`
- **Functions:** `{{ toYaml .Values.resources | nindent 12 }}` renders nested YAML cleanly

This means the same chart works on both OpenShift (route enabled) and vanilla Kubernetes (route disabled, use Ingress instead).

---

## Step 5 — Understand the Values Hierarchy

Helm resolves values in a specific priority order — lowest to highest:

1. **`values.yaml`** — the chart's built-in defaults
2. **`-f values-prod.yaml`** — a custom values file that overrides defaults
3. **`--set key=value`** — CLI overrides that trump everything

This layering is what makes a single chart reusable across environments. The same chart, different values files: `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml`.

Example:

```bash
helm upgrade my-httpd ./charts/httpd-demo \
  -f values-prod.yaml \
  --set image.tag=2.4-ubi9
```

---

## Step 6 — Preview Before You Deploy (Dry Run)

Helm lets you render and validate charts locally without touching the cluster:

```bash
# Render templates locally — see exactly what Kubernetes will receive
helm template my-httpd ./charts/httpd-demo
```

```bash
# Render with overrides to test specific configurations
helm template my-httpd ./charts/httpd-demo --set replicaCount=5
```

```bash
# Lint the chart for structural issues
helm lint ./charts/httpd-demo
```

```bash
# Dry-run against the cluster (validates with the API server)
helm install my-httpd ./charts/httpd-demo --dry-run
```

> **Tip:** Integrate `helm template` and `helm lint` into your CI pipeline to catch issues before they hit the cluster.

---

## Step 7 — Install the Helm Chart

Deploy the chart with the defaults:

```bash
helm install my-httpd ./charts/httpd-demo
```

You should see output confirming the release was created.

Check the status:

```bash
helm status my-httpd
```

---

## Step 8 — Verify the Deployment

Watch the pod come up:

```bash
oc get pods -w
```

> Press `Ctrl+C` once the pod shows `Running` and `1/1` ready.

Check the service and route were created:

```bash
oc get svc
oc get route
```

---

## Step 9 — Access the Application

Grab your route URL:

```bash
oc get route my-httpd-httpd -o jsonpath='{.spec.host}{"\n"}'
```

Open that URL in your browser (it will be HTTPS via edge termination). You should see the **Apache HTTP Server Test Page** — proof that your application is running on OpenShift, deployed entirely via a Helm chart.

You can also verify from the command line:

```bash
curl -kL https://$(oc get route my-httpd-httpd -o jsonpath='{.spec.host}')
```

---

## Step 10 — Override Values with `--set`

This is where Helm shines. Scale up your deployment without touching any files:

```bash
helm upgrade my-httpd ./charts/httpd-demo --set replicaCount=3
```

Watch the new replicas appear:

```bash
oc get pods -w
```

> Press `Ctrl+C` once all three pods show `Running`.

You can also chain multiple overrides:

```bash
helm upgrade my-httpd ./charts/httpd-demo \
  --set replicaCount=2 \
  --set resources.limits.memory=512Mi
```

---

## Step 11 — View Release History

Helm tracks every upgrade as a revision:

```bash
helm history my-httpd
```

You can roll back to any previous revision:

```bash
helm rollback my-httpd 1
```

Verify the rollback took effect:

```bash
oc get pods
helm status my-httpd
```

---

## Step 12 — Cleanup

Uninstall the Helm release (removes all Kubernetes resources it created):

```bash
helm uninstall my-httpd
```

Verify everything is cleaned up:

```bash
oc get all
```

Delete your project:

```bash
oc delete project <your-firstname>-helm-demo
```

---

## Bonus — Helm Repositories

Charts aren't just local folders — they can be packaged and published to repositories for team-wide reuse:

```bash
# Add a public chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for available charts
helm search repo nginx

# Pull a chart from an OCI registry
helm pull oci://registry.example.com/charts/my-app --version 1.2.0
```

Discover thousands of community charts at [Artifact Hub](https://artifacthub.io). You can also host charts in your own OCI registry (Quay, Nexus, Harbor) and share them across projects.

---

## Recap

In this demo you:

1. Logged into an OpenShift cluster with your own credentials
2. Created a personal project/namespace
3. Explored a Helm chart's structure and default values
4. Learned how charts are **version-controlled artifacts** with SemVer and Git
5. Understood **Go templating** — value injection, conditionals, and built-in objects
6. Learned how the **values hierarchy** cascades from defaults to overrides
7. Used **`helm template`** and **`helm lint`** to preview and validate before deploying
8. Deployed an application with `helm install`
9. Verified the running app via its OpenShift Route
10. Used `--set` to override values and scale the deployment
11. Reviewed release history and performed a rollback
12. Cleaned everything up with `helm uninstall`

**Estimated time:** ~20–25 minutes per participant.
