const Vec3 = @Vector(3, f32);

origin: Vec3,
dir: Vec3,

const Self = @This();

pub fn at(self: Self, t: f32) Vec3 {
    return self.origin + (@as(Vec3, @splat(t)) * self.dir);
}
