const std = @import("std");

const bar_positions = [_][4]u4{
    .{ 7, 2, 4, 3 },
    .{ 1, 10, 0, 0 },
    .{ 9, 12, 2, 8 },
    .{ 5, 5, 6, 11 },
    .{ 8, 9, 3, 1 },
    .{ 0, 1, 5, 12 },
    .{ 2, 5, 1, 8 },
    .{ 4, 4, 9, 11 },
    .{ 6, 3, 8, 10 },
    .{ 3, 9, 7, 6 },
    .{ 5, 11, 1, 4 },
    .{ 8, 5, 2, 12 },
    .{ 9, 10, 0, 2 },
    .{ 7, 1, 6, 7 },
    .{ 3, 6, 4, 9 },
    .{ 0, 3, 8, 6 },
    .{ 6, 4, 2, 7 },
    .{ 1, 1, 9, 9 },
    .{ 7, 10, 5, 2 },
    .{ 4, 0, 3, 8 },
    .{ 6, 2, 0, 4 },
    .{ 8, 11, 1, 0 },
    .{ 9, 8, 3, 12 },
    .{ 2, 6, 7, 7 },
    .{ 5, 1, 4, 10 },
    .{ 1, 12, 6, 9 },
    .{ 7, 3, 8, 0 },
    .{ 5, 8, 9, 7 },
    .{ 4, 6, 2, 10 },
    .{ 3, 4, 0, 5 },
    .{ 8, 4, 5, 7 },
    .{ 7, 11, 1, 9 },
    .{ 6, 0, 9, 6 },
    .{ 0, 6, 4, 8 },
    .{ 2, 1, 3, 2 },
    .{ 5, 9, 8, 12 },
    .{ 4, 11, 6, 1 },
    .{ 9, 5, 7, 4 },
    .{ 3, 3, 1, 2 },
    .{ 0, 7, 2, 0 },
    .{ 1, 3, 4, 1 },
    .{ 6, 10, 3, 5 },
    .{ 8, 7, 9, 4 },
    .{ 2, 11, 5, 6 },
    .{ 0, 8, 7, 12 },
    .{ 4, 2, 8, 1 },
    .{ 5, 10, 3, 0 },
    .{ 9, 3, 0, 9 },
    .{ 6, 5, 2, 4 },
    .{ 7, 8, 1, 7 },
    .{ 5, 0, 4, 5 },
    .{ 2, 3, 0, 10 },
    .{ 6, 12, 9, 2 },
    .{ 3, 11, 1, 6 },
    .{ 8, 8, 7, 9 },
    .{ 5, 4, 0, 11 },
    .{ 1, 5, 2, 2 },
    .{ 9, 1, 4, 12 },
    .{ 8, 3, 6, 6 },
    .{ 7, 0, 3, 7 },
    .{ 4, 7, 7, 5 },
    .{ 0, 12, 1, 11 },
    .{ 2, 9, 9, 0 },
    .{ 6, 8, 5, 3 },
    .{ 3, 10, 8, 2 },
};

fn generateCharacterTable(n: u8, comptime len: usize) [len]u13 {
    @setEvalBranchQuota(150000);

    var table: [len]u13 = undefined;

    var lower_index = 0;
    var upper_index = len - 1;

    for (0..0x2000) |i| {
        const b = bitsSet(u13, i);
        if (b != n) {
            continue;
        }

        const reverse = @bitReverse(@as(u13, i));

        if (reverse < i) {
            continue;
        }

        if (reverse == i) {
            table[upper_index] = i;
            upper_index -= 1;
        } else {
            table[lower_index] = i;
            lower_index += 1;
            table[lower_index] = reverse;
            lower_index += 1;
        }
    }

    return table;
}

const character_table_5 = generateCharacterTable(5, 1287);
const character_table_2 = generateCharacterTable(2, 77);

const BarType = enum {
    descending,
    ascending,
    tracking,
    full,
};

pub const BarcodeResult = struct {
    tracking_code: [20]u8,
    routing_code: [11]u8,
};

pub const Error = error{
    InvalidCharacter,
    DecodingError,
    InternalError,
    InvalidChecksum,
};

fn bitsSet(comptime T: type, value: T) u8 {
    var count: u8 = 0;

    for (0..@typeInfo(T).int.bits) |i| {
        count += @intCast((value >> @intCast(i)) & 1);
    }

    return count;
}

