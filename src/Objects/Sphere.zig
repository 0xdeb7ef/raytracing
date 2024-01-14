const Vec3 = @Vector(3, f32);
const Vec3t = @import("../Vector.zig").Vector(3, f32);
const Vec = Vec3t.init;

const Ray = @import("../Ray.zig");

const HitRecord = @import("../Objects.zig").HitRecord;

const interval = @import("../utils/interval.zig");

center: Vec3,
radius: f32,

const Self = @This();

pub fn hit(self: Self, ray: Ray, ray_t: interval, rec: *HitRecord) bool {
    const oc = ray.origin - self.center;
    const a = Vec3t.mag_squared(ray.dir);
    const half_b = Vec3t.dot(oc, ray.dir);
    const c = Vec3t.mag_squared(oc) - (self.radius * self.radius);
    const discr = (half_b * half_b) - (a * c);

    if (discr < 0) return false;
    const sqrtd = @sqrt(discr);

    // Find the nearest root that lies in the acceptable range.
    var root = (-half_b - sqrtd) / a;
    if (!ray_t.surrounds(root)) {
        root = (-half_b + sqrtd) / a;
        if (!ray_t.surrounds(root))
            return false;
    }

    rec.t = root;
    rec.p = ray.at(rec.t);
    const outward_normal = (rec.p - self.center) / Vec(self.radius);
    rec.set_face_normal(ray, outward_normal);

    return true;
}
