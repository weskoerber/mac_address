const std = @import("std");
const debug = std.debug;
const heap = std.heap;

const mac_address = @import("mac_address");

pub fn main() void {
    const addrs = mac_address.getAll(heap.page_allocator) catch |err| {
        debug.print("error: {}\n  -> unable to get MAC address\n", .{err});
        return;
    };

    if (addrs.len == 0) {
        std.debug.print("No MAC addresses found\n", .{});
    } else {
        std.debug.print("{}\n", .{addrs[0]});
    }
}
