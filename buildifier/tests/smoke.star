# Stable smoke test — assert on the contract (buildifier reformats a BUILD file
# to its own canonical form), never on help/version prose.
#
# buildifier's whole job is FORMATTING, and unlike bazelisk it needs no network
# and no toolchain to do it — so this test does the real job end to end: write a
# deliberately misformatted BUILD file, prove buildifier reports it as
# unformatted, fix it, prove the result is buildifier's own fixed point.
#
# Both outcomes of the check are demonstrated in one run, on input this script
# controls: `formatted: false` before the fix, `formatted: true` after. A binary
# that did nothing cannot produce that pair.
#
# The assertion surface is `--mode=check --format=json` — buildifier's
# machine-readable diagnostics contract (documented in buildifier/README.md,
# unchanged in shape since 5.0.0, this mirror's floor), not console prose. With
# `--format` set buildifier always exits 0 and puts the verdict in the JSON
# `formatted` field, so the exit code is not the signal here; it only catches a
# rejected flag combination.
#
# Deliberately NOT asserted: the exact canonical layout. That is buildifier's to
# define and it shifts between releases — pinning it would red a healthy mirror.
# Asserting the fixed point instead uses the tool's own definition of canonical.
# `name = "foo"` is the single formatting fact asserted literally: spaces around
# `=` in a rule's keyword arguments is bedrock BUILD style and has never moved.
BUILDIFIER = "buildifier.exe" if ocx.target_platform.os == ocx.os.Windows else "buildifier"

# One line, no spaces around `=`, a multi-element list — buildifier rewrites
# every part of this. The list is already sorted so the only thing under test is
# formatting, not buildifier's separate list-sorting rewrite.
MISFORMATTED = 'cc_library(name="foo",srcs=["a.cc","b.cc"],deps=[":bar"])\n'

# Named `BUILD` on purpose: buildifier picks the (stricter) BUILD formatting
# rules from the filename. A file named anything else is formatted as generic
# Starlark and would not exercise the same code path.
ocx.write_file("BUILD", MISFORMATTED)

# Tier 1 + 3: the binary executed and its parser + formatter reached a verdict —
# valid Starlark, but not canonically formatted.
before = ocx.run(BUILDIFIER, "--mode=check", "--format=json", "BUILD")
expect.ok(before)
diagnosed = json.decode(before.stdout)["files"][0]
expect.true(diagnosed["valid"], msg = "buildifier could not parse a valid BUILD file")
expect.false(diagnosed["formatted"], msg = "buildifier saw nothing to fix in a misformatted BUILD file")

# Tier 2: fix mode (the default) rewrites the file in place.
fixed = ocx.run(BUILDIFIER, "BUILD")
expect.ok(fixed)
formatted = ocx.read_file("BUILD")
expect.ne(formatted, MISFORMATTED, msg = "buildifier left the file byte-identical")
expect.contains(formatted, 'name = "foo"')

# Tier 3: the rewritten file is buildifier's own fixed point — i.e. what it just
# produced is what it considers canonical.
after = ocx.run(BUILDIFIER, "--mode=check", "--format=json", "BUILD")
expect.ok(after)
expect.true(
    json.decode(after.stdout)["files"][0]["formatted"],
    msg = "buildifier does not consider its own output canonical",
)
