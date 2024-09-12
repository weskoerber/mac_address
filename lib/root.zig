pub const MacAddress = @import("MacAddress.zig");
pub const MacAddressError = @import("errors.zig").MacAddressError;

/// Retrieve all MAC addresses, including loopback devices.
pub fn getAll(allocator: std.mem.Allocator) ![]MacAddress {
    return switch (native_os) {
        .linux => linux.getAll(allocator),
        .windows => windows.getAll(allocator),
        else => |x| @panic("Unsupported OS '" ++ @tagName(x) ++ "'"),
    };
}

/// Retrieve MAC address from the first network interface that is not a
/// loopback interface.
pub fn getFirstNoLoopback(allocator: std.mem.Allocator) !MacAddress {
    return switch (native_os) {
        .linux => linux.getFirstNoLoopback(allocator),
        .windows => windows.getFirstNoLoopback(allocator),
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

test "get_first_no_loopback" {
    const addr = try getFirstNoLoopback(testing.allocator);

    try testing.expect(std.mem.indexOfDiff(u8, &addr.data, &.{ 0, 0, 0, 0, 0, 0 }) != null);
}
