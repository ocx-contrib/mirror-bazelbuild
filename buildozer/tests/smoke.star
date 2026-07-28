# Stable smoke test — assert on the contract (buildozer applies a scripted edit
# to a BUILD file), never on help/version prose.
#
# buildozer's whole job is REWRITING BUILD files from commands, and it needs no
# network and no toolchain to do it — so this test does the real job: build a
# minimal workspace in scratch, apply one `add deps` command, read the file back.
#
# The second, identical run is what makes this more than a smoke: `add` does not
# re-add a value already present, and "success, no changes were made" is exit 3,
# buildozer's documented return code (buildozer/README.md "Error code";
# `edit/buildozer.go` returns 3 for a non-readonly command that modified
# nothing — same code path at 5.0.0, this mirror's floor, and at HEAD). That run
# proves buildozer PARSED the file it had just written: a binary that blindly
# appended text would modify the file again and exit 0.
BUILDOZER = "buildozer.exe" if ocx.target_platform.os == ocx.os.Windows else "buildozer"

# buildozer resolves `//pkg:rule` against the nearest repository-root marker,
# walking up from cwd (WORKSPACE, WORKSPACE.bazel, MODULE.bazel, ... — see
# wspace/workspace.go). cwd defaults to the scratch root, so an empty WORKSPACE
# there anchors the label deterministically instead of leaving resolution to
# whatever happens to sit above the scratch directory.
ocx.write_file("WORKSPACE", "")
ocx.mkdir("pkg")
ocx.write_file("pkg/BUILD", 'java_library(\n    name = "foo",\n    deps = ["//a:lib"],\n)\n')

# Both labels are written in a form buildozer's `ShortenLabel` leaves alone
# (target name differs from the last package segment, and neither is in `//pkg`),
# so the strings asserted below are the strings that land in the file.
edit = ocx.run(BUILDOZER, "add deps //b:lib", "//pkg:foo")

# Tier 1 + 3: the binary executed and performed the edit it was told to.
expect.ok(edit)
after = ocx.read_file("pkg/BUILD")
expect.contains(after, '"//b:lib"', msg = "buildozer did not add the dep")
# An edit, not a rewrite — the pre-existing dep survives.
expect.contains(after, '"//a:lib"', msg = "buildozer dropped an existing dep")

# Tier 2: idempotence, via the documented "no changes made" exit code. This only
# holds if buildozer re-read and understood the file it produced above.
again = ocx.run(BUILDOZER, "add deps //b:lib", "//pkg:foo")
expect.eq(again.exit_code, 3, msg = "buildozer did not recognise the dep it had just added")
expect.eq(ocx.read_file("pkg/BUILD"), after, msg = "buildozer changed the file on a no-op command")
