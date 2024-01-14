const std = @import("std");

// Constants
pub const infinity = std.math.inf(f32);
pub const pi: f32 = std.math.pi;

// Utility
pub const degToRad = std.math.degreesToRadians;

// Color
pub const writeColor = @import("color.zig").writeColor;

// Interval
pub const interval = @import("interval.zig");
