pub const MacAddress = @import("MacAddress.zig");
pub const MacAddressError = @import("errors.zig").MacAddressError;

/// Retrieve all MAC addresses.
pub fn getAll(allocator: std.mem.Allocator) ![]MacAddress {
    return switch (native_os) {
        .linux => linux.getAll(allocator),
        .windows => windows.getAll(allocator),
        else => |x| @panic("Unsupported OS '" ++ @tagName(x) ++ "'"),
    };
}

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

const linux = @import("linux.zig");
const windows = @import("windows.zig");

const native_os = builtin.os.tag;

test "get_all" {
    const addrs = try getAll(testing.allocator);
    defer testing.allocator.free(addrs);
}
