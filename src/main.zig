const std = @import("std");
const stdout_file = std.io.getStdOut().writer();
const log = std.log;

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const Ray = @import("Ray.zig");

const interval = @import("utils/interval.zig");
const colorUtils = @import("utils/color.zig");

const Objects = @import("Objects.zig");
const HittableList = Objects.HittableList;
const HitRecord = Objects.HitRecord;
const Hittable = Objects.Hittable;

const Camera = @import("Camera.zig");

pub fn main() !void {
    // for now, let's use stdout
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // World
    var world = HittableList{};
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

    var cam = Camera{ .image_width = 400, .aspect_ratio = 16.0 / 9.0 };
    try cam.render(world, stdout);

    try bw.flush();
}
