const std = @import("std");
const stdout_file = std.io.getStdOut().writer();
const log = std.log;

const Vector = @import("Vector.zig").Vector;
const colorUtils = @import("utils/color.zig");

const image_width = 256;
const image_height = 256;

pub fn main() !void {
    // for now, let's use stdout
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const Vec3 = Vector(3, f32);

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    var i: usize = 0;
    while (i < image_height) : (i += 1) {
        std.log.info("Scanlines remaining: [{d:3}/{d:3}]", .{ image_height - i, image_height });
        var j: usize = 0;
        while (j < image_width) : (j += 1) {
            // representing the colors as values from 0.0 to 1.0
            const color = Vec3.init(.{ @as(f32, @floatFromInt(i)) / (image_height - 1), @as(f32, @floatFromInt(j)) / (image_width - 1), 0.0 });
            try colorUtils.writeColor(color, stdout);
        }
    }
    std.log.info("Done!", .{});
    try bw.flush();
}
