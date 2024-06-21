/// Get all available MAC addresses.
///
/// This function uses `ioctl`  to retrieve a list of network
/// interfaces:
/// - `SIOCGIFCONF` to retrieve a list of interface names
/// - `SIOCGIFFLAGS` to determine if it's a loopback device
/// - `SIOCGIFHWADDR` to get its MAC address
///
/// In total there will be 2 + 2n syscalls, where `n` is the number of network
/// interfaces. The first syscall determines how many interfaces there are.
/// After that, this function allocates and deallocates only the required
/// memory. Then, for each interface, its flags and MAC address are queried.
///
/// The caller is owns the returned memory.
pub fn getAll(allocator: mem.Allocator) ![]MacAddress {
    var addrs = std.ArrayList(MacAddress).init(allocator);
    var iter = try IfIterator.initAlloc(allocator, .{});
    defer iter.deinit();

    while (try iter.next()) |addr| {
        try addrs.append(addr);
    }

    return try addrs.toOwnedSlice();
}

/// Gets the MAC address of the first non-loopback interface.
///
/// Internally, this function works identically to the `getAll` function except
/// that it returns a single `MacAddress` struct, whereas `getAll` returns a
/// slice of `MacAddress` structs.
///
/// The returned memory is stack allocated and returned by value; the caller
/// need not free anything.
pub fn getFirstNoLoopback(allocator: mem.Allocator) !MacAddress {
    var iter = try IfIterator.initAlloc(allocator, .{ .skip_loopback = true });
    defer iter.deinit();

    while (try iter.next()) |addr| {
        return addr;
    }

    return MacAddressError.NoDevice;
}

fn ioctlReq(fd: linux.fd_t, req: u32, arg: *anyopaque) !void {
    const arg_int = @intFromPtr(arg);

    const result = linux.ioctl(fd, req, arg_int);
    const err = posix.errno(result);

    log.debug("ioctl 0x{x} for fd {d} with 0x{x} returned {d} ({})", .{ req, fd, arg_int, result, err });

    if (err != .SUCCESS) return MacAddressError.OsError;
}

const IfIterator = struct {
    allocator: mem.Allocator,
    buffer: []ifreq,
    index: usize,
    sock_fd: i32,
    iterator_options: IteratorOptions,

    pub const IteratorOptions = struct {
        skip_loopback: bool = false,
    };

    pub fn initAlloc(allocator: mem.Allocator, iterator_options: IteratorOptions) !IfIterator {
        const sock = linux.socket(linux.AF.INET, linux.SOCK.DGRAM, linux.IPPROTO.IP);
        const sock_fd = if (posix.errno(sock) == .SUCCESS)
            @as(linux.fd_t, @intCast(sock))
        else
            return MacAddressError.OsError;

        var ifc = mem.zeroes(ifconf);

        try ioctlReq(sock_fd, SIOCGIFCONF, &ifc);

        const num_elems = @divTrunc(@as(u32, @intCast(ifc.ifc_len)), @sizeOf(ifreq));
        const elems = try allocator.alloc(ifreq, num_elems);

        ifc.ifc_ifu.ifc_buf = @alignCast(@ptrCast(elems.ptr));

        try ioctlReq(sock_fd, SIOCGIFCONF, &ifc);

        return .{
            .allocator = allocator,
            .buffer = elems,
            .index = 0,
            .sock_fd = sock_fd,
            .iterator_options = iterator_options,
        };
    }

    pub fn deinit(self: *IfIterator) void {
        self.allocator.free(self.buffer);
        _ = linux.close(self.sock_fd);
    }

    pub fn next(self: *IfIterator) !?MacAddress {
        if (self.index >= self.buffer.len) {
            return null;
        }

        const elem = &self.buffer[self.index];

        std.debug.print("if: {s}\n", .{elem.ifrn.name});

        ioctlReq(self.sock_fd, SIOCGIFFLAGS, elem) catch return MacAddressError.OsError;
        const is_loopback = elem.ifru.flags & IFF_LOOPBACK != 0;

        if (self.iterator_options.skip_loopback and is_loopback) {
            self.index += 1;
            return self.next();
        }

        ioctlReq(self.sock_fd, SIOCGIFHWADDR, elem) catch return MacAddressError.OsError;
        const hwaddr = elem.ifru.hwaddr.data[0..6].*;

        var addr = mem.zeroes(MacAddress);
        addr.data = hwaddr;

        self.index += 1;

        return addr;
    }
};

const std = @import("std");
const linux = std.os.linux;
const mem = std.mem;
const posix = std.posix;

const options = @import("options");

const log = if (options.verbose) std.log.scoped(.mac_address) else NullLogger{};
const MacAddress = @import("MacAddress.zig");
const MacAddressError = @import("errors.zig").MacAddressError;
const NullLogger = struct {
    const T: type = fn (fmt: []const u8, args: anytype) void;

    debug: T = null_log,
    info: T = null_log,
    warn: T = null_log,
    err: T = null_log,

    fn null_log(fmt: []const u8, args: anytype) void {
        _ = fmt;
        _ = args;
    }
};

// These definitions aren't in zig's standard library
const SIOCGIFCONF = 0x8912;
const SIOCGIFFLAGS = 0x8913;
const SIOCGIFHWADDR = 0x8927;

const IFNAMESIZE = linux.IFNAMESIZE;
const IFF_LOOPBACK = 0x8;
const sockaddr = linux.sockaddr;

// https://github.com/ziglang/zig/issues/19980
pub const ifreq = extern struct {
    ifrn: extern union {
        name: [IFNAMESIZE]u8,
    },
    ifru: extern union {
        addr: sockaddr,
        dstaddr: sockaddr,
        broadaddr: sockaddr,
        netmask: sockaddr,
        hwaddr: sockaddr,
        flags: i16,
        ivalue: i32,
        mtu: i32,
        map: ifmap,
        slave: [IFNAMESIZE - 1:0]u8,
        newname: [IFNAMESIZE - 1:0]u8,
        data: ?[*]u8,
    },
};
pub const ifmap = extern struct {
    mem_start: usize,
    mem_end: usize,
    base_addr: u16,
    irq: u8,
    dma: u8,
    port: u8,
};
const ifconf = extern struct {
    ifc_len: i32,
    ifc_ifu: extern union {
        ifc_buf: ?[*]u8,
        ifc_req: ?[*]ifreq,
    },
};