fn findCodeword(character: u13) ?u13 {
    const b = bitsSet(u13, character);
    if (b == 2) {
        for (character_table_2, 0..) |item, codeword| {
            if (character == item) {
                return @intCast(codeword + 1287);
            }
        }
    } else {
        for (character_table_5, 0..) |item, codeword| {
            if (character == item) {
                return @intCast(codeword);
            }
        }
    }

    return null;
}

fn generateChecksum(data: [13]u8) u16 {
    const generator_polynomial: u16 = 0x0F35;
    var checksum: u16 = 0x07ff;

    var byte: u16 = @as(u16, data[0]) << 5;

    for (2..8) |_| {
        if (((checksum ^ byte) & 0x400) != 0) {
            checksum = (checksum << 1) ^ generator_polynomial;
        } else {
            checksum <<= 1;
        }

        checksum &= 0x7FF;
        byte <<= 1;
    }

    for (data[1..]) |b| {
        byte = @as(u16, b) << 3;

        for (0..8) |_| {
            if (((checksum ^ byte) & 0x400) != 0) {
                checksum = (checksum << 1) ^ generator_polynomial;
            } else {
                checksum <<= 1;
            }

            checksum &= 0x7FF;
            byte <<= 1;
        }
    }

    return checksum;
}

fn decode(bars: [65]BarType) Error!BarcodeResult {
    var characters = [_]u13{0} ** 10;

    for (bars, 0..) |bar, i| {
        const positions = bar_positions[i];
        if (bar == .descending or bar == .full) {
            characters[positions[0]] |= (@as(u13, 1) << positions[1]);
        }
        if (bar == .ascending or bar == .full) {
            characters[positions[2]] |= (@as(u13, 1) << positions[3]);
        }
    }

    var checksum: u11 = 0;

    for (&characters, 0..) |*character, i| {
        switch (bitsSet(u13, character.*)) {
            8, 11 => {
                character.* ^= 0b1111111111111;
                checksum |= (@as(u11, 1) << @intCast(i));
            },
            2, 5 => {},
            else => return error.DecodingError,
        }

        character.* = findCodeword(character.*).?;
    }

    characters[9] /= 2;
    if (characters[0] >= 659) {
        characters[0] -= 659;
        checksum |= 0b10000000000;
    }

    var bindata: u104 = 0;

    bindata = @as(u104, characters[0]) * 1365 + characters[1];
    bindata = bindata * 1365 + characters[2];
    bindata = bindata * 1365 + characters[3];
    bindata = bindata * 1365 + characters[4];
    bindata = bindata * 1365 + characters[5];
    bindata = bindata * 1365 + characters[6];
    bindata = bindata * 1365 + characters[7];
    bindata = bindata * 1365 + characters[8];
    bindata = bindata * 636 + characters[9];

    if (generateChecksum(@bitCast(@byteSwap(bindata))) != checksum) { // lol, only works on little-endian systems #WONTFIX
        return error.InvalidChecksum;
    }

    var tracking_code: [20]u8 = undefined;
    var routing_code = [_]u8{0} ** 11;

    var i: u8 = 19;
    while (i >= 2) : (i -= 1) {
        tracking_code[i] = std.fmt.digitToChar(@intCast(bindata % 10), .lower);
        bindata /= 10;
    }
    tracking_code[i] = std.fmt.digitToChar(@intCast(bindata % 5), .lower);
    bindata /= 5;
    i -= 1;
    tracking_code[i] = std.fmt.digitToChar(@intCast(bindata % 10), .lower);
    bindata /= 10;

    switch (bindata) {
        1...100000 => {
            _ = std.fmt.bufPrint(&routing_code, "{d:05}", .{bindata - 1}) catch return error.InternalError;
        },
        100001...1000199999 => {
            _ = std.fmt.bufPrint(&routing_code, "{d:09}", .{bindata - 100000 - 1}) catch return error.InternalError;
        },
        else => {
            _ = std.fmt.bufPrint(&routing_code, "{d:011}", .{bindata - 1000000000 - 100000 - 1}) catch return error.InternalError;
        },
    }

    return .{
        .tracking_code = tracking_code,
        .routing_code = routing_code,
    };
}

pub fn decodeString(str: *const [65:0]u8) Error!BarcodeResult {
    var bars: [65]BarType = undefined;
    for (&bars, 0..) |*pt, i| {
        pt.* = switch (str[i]) {
            'A', 'a' => .ascending,
            'D', 'd' => .descending,
            'F', 'f' => .full,
            'T', 't' => .tracking,
            else => return error.InvalidCharacter,
        };
    }

    return try decode(bars);
}
