const std = @import("std");
const debug = std.debug;
const heap = std.heap;

const mac_address = @import("mac_address");

pub fn main() void {
    const addr = mac_address.getFirstNoLoopback(heap.page_allocator) catch |err| {
        debug.print("error: {}\n  -> unable to get MAC address\n", .{err});
        return;
    };

    debug.print("{}\n", .{addr});
}
