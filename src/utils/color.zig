pub fn writeColor(color: @Vector(3, f32), writer: anytype) !void {
    const c = color * @as(@TypeOf(color), @splat(255.999));
    const r: u8 = @intFromFloat(c[0]);
    const g: u8 = @intFromFloat(c[1]);
    const b: u8 = @intFromFloat(c[2]);

    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}
