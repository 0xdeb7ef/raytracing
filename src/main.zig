const std = @import("std");
const stdout_file = std.io.getStdOut().writer();
const stderr_file = std.io.getStdErr().writer();

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const util = @import("utils/utils.zig");
const random = util.random;

const ObjectList = @import("Objects.zig").ObjectList;

const Material = @import("Materials.zig").Material;

const Camera = @import("Camera.zig");

const utils = @import("utils/utils.zig");
const writeColor = utils.writeColor;

pub fn main() !void {
    // for now, let's use stdout
    var bw = std.io.bufferedWriter(stdout_file);
    var bwe = std.io.bufferedWriter(stderr_file);
    const stdout = bw.writer();
    const stderr = bwe.writer();

    // gpa
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // World
    var world: ObjectList = undefined;
    world.init(alloc);
    defer world.objects.deinit();

    const ground_material = .{ .lambertian = .{ .albedo = Vec(.{ 0.5, 0.5, 0.5 }) } };
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 0, -1000, 0 }),
            .radius = -1000,
            .mat = ground_material,
        },
    });

    var a: isize = -11;
    while (a < 11) : (a += 1) {
        var b: isize = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = random(f32);
            const center = Vec(.{
                @as(f32, @floatFromInt(a)) + 0.9 * random(f32),
                0.2,
                @as(f32, @floatFromInt(b)) + 0.9 * random(f32),
            });

            if (Vec3t.mag(center - Vec(.{ 4, 0.2, 0 })) > 0.9) {
                var sphere_material: Material = undefined;

                if (choose_mat < 0.8) {
                    // diffuse
                    sphere_material = .{
                        .lambertian = .{
                            .albedo = Vec3t.randomVec() * Vec3t.randomVec(),
                        },
                    };
                } else if (choose_mat < 0.95) {
                    // metal
                    sphere_material = .{
                        .metal = .{
                            .albedo = Vec3t.randomIVec(0.5, 1),
                            .fuzz = random(f32),
                        },
                    };
                } else {
                    // glass
                    sphere_material = .{ .dielectric = .{ .ir = 1.5 } };
                }

                try world.add(.{
                    .sphere = .{
                        .center = center,
                        .radius = 0.2,
                        .mat = sphere_material,
                    },
                });
            }
        }
    }

    const material1 = .{ .dielectric = .{ .ir = 1.5 } };
    const material2 = .{ .lambertian = .{ .albedo = Vec(.{ 0.4, 0.2, 0.1 }) } };
    const material3 = .{
        .metal = .{
            .albedo = Vec(.{ 0.7, 0.6, 0.5 }),
            .fuzz = 0,
        },
    };

    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 0, 1, 0 }),
            .radius = 1,
            .mat = material1,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ -4, 1, 0 }),
            .radius = 1,
            .mat = material2,
        },
    });
    try world.add(.{
        .sphere = .{
            .center = Vec(.{ 4, 1, 0 }),
            .radius = 1,
            .mat = material3,
        },
    });

    // Camera
    var cam = Camera{
        .image_width = 1200,
        .aspect_ratio = 16.0 / 9.0,
        .samples_per_pixel = 500,
        .max_depth = 50,

        .vfov = 20,
        .lookfrom = Vec(.{ 13, 2, 3 }),
        .lookat = Vec(.{ 0, 0, 0 }),
        .vup = Vec(.{ 0, 1, 0 }),

        .defocus_angle = 0.6,
        .focus_dist = 10.0,
    };
    const buf = try cam.render(world, alloc, null);
    defer alloc.free(buf);

    // Image
    try stdout.print("P3\n{d} {d}\n255\n", .{ cam.image_width, cam._image_height });
    for (0..cam.image_width * cam._image_height) |i| {
        try writeColor(buf[i], cam.samples_per_pixel, stdout);
    }

    try stderr.print("\nFinished rendering [{d}x{d}:{d}|{d}]\n", .{
        cam.image_width,
        cam._image_height,
        cam.samples_per_pixel,
        cam.max_depth,
    });

    try bw.flush();
    try bwe.flush();
}
