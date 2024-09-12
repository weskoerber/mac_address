const std = @import("std");
const debug = std.debug;
const heap = std.heap;

const mac_address = @import("mac_address");

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const addrs = try mac_address.getAll(allocator);
    for (addrs) |addr| {
        debug.print("{}\n", .{addr});
    }
}
