pub fn getAll(allocator: mem.Allocator) ![]MacAddress {
    _ = allocator;
    @panic("Not implemented");
}

const std = @import("std");
const mem = std.mem;

const MacAddress = @import("MacAddress.zig");
const MacAddressError = @import("errors.zig").MacAddressError;
