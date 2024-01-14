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
    };
}
