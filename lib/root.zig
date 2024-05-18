pub const MacAddress = @import("MacAddress.zig");
pub const MacAddressError = @import("errors.zig").MacAddressError;

/// Retrieve all MAC addresses, including loopback devices.
pub const getAll = switch (native_os) {
    .linux => linux.getAll,
    .windows => windows.getAll,
    else => |x| @panic("Unsupported OS '" ++ @tagName(x) ++ "'"),
};

pub const getFirstNoLoopback = switch (native_os) {
    .linux => linux.getFirstNoLoopback,
    else => |x| @panic("Unsupported OS '" ++ @tagName(x) ++ "'"),
};

const std = @import("std");
const builtin = @import("builtin");

const linux = @import("linux.zig");
const windows = @import("windows.zig");

const native_os = builtin.os.tag;
