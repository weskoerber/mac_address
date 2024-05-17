/// Get all available MAC addresses.
///
/// This function uses the `SIOCGIFCONF` `ioctl` to retrieve a list of network
/// interfaces, and `SIOCGIFHWADDR` to get their MAC address. In total there
/// will be 2 + `n` syscalls, where `n` is the number of network interfaces.
/// The first syscall determines how many interfaces there are. After that,
/// this function allocates and deallocates only the required memory.
///
/// The caller is owns the returned memory.
pub fn getAll(allocator: mem.Allocator) ![]MacAddress {
    var addrs = std.ArrayList(MacAddress).init(allocator);
    const sock = linux.socket(linux.AF.INET, linux.SOCK.DGRAM, linux.IPPROTO.IP);
    const sock_fd = if (posix.errno(sock) == .SUCCESS)
        @as(linux.fd_t, @intCast(sock))
    else
        return MacAddressError.OsError;

    var ifc = mem.zeroes(ifconf);
    var ifr = mem.zeroes(ifreq);

    try ioctlReq(sock_fd, SIOCGIFCONF, &ifc);

    const num_elems = @divTrunc(@as(u32, @intCast(ifc.ifc_len)), @sizeOf(ifreq));
    const elems = try allocator.alloc(ifreq, num_elems);
    defer allocator.free(elems);

    ifc.ifc_ifu.ifc_buf = @alignCast(@ptrCast(elems.ptr));

    try ioctlReq(sock_fd, SIOCGIFCONF, &ifc);

    for (elems) |elem| {
        ifr.ifrn.name = elem.ifrn.name;

        try ioctlReq(sock_fd, SIOCGIFHWADDR, &ifr);

        try addrs.append(MacAddress{ .data = ifr.ifru.hwaddr.data[0..6].* });
    }

    return try addrs.toOwnedSlice();
}

fn ioctlReq(fd: linux.fd_t, req: u32, arg: *anyopaque) !void {
    const result = linux.ioctl(fd, req, @intFromPtr(arg));
    const err = posix.errno(result);

    if (err != .SUCCESS) return MacAddressError.OsError;
}

const std = @import("std");
const linux = std.os.linux;
const mem = std.mem;
const posix = std.posix;

const MacAddress = @import("MacAddress.zig");
const MacAddressError = @import("errors.zig").MacAddressError;

// These definitions aren't in zig's standard library
const SIOCGIFCONF = 0x8912;
const SIOCGIFHWADDR = 0x8927;

const IFNAMESIZE = linux.IFNAMESIZE;
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
