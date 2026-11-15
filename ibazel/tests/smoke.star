# Stable smoke test — assert on the contract, never on help prose.
#
# ibazel is a file WATCHER that drives `bazel`: build/test/run do nothing useful
# without a bazel binary, a workspace and (usually) the network, and then never
# exit. So this smoke deliberately stays on what ibazel does by itself:
#   1. it executes and prints its banner, whose `Version vX.Y.Z` token is the
#      release version (asserted by SHAPE, not value) — on stderr, exit 0;
#   2. flag parsing is real: an undefined flag is rejected with exit 2, the Go
#      `flag` package contract (ExitOnError), distinct from the 0 above.
#
# NOT covered: any actual watch/build/test/run cycle, the `-bazel_path`
# hand-off to bazel, live reload. Those need bazel + a workspace and would test
# bazel, not the mirrored ibazel binary.
IBAZEL = "ibazel.exe" if ocx.target_platform.os == ocx.os.Windows else "ibazel"

ok = ocx.run(IBAZEL, "version")
expect.eq(ok.exit_code, 0)
expect.matches(ok.stderr, r"Version v\d+\.\d+\.\d+")

bad = ocx.run(IBAZEL, "-no-such-flag-for-smoke")
expect.eq(bad.exit_code, 2)
