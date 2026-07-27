# mirror-bazelbuild

OCX mirror for [Bazelisk](https://github.com/bazelbuild/bazelisk).
Publishes GitHub releases to `ghcr.io/ocx-contrib/bazelbuild/bazelisk` with
cascade tags after a smoke test per `(version, platform)`, then announces the
result into the OCX index as `ocx.sh/bazelbuild/bazelisk`.

Bazelisk is the Bazel version launcher — it reads `.bazelversion` (or the
`USE_BAZEL_VERSION` env var) and automatically downloads + invokes the correct
Bazel release. Users typically symlink or rename `bazelisk` to `bazel` so it
is transparent.

## Migration status

This repo is the pilot for the ocx.sh → GHCR move, and the move is **done**.
As of 2026-07-27, after
[run 30241738383](https://github.com/ocx-contrib/mirror-bazelbuild/actions/runs/30241738383):

| | State |
|---|---|
| Published | **25 of 25** `(version, platform)` pairs — 1.26.0, 1.27.0, 1.28.0, 1.28.1, 1.29.0 across linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64. Rolling aliases (`latest`, `1`, `1.29`, …) all carry the full platform set. |
| Package visibility | Public. Verified anonymously with an empty `DOCKER_CONFIG`. |
| Index name `ocx.sh/bazelbuild/bazelisk` | **Resolves.** [#80](https://github.com/ocx-sh/index/pull/80) claimed the root, [#81](https://github.com/ocx-sh/index/pull/81) curated 11 tags into it. |
| Index announce | Working. It first failed with `404 … /ocx-contrib/index/git/blobs` — GitHub masking an unauthorised *write* as not-found — which was the ocx-bot GitHub App lacking write on the fork, not the PAT's scopes. A PAT can never exceed the App's own repo permission. |

Proved end to end from a scratch `OCX_HOME`, no credentials:

```
ocx package inspect ocx.sh/bazelbuild/bazelisk
  → ocx.sh/bazelbuild/bazelisk:latest@sha256:a6219dce910a84696f7e38fb6e0c27ad7c557869b455cda5fcc67091c1d4997e
    candidates: darwin/amd64, darwin/arm64, linux/amd64, linux/arm64, windows/amd64
ocx --global add ocx.sh/bazelbuild/bazelisk
  → bazelisk  default  sha256:1736f19f619f6ad3d64e37bc214695222884145f25cef13fc0b28338e951b47c
bazelisk version
  → Bazelisk version: v1.29.0
```

**Caveat — which cli you need.** Resolving `ocx.sh/bazelbuild/bazelisk` with
*no config at all* needs a build carrying the compiled-in default index tier,
which is on `announce/integration` and unreleased. Today's released cli needs
an explicit `[registries."ocx.sh"] index = "https://index.ocx.sh"` in
`$OCX_HOME/config.toml`, or the `ghcr.io/…` path below, which needs neither.

**Telling "absent" from "private" over anonymous HTTP.** GHCR answers an
anonymous read of a package that does not exist with `403 DENIED` — it will
not confirm non-existence to a caller it cannot authorise — but one that
exists and is private with `401 UNAUTHORIZED: authentication required`. The
two states are therefore separable without credentials, which is what a
fleet-wide migration check needs to distinguish "not published yet" from
"published but not public". Authenticated, a missing package returns
`404 NAME_UNKNOWN` as normal, which is why the `discover` job logs in.

## Install with OCX

```sh
ocx --global add ghcr.io/ocx-contrib/bazelbuild/bazelisk
```

No credentials needed — the package is public, and this path works on every
cli. The shorter `ocx --global add ocx.sh/bazelbuild/bazelisk` also resolves,
subject to the cli caveat in Migration status above.

This places `bazelisk` (and `bazelisk.exe` on Windows) on your `PATH`. To use
it as your default `bazel` command, create a symlink:

```sh
# Linux/macOS
ln -s "$(which bazelisk)" "$(dirname "$(which bazelisk)")/bazel"
# Windows (PowerShell, run as Admin)
New-Item -ItemType SymbolicLink -Path "$env:PATH_ENTRY\bazel.exe" -Target (Get-Command bazelisk.exe).Source
```

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror.yml` | hand | `ocx-mirror pipeline generate ci` |
| `tests/smoke.star` | hand | — |
| `metadata.json`, `CATALOG.md`, `logo.*` | hand | — |
| `.github/workflows/*.yml` | generated | re-run when `mirror.yml` changes |

CI fails on drift via `ocx-mirror pipeline generate ci --check`.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from `ocx-contrib/index` |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

The GHCR push uses the run's own `GITHUB_TOKEN` (`permissions: packages: write`),
so it needs no registry secret. `OCX_MIRROR_REGISTRY_*` stays pointed at `ocx.sh`
for the other mirrors and is not read here.

(Inherited from the `ocx-contrib` org with visibility ALL.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of
scope; see [`NOTICE.md`](NOTICE.md).
