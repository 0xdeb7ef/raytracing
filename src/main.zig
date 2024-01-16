const std = @import("std");
const stdout_file = std.io.getStdOut().writer();

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const ObjectList = @import("Objects.zig").ObjectList;

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
    var world: ObjectList = undefined;
    world.init(alloc);
    defer world.objects.deinit();

    const material_ground = .{
        .lambertian = .{ .albedo = Vec(.{ 0.8, 0.8, 0.0 }) },
    };
    const material_center = .{
        .lambertian = .{ .albedo = Vec(.{ 0.1, 0.2, 0.5 }) },
    };
    const material_left = .{
        .dielectric = .{ .ir = 1.5 },
    };
    const material_right = .{
        .metal = .{
            .albedo = Vec(.{ 0.8, 0.6, 0.2 }),
            .fuzz = 1.0,
        },
    };

    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 0, -100.5, -1 }),
            .radius = 100,
            .mat = material_ground,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 0, 0, -1 }),
            .radius = 0.5,
            .mat = material_center,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ -1, 0, -1 }),
            .radius = 0.5,
            .mat = material_left,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ -1, 0, -1 }),
            .radius = -0.4,
            .mat = material_left,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 1, 0, -1 }),
            .radius = 0.5,
            .mat = material_right,
        },
    });

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
    for (0..cam.image_width * cam._image_height) |i| {
        try writeColor(buf[i], cam.samples_per_pixel, stdout);
    }

    try bw.flush();
}
