const std = @import("std");
const imb = @import("./imb.zig");

pub fn main() !void {
    const stuff = try imb.decodeString("AADTFFDFTDADTAADAATFDTDDAAADDTDTTDAFADADDDTFFFDDTTTADFAAADFTDAADA");
    std.log.info("{s}", .{stuff.tracking_code});
    std.log.info("{s}", .{stuff.routing_code});
}
