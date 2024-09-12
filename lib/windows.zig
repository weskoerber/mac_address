/// Get all available MAC addresses.
///
/// Windows recommends preallocating a 15k buffer rather than determine the
/// buffer size at runtime since GetAdaptersAddresses is resource-intensive.
/// This buffer is invisible to the caller, as it is allocated and freed within
/// this function.
/// See
/// https://learn.microsoft.com/en-us/windows/win32/api/iphlpapi/nf-iphlpapi-getadaptersaddresses#remarks.
///
/// The caller is owns the returned memory.
pub fn getAll(allocator: mem.Allocator) ![]MacAddress {
    var addrs = std.ArrayList(MacAddress).init(allocator);

    const buf = try allocator.alloc(IP_ADAPTER_ADDRESSES_LH, 36);
    defer allocator.free(buf);
    var size = @as(u32, @truncate(buf.len * @sizeOf(IP_ADAPTER_ADDRESSES_LH)));

    if (GetAdaptersAddresses(.INET, .{}, null, @alignCast(@ptrCast(buf.ptr)), &size) != @intFromEnum(NO_ERROR)) {
        return MacAddressError.OsError;
    }

    var node: ?*IP_ADAPTER_ADDRESSES_LH = &buf[0];
    while (node) |adapter| : (node = node.?.Next) {
        try addrs.append(MacAddress{
            .data = adapter.PhysicalAddress[0..6].*,
        });
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
    const buf = try allocator.alloc(IP_ADAPTER_ADDRESSES_LH, 36);
    defer allocator.free(buf);
    var size = @as(u32, @truncate(buf.len * @sizeOf(IP_ADAPTER_ADDRESSES_LH)));

    if (GetAdaptersAddresses(.INET, .{}, null, @alignCast(@ptrCast(buf.ptr)), &size) != @intFromEnum(NO_ERROR)) {
        return MacAddressError.OsError;
    }

    var node: ?*IP_ADAPTER_ADDRESSES_LH = &buf[0];
    while (node) |adapter| : (node = node.?.Next) {
        if (adapter.IfType != MIB_IF_TYPE_LOOPBACK) {
            return MacAddress{
                .data = adapter.PhysicalAddress[0..6].*,
            };
        }
    }

    return MacAddressError.NoDevice;
}

const std = @import("std");
const mem = std.mem;

const win32 = @import("win32");
const foundation = win32.foundation;
const ip_helper = win32.network_management.ip_helper;

const NO_ERROR = foundation.NO_ERROR;
const ERROR_BUFFER_OVERFLOW = foundation.ERROR_BUFFER_OVERFLOW;
const IP_ADAPTER_ADDRESSES_LH = ip_helper.IP_ADAPTER_ADDRESSES_LH;
const GetAdaptersAddresses = ip_helper.GetAdaptersAddresses;

const MIB_IF_TYPE_LOOPBACK = ip_helper.MIB_IF_TYPE_LOOPBACK;
const MacAddress = @import("MacAddress.zig");
const MacAddressError = @import("errors.zig").MacAddressError;

const AdapterOptions = struct {
    exclude_loopback: bool = false,
};
