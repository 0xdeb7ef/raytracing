const Vec3 = @Vector(3, f32);

const Ray = @import("Ray.zig");

const HitRecord = @import("Objects.zig").HitRecord;

// Materials
pub const Lambertian = @import("Materials/Lambertian.zig");
pub const Metal = @import("Materials/Metal.zig");

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    none,

    pub fn scatter(self: Material, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        return switch (self) {
            Material.lambertian => |m| m.scatter(r_in, rec, attenuation, scattered),
            Material.metal => |m| m.scatter(r_in, rec, attenuation, scattered),
            else => @panic("no material defined"),
        };
    }
};
