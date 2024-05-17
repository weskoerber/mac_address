pub const MacAddress = @import("MacAddress.zig");
pub const MacAddressError = @import("errors.zig").MacAddressError;

pub const getAll = switch (native_os) {
    .linux => linux.getAll,
    .windows => windows.getAll,
    else => |x| @panic("Unsupported OS '" ++ @tagName(x) ++ "'"),
};

const std = @import("std");
const builtin = @import("builtin");
const debug = std.debug;
const mem = std.mem;
const unicode = std.unicode;

const linux = @import("linux.zig");
const windows = @import("windows.zig");

const native_os = builtin.os.tag;
