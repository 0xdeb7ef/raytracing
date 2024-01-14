const rando = @import("std").rand.DefaultPrng;
const nanoTimestamp = @import("std").time.nanoTimestamp;

pub fn random(comptime T: type) T {
    const seed = @as(u64, @truncate(@as(u128, @bitCast(nanoTimestamp()))));
    var rand = rando.init(seed);

    return switch (@typeInfo(T)) {
        .Int => rand.random().int(T),
        .Float => rand.random().float(T),
        else => @compileError("unsupported type"),
    };
}

pub inline fn randomI(comptime T: type, min: T, max: T) T {
    return min + (max - min) * random(T);
}

const std = @import("std");
