# Stable smoke test — assert on the contract (unused-deps computes the Bazel
# query it delegates to), never on help/version prose.
#
# unused-deps CANNOT do its real job in a smoke leg: it analyses `java_library`
# deps by driving a full `bazel build` with an injected aspect and then reading
# the resulting jdeps protos, which needs a Bazel workspace, a JDK and a network.
# So this drives it exactly as far as its own logic reaches and then stops it
# deliberately — the same shape as the bazelisk smoke test's unreachable
# download URL.
#
# `--build_tool` names the binary unused-deps shells out to. Pointed at a path
# that cannot exist, unused-deps still:
#   1. parses its flags and its positional target patterns,
#   2. builds the Bazel query expression itself — joining the patterns with its
#      own " + " separator and wrapping them in `kind('(kt|java|android)_*', …)`,
#   3. logs that computed command line to stderr BEFORE spawning anything,
#   4. gets nothing back, falls into its usage path, and exits 2.
# Steps 2-4 are unused_deps.go's own behaviour, byte-identical from buildtools
# 5.0.0 (this mirror's floor) through HEAD. The exit code is not incidental:
# `usage()` ends in `os.Exit(2)`.
#
# The `--version` flag is deliberately unused: it prints the string "redacted"
# unless the build stamps a version in, which the released binaries do not.
#
# Known maintenance point: the rule-kind set inside `kind(...)` is upstream's and
# will move if they start matching more languages. The assertions below anchor on
# the `+`-joined patterns and the `--tool_tag`, not on the kind list.
UNUSED_DEPS = "unused-deps.exe" if ocx.target_platform.os == ocx.os.Windows else "unused-deps"

# Inside scratch and never created — the spawn fails on every platform without
# depending on what the container image does or does not have installed.
ABSENT_BUILD_TOOL = ocx.scratch_root + "/absent-build-tool"

r = ocx.run(
    UNUSED_DEPS,
    "--build_tool=" + ABSENT_BUILD_TOOL,
    "//smoke:alpha",
    "//smoke:beta",
)

# Tier 1 + 3: the binary executed and ran its own logic — it joined the two
# target patterns with the ` + ` separator and wrapped them in a query
# expression. Neither the separator nor the wrapper was supplied by this script.
expect.contains(r.stderr, "//smoke:alpha + //smoke:beta")
expect.contains(r.stderr, "--tool_tag=unused_deps")
expect.matches(r.stderr, r"running: .*absent-build-tool.* query ")

# Tier 2: the deliberate, self-inflicted stop, at the documented exit code.
expect.eq(r.exit_code, 2)
