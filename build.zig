const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Declaring modules here

    const ll = b.createModule(.{
        .root_source_file = b.path("src/common/ll.zig"),
    });

    const chashmap = b.createModule(.{ .root_source_file = b.path("src/common/chashmap/chashmap.zig") });

    const defaults = b.createModule(.{
        .root_source_file = b.path("src/defaults.zig"),
    });

    const notifier = b.createModule(.{ .root_source_file = b.path("src/notifier.zig") });

    const ep_module = b.createModule(.{ .root_source_file = b.path("src/ep.zig"), .imports = &.{.{ .name = "ll", .module = ll }} });
    const cache = b.createModule(.{ .root_source_file = b.path("src/cache.zig"), .imports = &.{ .{ .name = "ep", .module = ep_module }, .{ .name = "defaults", .module = defaults }, .{ .name = "ll", .module = ll }, .{ .name = "notify", .module = notifier }, .{ .name = "chashmap", .module = chashmap } } });

    const lib = b.addStaticLibrary(.{
        .name = "cerca",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/cerca.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.root_module.addImport("ep", ep_module);
    lib.root_module.addImport("ll", ll);
    lib.root_module.addImport("defaults", defaults);
    lib.root_module.addImport("cache", cache);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "cerca",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lru_tests = b.addTest(.{
        .name = "lru_tests",
        .root_source_file = b.path("src/tests/lru.zig"),
        .target = target,
        .optimize = optimize,
    });
    lru_tests.root_module.addImport("ep", ep_module);
    lru_tests.root_module.addImport("ll", ll);
    lru_tests.root_module.addImport("defaults", defaults);
    lru_tests.root_module.addImport("cache", cache);

    const sieve_tests = b.addTest(.{
        .name = "sieve_tests",
        .root_source_file = b.path("src/tests/sieve.zig"),
        .target = target,
        .optimize = optimize,
    });
    sieve_tests.root_module.addImport("ep", ep_module);
    sieve_tests.root_module.addImport("ll", ll);
    sieve_tests.root_module.addImport("defaults", defaults);
    sieve_tests.root_module.addImport("cache", cache);

    const generic_tests = b.addTest(.{
        .name = "generic_tests",
        .root_source_file = b.path("src/tests/generic.zig"),
        .target = target,
        .optimize = optimize,
    });
    generic_tests.root_module.addImport("cache", cache);
    generic_tests.root_module.addImport("ep", ep_module);

    const chashmap_tests = b.addTest(.{ .name = "chashmap_tests", .root_source_file = b.path("src/common/chashmap/chashmap.zig"), .target = target, .optimize = optimize });
    const lru_run_tests = b.addRunArtifact(lru_tests);
    const sieve_run_tests = b.addRunArtifact(sieve_tests);
    const generic_run_tests = b.addRunArtifact(generic_tests);
    const chashmap_run_tests = b.addRunArtifact(chashmap_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lru_run_tests.step);
    test_step.dependOn(&sieve_run_tests.step);
    test_step.dependOn(&generic_run_tests.step);
    test_step.dependOn(&chashmap_run_tests.step);

    const fmt_step = b.step("fmt", "Run formatting checks");
    const fmt = b.addFmt(.{
        .paths = &.{
            "src",
            "build.zig",
        },
        .check = true,
    });

    fmt_step.dependOn(&fmt.step);
    b.default_step.dependOn(fmt_step);
}
