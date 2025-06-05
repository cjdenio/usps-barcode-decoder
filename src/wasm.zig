const std = @import("std");
const imb = @import("./imb.zig");

const allocator = std.heap.wasm_allocator;

export fn decodeStringWasm(str: *const [65:0]u8) usize {
    if (imb.decodeString(str)) |v| {
        const ptr = allocator.create([31]u8) catch unreachable;
        ptr.* = v.tracking_code ++ v.routing_code;
        return @intFromPtr(ptr);
    } else |e| switch (e) {
        error.InvalidCharacter => return 0,
        error.DecodingError => return 1,
        error.InternalError => return 2,
        error.InvalidChecksum => return 3,
    }
}

export fn malloc(len: u8) [*]u8 {
    return (allocator.alloc(u8, len) catch unreachable).ptr;
}

export fn free(ptr: [*]u8, len: u8) void {
    allocator.free(ptr[0..len]);
}
