const infinity = @import("std").math.inf(f32);

min: f32 = infinity,
max: f32 = -infinity,

const Self = @This();

pub fn contains(self: Self, x: f32) bool {
    return (self.min <= x and x <= self.max);
}

pub fn surrounds(self: Self, x: f32) bool {
    return (self.min < x and x < self.max);
}

pub const Empty = Self{ .min = infinity, .max = -infinity };
pub const Universe = Self{ .min = -infinity, .max = infinity };
