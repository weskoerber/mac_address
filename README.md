[![test](https://github.com/weskoerber/mac_address/actions/workflows/test.yaml/badge.svg)](https://github.com/weskoerber/mac_address/actions/workflows/test.yaml)
[![docs](https://github.com/weskoerber/mac_address/actions/workflows/docs.yaml/badge.svg)](https://github.com/weskoerber/mac_address/actions/workflows/docs.yaml)

# `mac_address`

A cross-platform library to retrieve the MAC address from your network
interfaces without `libc`.

## Requirements

- [`zig`](https://github.com/ziglang/zig) compiler (`0.12.0` and up)[^1]

## Install

First, add the dependency to your `build.zig.zon file` using `zig fetch`:

```console
zig fetch --save git+https://github.com/weskoerber/mac_address#main
```

Then, import `mac_address` into your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mac_address = b.dependency("mac_address", .{
            .target = target,
            .optimize = optimize,
    }).module("mac_address");

    const my_exe = b.addExecutable(.{
        .name = "my_exe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    my_exe.root_module.addImport(mac_address);
}
```

## Usage

See the `examples` directory for example usage. Example executables can be
built by setting the `examples` option to `true`:

```zig
    const mac_address = b.dependency("mac_address", .{
            .target = target,
            .optimize = optimize,
            .examples = true,
    }).module("mac_address");
```

## Cross-platform support

| `mac_address` API  | Linux | Windows |
| ------------------ | ----- | ------- |
| `getAll`           | ✅    | ✅      |
| `getAllNoLoopback` | ✅    | 📝      |

- ✅ = supported
- 📝 = planned
- ❌ = not supported

---

[^1]: Shameless plug: if you're using a unix-like operating system or WSL on
    Windows, consider using a Zig compiler version manager I wrote called
    [zvm](https://github.com/weskoerber/zvm). Once downloaded and in your
    `PATH`, just run `zvm install 0.12.0` (or `zvm install master` to get the
    latest nightly).
