const Ray = @import("Ray.zig");

const Vec3t = @import("Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const utils = @import("utils/utils.zig");
const interval = utils.interval;

const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;

// Objects
pub const Sphere = @import("Objects/Sphere.zig");

pub const HitRecord = struct {
    p: Vec3 = undefined,
    normal: Vec3 = undefined,
    t: f32 = undefined,
    front_face: bool = undefined,

    pub fn set_face_normal(self: *HitRecord, ray: Ray, outward_normal: Vec3) void {
        // Sets the hit record normal vector.
        // NOTE: the parameter `outward_normal` is assumed to have unit length.

        self.front_face = Vec3t.dot(ray.dir, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else -outward_normal;
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,
    none,

    pub fn hit(self: Hittable, ray: Ray, ray_t: interval, rec: *HitRecord) bool {
        return switch (self) {
            Hittable.sphere => |s| s.hit(ray, ray_t, rec),
            else => @panic("no hittable defined"),
        };
    }
};

pub const HittableList = struct {
    const Self = @This();

    objects: ArrayList(Hittable) = undefined,

    pub fn init(self: *Self, allocator: Allocator) void {
        self.objects = ArrayList(Hittable).init(allocator);
    }
    pub fn clear(self: Self) void {
        self.objects.clearAndFree();
    }
    pub fn add(self: *Self, obj: Hittable) !void {
        try self.objects.append(obj);
    }
    pub fn hit(self: Self, ray: Ray, ray_t: interval, rec: *HitRecord) bool {
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |o| {
            if (o.hit(ray, interval{ .min = ray_t.min, .max = closest_so_far }, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;

                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};
