# Stable smoke test — assert on the contract (the binary runs and performs its
# launcher logic), never on help/version prose.
#
# bazelisk is a Bazel VERSION LAUNCHER, not a standalone tool: its job is to
# resolve a Bazel version, download that Bazel, and exec it. Actually downloading
# Bazel (~50MB) in the smoke would test *Bazel*, not bazelisk, and add a per-leg
# network dependency on Bazel's CDN. Instead we prove the mirrored *bazelisk*
# binary runs and executes its core logic — resolve the pinned version and build
# the platform-correct Bazel download URL — then stop it fast by pointing it at
# an unreachable base URL.
#
# bazelisk logs the download attempt to stderr BEFORE fetching:
#   "Downloading <base>/7.4.1/bazel-7.4.1-<os>-<arch>..."
# That line proves bazelisk executed, parsed USE_BAZEL_VERSION, and computed the
# platform string — the whole launcher contract short of the network download.
# The exit code is non-zero by design (the dead URL fails), so it is not asserted.
#
# USE_BAZEL_VERSION pins Bazel 7.4.1 (a stable LTS) so the asserted token is
# deterministic — this is a known maintenance point; bump it when 7.4.1 is EOL.
BAZELISK = "bazelisk.exe" if ocx.target_platform.os == ocx.os.Windows else "bazelisk"

r = ocx.run(
    BAZELISK,
    "version",
    env = {
        "USE_BAZEL_VERSION": "7.4.1",
        "BAZELISK_HOME": ocx.scratch_root + "/bzl",
        # Unreachable base URL: bazelisk emits the Downloading line, then fails
        # fast instead of pulling ~50MB of Bazel over the network.
        "BAZELISK_BASE_URL": "http://127.0.0.1:1/dead",
    },
)

# Tier 1 + 3: the binary executed and ran its launcher logic far enough to emit
# the download URL for the pinned Bazel version.
expect.contains(r.stderr, "Downloading")
# Tier 2: version SHAPE — the pinned Bazel version appears in the computed URL
# (`.../bazel-7.4.1-<platform>`). Asserts bazelisk parsed the version correctly.
expect.matches(r.stderr, r"bazel-\d+\.\d+\.\d+-")
