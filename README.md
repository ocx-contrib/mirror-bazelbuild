# mirror-bazelisk

OCX mirror for [Bazelisk](https://github.com/bazelbuild/bazelisk).
Publishes GitHub releases to `ocx.sh/bazelisk` with cascade tags after a
smoke test per `(version, platform)`.

Bazelisk is the Bazel version launcher — it reads `.bazelversion` (or the
`USE_BAZEL_VERSION` env var) and automatically downloads + invokes the correct
Bazel release. Users typically symlink or rename `bazelisk` to `bazel` so it
is transparent.

## Install with OCX

```sh
ocx install ocx.sh/bazelisk
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
| `OCX_MIRROR_REGISTRY_TOKEN` + `OCX_MIRROR_REGISTRY_USER` | `ocx package push` to `ocx.sh` |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of
scope; see [`NOTICE.md`](NOTICE.md).
