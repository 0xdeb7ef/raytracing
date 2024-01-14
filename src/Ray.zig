pub fn Ray(comptime dim: usize, comptime T: type) type {
    const Vec = @Vector(dim, T);

    return struct {
        const Self = @This();

        origin: Vec,
        dir: Vec,

        pub fn init(origin: Vec, dir: Vec) Self {
            return Self{
                .origin = origin,
                .dir = dir,
            };
        }

        pub fn at(self: Self, t: T) Vec {
            return self.origin + (@as(Vec, @splat(t)) * self.dir);
        }
    };
}
