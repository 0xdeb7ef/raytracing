const util = @import("utils.zig");
const interval = util.interval;

pub fn writeColor(color: @Vector(3, f32), samples: u32, writer: anytype) !void {
    const intensity = interval{ .min = 0.0, .max = 0.999 };

    // Linear to Gamma correction (@sqrt)
    const c = @sqrt(color * @as(@TypeOf(color), @splat(1.0 / @as(f32, @floatFromInt(samples)))));

    const r: u8 = @intFromFloat(256 * intensity.clamp(c[0]));
    const g: u8 = @intFromFloat(256 * intensity.clamp(c[1]));
    const b: u8 = @intFromFloat(256 * intensity.clamp(c[2]));

    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}
