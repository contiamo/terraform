# Contiamo Terraform Modules

A monorepo of reusable Terraform modules maintained by Contiamo. Each top-level directory is an independently-versioned module — see the auto-generated wiki for the full reference of every module.

> 📚 **[Browse all modules in the wiki →](https://github.com/contiamo/terraform/wiki)**
>
> The wiki is the canonical source of truth: it lists every module with its latest tag, an auto-generated input/output table, a usage example pinned to the current version, and a per-module changelog. Updated automatically on every release.

## Referencing a module

Each module has its own tag of the form `<module>/v<X.Y.Z>` (e.g. `slack/v1.4.0`). To consume a module from another Terraform project, pin the `ref` to a per-module tag:

```hcl
module "slack" {
  source = "github.com/contiamo/terraform?ref=slack/v1.0.0"

  channel_name = "..."
}
```

Notes:

- **Do not include a `//<module>` subdir** in the `source`. The published tag tree contains the module's files at the root, so go-getter would fail with `subdir "<module>" not found`.
- The wiki shows the explicit `git::https://github.com/contiamo/terraform.git?ref=<module>/v<X.Y.Z>` form. Both formats are equivalent — the shorthand above is the same module fetched via the same tag.
- For private access over SSH, swap the URL prefix: `git::ssh://git@github.com/contiamo/terraform.git?ref=<module>/v<X.Y.Z>`.

## Available modules

| Module | Purpose |
|---|---|
| [azure-openai](./azure-openai) | Azure OpenAI Cognitive Services with private endpoints |
| [datahub](./datahub) | DataHub metadata platform deployment via Helm |
| [ecr-pull-helper](./ecr-pull-helper) | ECR pull-through credential refresher for non-AWS clusters |
| [elasticsearch](./elasticsearch) | Elasticsearch cluster setup |
| [envoy-gateway](./envoy-gateway) | Envoy Gateway control plane + listener config |
| [external-dns](./external-dns) | external-dns deployment |
| [gateway-api-crds](./gateway-api-crds) | Kubernetes Gateway API CRD bundle |
| [github](./github) | GitHub repository creation with Contiamo standard settings |
| [langfuse](./langfuse) | Langfuse self-hosted deployment |
| [monitoring](./monitoring) | Monitoring stack (Prometheus, Grafana, Loki, Alloy) |
| [mwaa](./mwaa) | Amazon Managed Workflows for Apache Airflow |
| [onepass](./onepass) | 1Password integration helpers |
| [onepassword-connect](./onepassword-connect) | 1Password Connect operator deployment |
| [onepassword-secret](./onepassword-secret) | Wraps `onepassword_item` data lookups for use in modules |
| [slack](./slack) | Slack channel creation and user management |
| [tailscale](./tailscale) | Tailscale operator + identity setup |
| [whitesky](./whitesky) | Whitesky service configuration |

## Release process

Releases are fully automated by [techpivot/terraform-module-releaser](https://github.com/techpivot/terraform-module-releaser):

- **The PR is the release.** Open a PR that touches one or more modules; the action posts a Release Plan comment listing exactly which modules will bump and to what version. On merge, tags and GitHub Releases are created within ~30 seconds.
- **Conventional commits drive the bump.** `feat: …` → minor, `fix: …` / `chore: …` / `docs: …` → patch, `feat!: …` or a `BREAKING CHANGE:` footer → major. Use the conventional commit's `(scope)` if you like, but **module routing is by changed file paths**, not by scope — a commit only bumps the modules whose `.tf` files it touched.
- **README, test, and docs changes don't trigger releases.** The action's `module-change-exclude-patterns` ignores `*.md`, `tests/**`, and `*.tftest.hcl` by default.
- **Bundling multiple modules in one PR** bumps all of them in lockstep on merge — useful when a change cuts across modules.

## Conventions

- New modules go in a top-level directory named after the module.
- Every module should have a `README.md` with a usage example pinned to the canonical source format above.
- PR titles must follow the conventional commits format (enforced by the `Conventional commit titles / validate` workflow).
- Code owners: `@contiamo/ops`.
