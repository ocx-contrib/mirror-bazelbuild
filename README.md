# mirror-bazelbuild

OCX mirror for [Bazelisk](https://github.com/bazelbuild/bazelisk).
Publishes GitHub releases to `ghcr.io/ocx-contrib/bazelbuild/bazelisk` with
cascade tags after a smoke test per `(version, platform)`, then announces the
result into the OCX index as `ocx.sh/bazelbuild/bazelisk`.

Bazelisk is the Bazel version launcher — it reads `.bazelversion` (or the
`USE_BAZEL_VERSION` env var) and automatically downloads + invokes the correct
Bazel release. Users typically symlink or rename `bazelisk` to `bazel` so it
is transparent.

## Migration status — not yet installable

This repo is the pilot for the ocx.sh → GHCR move, and the move is unfinished.
`ocx install` does **not** work yet. As of 2026-07-26, after
[run 30221243658](https://github.com/ocx-contrib/mirror-bazelbuild/actions/runs/30221243658):

| | State |
|---|---|
| Published | 20 of 25 `(version, platform)` pairs — 1.26.0, 1.27.0, 1.28.0, 1.28.1, 1.29.0 on linux/amd64, linux/arm64, darwin/amd64, darwin/arm64 |
| `windows/amd64` | Blocked, all 5 versions. GHCR caps a monolithic blob upload at 4 MiB and ocx pushes each layer in one request; only the windows bundle crosses it. Needs chunked upload in `ocx_lib`. |
| Package visibility | **Private.** GHCR makes a first-published package private, and a linked package inherits its repository's access *permissions*, not its visibility — a public repo does not make it public. Flipping it is UI-only and needs `write:packages`. |
| Index announce | Failing with `unclaimed namespace … exit 79`. Expected: the claim PR [ocx-sh/index#80](https://github.com/ocx-sh/index/pull/80) is open and cannot go green until the package is public, because `schema-validate-pr` probes it anonymously. |

Order out: flip visibility → #80 goes green and merges → re-run to announce
(or catch up the already-published tags with `ocx package announce --tags`).

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
ocx install ocx.sh/bazelbuild/bazelisk
```

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
