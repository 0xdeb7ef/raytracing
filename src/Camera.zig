const Vec3 = @Vector(3, f32);
const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec = Vec3t.init;

const Ray = @import("Ray.zig");

const Objects = @import("Objects.zig");
const HitRecord = Objects.HitRecord;
const Hittable = Objects.Hittable;
const HittableList = Objects.HittableList;

const utils = @import("utils/utils.zig");
const interval = utils.interval;
const infinity = utils.infinity;
const writeColor = utils.writeColor;

const log = @import("std").log;

/// Ratio of image width over height
aspect_ratio: f32 = 1.0,
/// Rendered image width in pixels
image_width: u32 = 100,

// private
/// Rendered image height
_image_height: u32 = undefined,
/// Camera center
_center: Vec3 = undefined,
/// Location of pixel 0, 0
_pixel00_loc: Vec3 = undefined,
/// Offset to pixel to the right
_pixel_delta_u: Vec3 = undefined,
/// Offset to pixel to the left
_pixel_delta_v: Vec3 = undefined,

const Self = @This();

pub fn render(self: *Self, world: HittableList, stdout: anytype) !void {
    self.init();

    try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self._image_height });

    var j: usize = 0;
    while (j < self._image_height) : (j += 1) {
        log.info("Scanlines remaining: [{d:3}/{d:3}]", .{ self._image_height - j, self._image_height });
        var i: usize = 0;
        while (i < self.image_width) : (i += 1) {
            const pixel_center = self._pixel00_loc + (Vec(@as(f32, @floatFromInt(i))) * self._pixel_delta_u) + (Vec(@as(f32, @floatFromInt(j))) * self._pixel_delta_v);
            const ray_direction = pixel_center - self._center;
            const r = Ray{ .origin = self._center, .dir = ray_direction };

            const color = ray_color(r, world);
            try writeColor(color, stdout);
        }
    }
    log.info("Done!", .{});
}

fn init(self: *Self) void {
    self._image_height = @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio);
    self._image_height = if (self._image_height < 1) 1 else self._image_height;

    self._center = Vec(0);

    // Determine viewport dimensions
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(f32, @floatFromInt(self.image_width)) / @as(f32, @floatFromInt(self._image_height)));

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec(.{ viewport_width, 0, 0 });
    const viewport_v = Vec(.{ 0, -viewport_height, 0 });

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    self._pixel_delta_u = viewport_u / Vec(@as(f32, @floatFromInt(self.image_width)));
    self._pixel_delta_v = viewport_v / Vec(@as(f32, @floatFromInt(self._image_height)));

    // Calculate the location of the upper left pixel
    const viewport_upper_left = self._center - Vec(.{ 0, 0, focal_length }) - (viewport_u / Vec(2)) - (viewport_v / Vec(2));
    self._pixel00_loc = viewport_upper_left + (Vec(0.5) * (self._pixel_delta_u + self._pixel_delta_v));
}

fn ray_color(ray: Ray, world: HittableList) Vec3 {
    var rec: HitRecord = undefined;
    if (world.hit(ray, interval{ .min = 0, .max = infinity }, &rec)) {
        return Vec(0.5) * (rec.normal + Vec(1));
    }

    const unit_direction = Vec(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return (Vec(1 - a) * Vec(1)) + (Vec(a) * Vec(.{ 0.5, 0.7, 1.0 }));
}
