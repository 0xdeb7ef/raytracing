const Vec3 = @Vector(3, f32);
const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec = Vec3t.init;

const Ray = @import("Ray.zig");

const Objects = @import("Objects.zig");
const HitRecord = Objects.HitRecord;
const ObjectList = Objects.ObjectList;

const utils = @import("utils/utils.zig");
const interval = utils.interval;
const infinity = utils.infinity;
const writeColor = utils.writeColor;
const random = utils.random;
const degToRad = utils.degToRad;

const std = @import("std");
const Allocator = std.mem.Allocator;
const Pool = std.Thread.Pool;
const tan = std.math.tan;

/// Ratio of image width over height
aspect_ratio: f32 = 1.0,
/// Rendered image width in pixels
image_width: u32 = 100,
/// Count of random samples for each pixel
samples_per_pixel: u32 = 10,
/// Maximum number of ray bounces into scene
max_depth: u32 = 10,

/// Vertical view angle (field of view)
vfov: f32 = 90.0,
/// Point camera is looking from
lookfrom: Vec3 = Vec(.{ 0, 0, -1 }),
/// Point camera is looking at
lookat: Vec3 = Vec(.{ 0, 0, 0 }),
/// Camera-relative "up" direction
vup: Vec3 = Vec(.{ 0, 1, 0 }),

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
/// Camera frame basis vectors
_u: Vec3 = undefined,
_v: Vec3 = undefined,
_w: Vec3 = undefined,

const Self = @This();

pub fn render(self: *Self, world: ObjectList, allocator: Allocator, n_threads: ?u32) ![][3]f32 {
    self.init();

    var buf = try allocator.alloc([3]f32, self.image_width * self._image_height);

    // Thread Pool
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator, .n_jobs = n_threads });
    defer pool.deinit();

    var j: usize = 0;
    while (j < self._image_height) : (j += 1) {
        try pool.spawn(Worker, .{
            self,
            j,
            self.image_width,
            self.samples_per_pixel,
            self.max_depth,
            &buf,
            world,
        });
    }
    return buf;
}

fn Worker(
    self: *Self,
    j: usize,
    image_width: u32,
    samples_per_pixel: u32,
    max_depth: u32,
    buf: *[][3]f32,
    world: ObjectList,
) void {
    var i: usize = 0;
    while (i < image_width) : (i += 1) {
        var sample: usize = 0;
        while (sample < samples_per_pixel) : (sample += 1) {
            const r = self.getRay(i, j);
            buf.*[(j * image_width) + i] += rayColor(r, max_depth, world);
        }
    }
    return;
}

fn init(self: *Self) void {
    // image_height = image_width / aspect_ratio
    self._image_height = @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio);
    // make sure image_height is at least 1
    self._image_height = if (self._image_height < 1) 1 else self._image_height;

    self._center = self.lookfrom;

    // Determine viewport dimensions
    const focal_length = Vec3t.mag(self.lookfrom - self.lookat);
    const theta = degToRad(f32, self.vfov);
    const h = tan(theta / 2.0);
    const viewport_height = 2.0 * h * focal_length;
    // viewport_width = viewport_height * (image_width / image_height)
    const viewport_width = viewport_height * (@as(f32, @floatFromInt(self.image_width)) / @as(f32, @floatFromInt(self._image_height)));

    // Calculate the u,v,w unit basis vector for the camera coordinate frame
    self._w = Vec3t.unitVector(self.lookfrom - self.lookat);
    self._u = Vec3t.unitVector(Vec3t.cross(self.vup, self._w));
    self._v = Vec3t.cross(self._w, self._u);

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec(viewport_width) * self._u;
    const viewport_v = Vec(viewport_height) * -self._v;

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    // pixel_delta_u = viewport_u / image_width
    self._pixel_delta_u = viewport_u / Vec(@as(f32, @floatFromInt(self.image_width)));
    // pixel_delta_v = viewport_v / image_height
    self._pixel_delta_v = viewport_v / Vec(@as(f32, @floatFromInt(self._image_height)));

    // Calculate the location of the upper left pixel
    // viewport_upper_left = center - focal_length*w - viewport_u/2 - viewport_v/2
    const viewport_upper_left = self._center - (Vec(focal_length) * self._w) - (viewport_u / Vec(2)) - (viewport_v / Vec(2));
    // pixel00_loc = viewport_upper_left + 0.5*(pixel_delta_u + pixel_delta_v)
    self._pixel00_loc = viewport_upper_left + (Vec(0.5) * (self._pixel_delta_u + self._pixel_delta_v));
}

fn getRay(self: Self, i: usize, j: usize) Ray {
    // pixel_center = pixel00_loc + i*pixel_delta_u + j*pixel_delta_v
    const pixel_center = self._pixel00_loc + (Vec(@as(f32, @floatFromInt(i))) * self._pixel_delta_u) + (Vec(@as(f32, @floatFromInt(j))) * self._pixel_delta_v);
    const pixel_sample = pixel_center + self.pixelSampleSquare();

    return Ray{ .origin = self._center, .dir = pixel_sample - self._center };
}

fn pixelSampleSquare(self: Self) Vec3 {
    const px = -0.5 + random(f32);
    const py = -0.5 + random(f32);
    return (Vec(px) * self._pixel_delta_u) + (Vec(py) * self._pixel_delta_v);
}

fn rayColor(ray: Ray, depth: u32, world: ObjectList) Vec3 {
    var rec: HitRecord = undefined;

    if (depth <= 0)
        return Vec(0);

    if (world.hit(ray, interval{ .min = 0.001, .max = infinity }, &rec)) {
        var scattered: Ray = undefined;
        var attenuation: Vec3 = undefined;

        if (rec.mat.scatter(ray, rec, &attenuation, &scattered))
            return attenuation * rayColor(scattered, depth - 1, world);
        return Vec(0);
    }

    // world background color
    const unit_direction = Vec3t.unitVector(ray.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    // (1-a)*{1,1,1} + a*{0.5,0.7,1.0}
    return Vec(1 - a) * Vec(1) + Vec(a) * Vec(.{ 0.5, 0.7, 1.0 });
}
