/// Determines whether MAC address belongs to a loopback device
is_loopback: bool,

/// Individual bytes of the MAC address.
data: [6]u8,

pub const ParseError = error{
    InvalidInput,
};

pub const FormatError = error{
    NoSpaceLeft,
};

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

pub fn toString(self: Self, buf: []u8) ![]u8 {
    return std.fmt.bufPrint(buf, "{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}", .{
        self.data[0],
        self.data[1],
        self.data[2],
        self.data[3],
        self.data[4],
        self.data[5],
    }) catch return FormatError.NoSpaceLeft;
}

const std = @import("std");
const testing = std.testing;

const Self = @This();

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

test "tostring_success" {
    const addr = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    const expected = "00:11:22:33:44:55";
    var buf: [17]u8 = undefined;

    try testing.expectEqualSlices(u8, expected, try addr.toString(&buf));
}

test "tostring_too_small" {
    const addr = Self{ .is_loopback = false, .data = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 } };
    var buf: [16]u8 = undefined;

    try testing.expectError(FormatError.NoSpaceLeft, addr.toString(&buf));
}
