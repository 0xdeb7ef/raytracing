const std = @import("std");
const stdout_file = std.io.getStdOut().writer();
const log = std.log;

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const colorUtils = @import("utils/color.zig");

const Ray = @import("Ray.zig").Ray(3, f32);

fn hit_sphere(center: Vec3, radius: f32, ray: Ray) f32 {
    const oc = ray.origin - center;
    const a = Vec3t.mag_squared(ray.dir);
    const half_b = Vec3t.dot(oc, ray.dir);
    const c = Vec3t.mag_squared(oc) - radius * radius;

    const discr = half_b * half_b - a * c;

    if (discr < 0) {
        return -1.0;
    } else {
        return (-half_b - @sqrt(discr)) / a;
    }
}

fn ray_color(ray: Ray) Vec3 {
    const t = hit_sphere(Vec(.{ 0, 0, -1 }), 0.5, ray);
    if (t > 0.0) {
        const N = Vec3t.unitVector(ray.at(t) - Vec(.{ 0, 0, -1 }));
        return Vec(0.5) * (N + Vec(1));
    }

    const unit_direction = Vec(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return (Vec(1 - a) * Vec(1)) + (Vec(a) * Vec(.{ 0.5, 0.7, 1.0 }));
}

pub fn main() !void {
    // for now, let's use stdout
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Image
    const aspect_ratio = 16.0 / 9.0;
    const image_width = 400;

    // Calculate image height, ensuring it is at least 1
    const image_height_tmp = @as(comptime_int, @intFromFloat(@as(comptime_float, @floatFromInt(image_width)) / aspect_ratio));
    const image_height = if (image_height_tmp < 1) 1 else image_height_tmp;

    // Camera
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(comptime_float, @floatFromInt(image_width)) / @as(comptime_float, @floatFromInt(image_height)));
    const camera_center = Vec(0);

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec(.{ viewport_width, 0, 0 });
    const viewport_v = Vec(.{ 0, -viewport_height, 0 });

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u / Vec(image_width);
    const pixel_delta_v = viewport_v / Vec(image_height);

    // Calculate the location of the upper left pixel
    const viewport_upper_left = camera_center - Vec(.{ 0, 0, focal_length }) - (viewport_u / Vec(2)) - (viewport_v / Vec(2));
    const pixel00_loc = viewport_upper_left + (Vec(0.5) * (pixel_delta_u + pixel_delta_v));

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    var j: usize = 0;
    while (j < image_height) : (j += 1) {
        std.log.info("Scanlines remaining: [{d:3}/{d:3}]", .{ image_height - j, image_height });
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            const pixel_center = pixel00_loc + (Vec(@as(f32, @floatFromInt(i))) * pixel_delta_u) + (Vec(@as(f32, @floatFromInt(j))) * pixel_delta_v);
            const ray_direction = pixel_center - camera_center;
            const r = Ray.init(camera_center, ray_direction);

            const color = ray_color(r);
            try colorUtils.writeColor(color, stdout);
        }
    }
    std.log.info("Done!", .{});
    try bw.flush();
}
