const Vec3t = @import("../Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);

const Ray = @import("../Ray.zig");

const HitRecord = @import("../Objects.zig").HitRecord;

const Self = @This();

albedo: Vec3,

pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    const reflected = Vec3t.reflect(r_in.dir, rec.normal);

    scattered.* = Ray{ .origin = rec.p, .dir = reflected };

    attenuation.* = self.albedo;
    return true;
}
