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

This repo is the pilot for the ocx.sh → GHCR move. The registry side is done;
the index side is not. As of 2026-07-27, after
[run 30241738383](https://github.com/ocx-contrib/mirror-bazelbuild/actions/runs/30241738383):

| | State |
|---|---|
| Published | **25 of 25** `(version, platform)` pairs — 1.26.0, 1.27.0, 1.28.0, 1.28.1, 1.29.0 across linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64. Rolling aliases (`latest`, `1`, `1.29`, …) all carry the full platform set. |
| Package visibility | Public. Verified anonymously with an empty `DOCKER_CONFIG`: all five versions list five platforms each, and `bazelisk version` runs from a credential-free pull. |
| Index name `ocx.sh/bazelbuild/bazelisk` | **Not resolvable yet.** The claim [ocx-sh/index#80](https://github.com/ocx-sh/index/pull/80) is merged, so the root exists — but its `tags` map is still empty because the announce has not landed one. Install from the GHCR path below until it does. |
| Index announce | Failing: `forge returned HTTP status 404 for https://api.github.com/repos/ocx-contrib/index/git/blobs`. The fork exists; GitHub answers an unauthorised *write* with 404 rather than 403, so this is `OCX_ANNOUNCE_TOKEN` lacking write access to `ocx-contrib/index`. A token-scope fix, not a code one. |

Once the token can write the fork, one re-run announces; the already-published
tags can also be caught up with `ocx package announce --tags`.

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

No credentials needed — the package is public. The shorter
`ocx --global add ocx.sh/bazelbuild/bazelisk` starts working once the index
announce lands (see Migration status).

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
