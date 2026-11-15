---
title: iBazel
description: File watcher for Bazel — rebuilds, retests or reruns your targets whenever a source file they depend on changes
keywords: ibazel,bazel,bazel-watcher,watch,file-watcher,live-reload,bazelbuild
---

# iBazel

iBazel watches the source files behind the Bazel targets you name and re-runs
`bazel build`, `test` or `run` whenever one changes — a tight edit-build-test
loop for Bazel workspaces. For `run` targets it restarts the binary, and it
supports live reload for web development.

## What's included

- **ibazel** — the single static binary. It drives an existing `bazel` (or
  `bazelisk`) from your `PATH`; it does not bundle Bazel.

## Usage

```sh
ibazel test //path/to/pkg/...
ibazel run //path/to/pkg:server -- --flag-for-your-binary
```

Pass `-bazel_path=<bazel>` to use a specific Bazel binary. Bazel itself must be
installed separately.

## Links

Apache-2.0 licensed.

- [bazel-watcher on GitHub](https://github.com/bazelbuild/bazel-watcher)
