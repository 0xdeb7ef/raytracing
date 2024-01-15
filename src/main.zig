const std = @import("std");
const stdout_file = std.io.getStdOut().writer();

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const Objects = @import("Objects.zig");
const HittableList = Objects.HittableList;
const Hittable = Objects.Hittable;

const Camera = @import("Camera.zig");

const utils = @import("utils/utils.zig");
const writeColor = utils.writeColor;

pub fn main() !void {
    // for now, let's use stdout
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // gpa
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // World
    var world: HittableList = undefined;
    world.init(alloc);
    defer world.objects.deinit();
    try world.add(Hittable{ .sphere = Objects.Sphere{
        .center = Vec(.{ 0, -100.5, -1 }),
        .radius = 100,
    } });
    try world.add(Hittable{ .sphere = Objects.Sphere{
        .center = Vec(.{ 0, 0, -1 }),
        .radius = 0.5,
    } });

    // Camera
    var cam = Camera{
        .image_width = 400,
        .aspect_ratio = 16.0 / 9.0,
        .samples_per_pixel = 100,
        .max_depth = 50,
    };
    const buf = try cam.render(world, alloc, null);
    defer alloc.free(buf);

    // Image
    try stdout.print("P3\n{d} {d}\n255\n", .{ cam.image_width, cam._image_height });
    for (0..((cam.image_width * cam._image_height) - 1)) |i| {
        try writeColor(buf[i], cam.samples_per_pixel, stdout);
    }

    try bw.flush();
}
