const Vec3t = @import("../Vector.zig").Vector(3, f32);
const Vec3 = @Vector(3, f32);
const Vec = Vec3t.init;

const Ray = @import("../Ray.zig");

const HitRecord = @import("../Objects.zig").HitRecord;

const random = @import("../utils/utils.zig").random;

const pow = @import("std").math.pow;

const Self = @This();

ir: f32,

pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    attenuation.* = Vec(1);
    const refration_ratio = if (rec.front_face) (1.0 / self.ir) else self.ir;

    const unit_direction = Vec3t.unitVector(r_in.dir);

    const cos_theta = @min(Vec3t.dot(-unit_direction, rec.normal), 1.0);
    const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

    const cannot_refract = refration_ratio * sin_theta > 1.0;
    const direction: Vec3 = dir: {
        if (cannot_refract or reflectance(cos_theta, refration_ratio) > random(f32)) {
            break :dir Vec3t.reflect(unit_direction, rec.normal);
        } else {
            break :dir Vec3t.refract(unit_direction, rec.normal, refration_ratio);
        }
    };

    scattered.* = Ray{ .origin = rec.p, .dir = direction };
    return true;
}

fn reflectance(cosine: f32, ref_idx: f32) f32 {
    // Use Schlick's approximation for reflectance.
    var r0 = (1 - ref_idx) / (1 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1 - r0) * pow(f32, (1 - cosine), 5);
}
