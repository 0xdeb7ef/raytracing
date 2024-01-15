const testing = @import("std").testing;
const sqrt1_2 = @import("std").math.sqrt1_2;

const utils = @import("utils/utils.zig");
const random = utils.random;
const randomI = utils.randomI;

pub fn Vector(comptime size: usize, comptime T: type) type {
    return struct {
        const Vec = @Vector(size, T);

        pub inline fn init(data: anytype) Vec {
            switch (@TypeOf(data)) {
                T, comptime_int, comptime_float => return @splat(data),
                else => return data,
            }
        }

        pub inline fn mag(u: Vec) f32 {
            return @sqrt(mag_squared(u));
        }
        pub inline fn mag_squared(u: Vec) T {
            return @reduce(.Add, (u * u));
        }

        pub inline fn unitVector(u: Vec) Vec {
            return u / @as(Vec, @splat(mag(u)));
        }

        pub inline fn dot(u: Vec, v: Vec) T {
            var sum: T = 0;
            comptime var i: usize = 0;
            inline while (i < size) : (i += 1) {
                sum += u[i] * v[i];
            }
            return sum;
        }

        pub inline fn cross(u: Vec, v: Vec) Vec {
            comptime {
                if (size != 3) @panic("cross product of vectors is only implemented for size 3 at the moment");
            }
            // TODO - Implement for n size
            return .{
                u[1] * v[2] - u[2] * v[1],
                u[2] * v[0] - u[0] * v[2],
                u[0] * v[1] - u[1] * v[0],
            };
        }

        pub fn randomVec() Vec {
            return .{
                random(T),
                random(T),
                random(T),
            };
        }
        pub fn randomIVec(min: T, max: T) Vec {
            return .{
                randomI(T, min, max),
                randomI(T, min, max),
                randomI(T, min, max),
            };
        }

        pub inline fn randomInSphere() Vec {
            while (true) {
                const p = randomIVec(-1, 1);
                if (mag_squared(p) < 1)
                    return p;
            }
        }
        pub inline fn randomUnitVec() Vec {
            return unitVector(randomInSphere());
        }
        pub inline fn randomOnHemisphere(normal: Vec) Vec {
            const on_unit_sphere = randomUnitVec();
            if (dot(on_unit_sphere, normal) > 0.0) {
                return on_unit_sphere;
            } else {
                return -on_unit_sphere;
            }
        }
    };
}

test "init" {
    const Vec3 = Vector(3, f32);

    const vec1 = Vec3.init(0);
    const vec2 = Vec3.init(.{ 1, 2, 3 });
    const vec3 = @Vector(3, f32){ 0, 0, 0 };
    const vec4 = @Vector(3, f32){ 1, 2, 3 };

    comptime var i = 0;
    inline while (i < 3) : (i += 1) {
        try testing.expectEqual(0, vec1[i]);
        try testing.expectEqual(0, vec3[i]);
    }

    i = 0;
    inline while (i < 3) : (i += 1) {
        try testing.expectEqual(vec3[i], vec1[i]);
        try testing.expectEqual(vec4[i], vec2[i]);
    }
}

test "magnitude of a vector" {
    const Vec2 = Vector(2, f32);
    const vec1 = Vec2.init(.{ 3, 4 });

    try testing.expectEqual(5, Vec2.mag(vec1));
}

test "unit vector" {
    const Vec2 = Vector(2, f32);
    const vec1 = Vec2.init(5);

    comptime var i = 0;
    inline while (i < 2) : (i += 1) {
        try testing.expectEqual(sqrt1_2, Vec2.unitVector(vec1)[i]);
    }
}

test "dot product" {
    const Vec3 = Vector(3, f32);
    const vec1 = Vec3.init(.{ 1, 2, 3 });
    const vec2 = Vec3.init(.{ 4, -5, 6 });

    try testing.expectEqual(12, Vec3.dot(vec1, vec2));

    const vec3 = Vec3.init(.{ 6, -1, 3 });
    const vec4 = Vec3.init(.{ 4, 18, -2 });

    try testing.expectEqual(0, Vec3.dot(vec3, vec4));
}

test "cross product" {
    const Vec3 = Vector(3, f32);
    const vec1 = Vec3.init(.{ 3, -3, 1 });
    const vec2 = Vec3.init(.{ 4, 9, 2 });
    const vec3 = @Vector(3, f32){ -15, -2, 39 };

    comptime var i = 0;
    inline while (i < 3) : (i += 1) {
        try testing.expectEqual(vec3[i], Vec3.cross(vec1, vec2)[i]);
    }
}
