const Vec3t = @import("../Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);

const Ray = @import("../Ray.zig");

const HitRecord = @import("../Objects.zig").HitRecord;

const Self = @This();

albedo: Vec3,

pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    _ = r_in; // unused

    var scatter_direction = rec.normal + Vec3t.randomUnitVec();

    // Catch degenerate scatter direction
    if (Vec3t.nearZero(scatter_direction))
        scatter_direction = rec.normal;

    scattered.* = Ray{ .origin = rec.p, .dir = scatter_direction };
    attenuation.* = self.albedo;
    return true;
}
