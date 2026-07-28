# Stable smoke test — assert on the contract (the launcher unpacks itself, boots
# its bundled JRE and gets an answer from the Bazel server), never on help or
# version prose.
#
# `bazel --version` is answered by the C++ client before it does anything at all
# (blaze.cc: `argc == 2 && argv[1] == "--version"` returns immediately) — no
# unpacking, no JVM, no server. It proves the file is executable and nothing
# else. `bazel version` — the subcommand, no dashes — is implemented server-side,
# so reaching it forces the whole chain the mirrored artifact has to deliver:
# unpack the embedded install base, start a JVM from the bundled runtime, load
# the server jar, answer. That is what is asserted here.
#
# `--noautodetect_server_javabase` is what makes the assertion mean "the BUNDLED
# runtime booted" rather than "some runtime booted". Without it bazel silently
# falls back to a host JVM (JAVA_HOME, then PATH), so an artifact whose embedded
# runtime was missing or broken would still pass on any image that happens to
# ship Java. With it, a missing embedded runtime is a hard stop
# (startup_options.cc → `BAZEL_DIE(LOCAL_ENVIRONMENTAL_ERROR)`, exit 36) and the
# result no longer depends on what the container image has installed — which is
# the property worth keeping now that this package ships one variant, the
# default, carrying its own JRE.
#
# `Build label:` is the server's own structured output — the same line bazelisk
# and CI tooling parse, not console chatter — and it confirms the answer came
# from the server rather than the client. The load-bearing assertion is the exit
# code: 0 is unreachable unless every step above worked.
#
# PLATFORM CONSTRAINT: the bazel binary is dynamically linked against glibc,
# libstdc++ and libgcc, and so is its bundled JRE (verified with `ldd`); upstream
# publishes no musl build. This test cannot pass on Alpine, and no rewrite of it
# would help — the loader rejects the binary before any of it runs. This
# package's `platforms` matrix must not carry a musl container leg. (The other
# three packages here are static Go binaries, where the Alpine leg is exactly the
# leg worth having.)
#
# Genuinely NOT covered: an actual build. Driving one needs a workspace, external
# toolchains and the network — that would be testing Bazel, not the mirror.
BAZEL = "bazel.exe" if ocx.target_platform.os == ocx.os.Windows else "bazel"

r = ocx.run(
    BAZEL,
    # A stray /etc/bazel.bazelrc in a base image could otherwise inject startup
    # options and change what is being measured.
    "--ignore_all_rc_files",
    # Keeps the unpacked install base and the output base inside scratch instead
    # of the image's /var/tmp: the install base defaults to
    # `<output_user_root>/install/<md5>`, so this one flag covers both.
    "--output_user_root=" + ocx.scratch_root + "/output-user-root",
    # Pins the JVM to the artifact's own bundled runtime; see above.
    "--noautodetect_server_javabase",
    # The subcommand, not `--version` — this one needs the server.
    "version",
)

# Tier 1 + 3: unpacked, booted the bundled JRE, and the server answered. A
# truncated artifact fails unpacking with 36; one missing its bundled runtime
# stops with 36 at the javabase lookup. Neither reaches 0.
expect.ok(r)
# Tier 2: version SHAPE, from the server's own structured output.
expect.matches(r.stdout, r"Build label: \d+\.\d+\.\d+")
