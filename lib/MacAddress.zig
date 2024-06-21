/// Individual bytes of the MAC address.
data: [6]u8,

pub const ParseError = error{
    InvalidInput,
};

pub const FormatError = error{
    NoSpaceLeft,
};

/// Parse a string into a `MacAddress`.
///
/// The `is_loopback` field is set to `false` but does not mean the parsed
/// value is not a loopback interface. This function does not make any
/// syscalls, so it knows nothing about the interface that's identified by the
/// value -- it's purely for display.
pub fn parse(buf: []const u8) !Self {
    var data: [6]u8 = undefined;
    var iter = std.mem.tokenizeScalar(u8, buf, ':');
    var i: usize = 0;
    while (iter.next()) |group| : (i += 1) {
        if (i >= 6) return ParseError.InvalidInput;

        data[i] = std.fmt.parseUnsigned(u8, group, 16) catch return ParseError.InvalidInput;
    }

    if (i < 6) return ParseError.InvalidInput;

    return Self{
        .is_loopback = false,
        .data = data,
    };
}

/// Format a `MacAddress` as a string, with each byte separated by colons. The
/// buffer must be at least 17 bytes long.
pub fn formatBuf(self: Self, buf: []u8) ![]u8 {
    return std.fmt.bufPrint(buf, "{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}", .{
        self.data[0],
        self.data[1],
        self.data[2],
        self.data[3],
        self.data[4],
        self.data[5],
    }) catch return FormatError.NoSpaceLeft;
}

/// Format a `MacAddress` as a string, with each byte separated by colons. The
/// caller owns the returned memory.
pub fn formatAlloc(self: Self, allocator: std.mem.Allocator) ![]u8 {
    const buf = try allocator.alloc(u8, MAC_STR_LEN);
    return self.formatBuf(buf);
}

/// Formats a MAC address to a string.
///
/// Note: The `fmt` and `options` arguments are required to work with
/// `std.fmt.format`, but are not used in `MacAddress`'s implementation.
pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = options;
    _ = fmt;

    var buf: [MAC_STR_LEN]u8 = undefined;
    const str = try self.formatBuf(&buf);

    try writer.writeAll(str);
}

const std = @import("std");
const testing = std.testing;

const Self = @This();

// The max length of a MAC address, formatted as a string with each byte
// separated with a colon.
const MAC_STR_LEN = 17;

test "parse_success" {
    const str = "00:11:22:33:44:55";
    const expected = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    const addr = try Self.parse(str);

    try testing.expect(std.meta.eql(expected, addr));
}

test "parse_error_too_short" {
    const str = "00:11:22:33:44";
    try testing.expectError(ParseError.InvalidInput, Self.parse(str));
}

test "parse_error_too_long" {
    const str = "00:11:22:33:44:55:66";
    try testing.expectError(ParseError.InvalidInput, Self.parse(str));
}

test "parse_error_empty" {
    const str = "";
    try testing.expectError(ParseError.InvalidInput, Self.parse(str));
}

test "parse_error_malformed" {
    const str = "00:11:22:33:4:455";
    try testing.expectError(ParseError.InvalidInput, Self.parse(str));
}

test "parse_error_malformed2" {
    const str = ":0011:22:33::4455";
    try testing.expectError(ParseError.InvalidInput, Self.parse(str));
}

test "format_buf_success" {
    const addr = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    const expected = "00:11:22:33:44:55";
    var buf: [MAC_STR_LEN]u8 = undefined;

    try testing.expectEqualSlices(u8, expected, try addr.formatBuf(&buf));
}

test "format_buf_too_small" {
    const addr = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    var buf: [16]u8 = undefined;

    try testing.expectError(FormatError.NoSpaceLeft, addr.formatBuf(&buf));
}

test "format_alloc_success" {
    const addr = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    const expected = "00:11:22:33:44:55";
    const buf = try addr.formatAlloc(testing.allocator);
    defer testing.allocator.free(buf);

    try testing.expectEqualSlices(u8, expected, buf);
}
