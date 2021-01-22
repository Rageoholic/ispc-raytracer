const std = @import("std");

// There's just 256 different input valus - just use a table.
const srgb8_to_f32_tab = [256]u32{
    0x00000000, 0x399f22b4, 0x3a1f22b4, 0x3a6eb40f, 0x3a9f22b4, 0x3ac6eb61, 0x3aeeb40f, 0x3b0b3e5e,
    0x3b1f22b4, 0x3b33070b, 0x3b46eb61, 0x3b5b518d, 0x3b70f18d, 0x3b83e1c6, 0x3b8fe616, 0x3b9c87fd,
    0x3ba9c9b7, 0x3bb7ad6f, 0x3bc63549, 0x3bd56361, 0x3be539c1, 0x3bf5ba70, 0x3c0373b5, 0x3c0c6152,
    0x3c15a703, 0x3c1f45be, 0x3c293e6b, 0x3c3391f7, 0x3c3e4149, 0x3c494d43, 0x3c54b6c7, 0x3c607eb1,
    0x3c6ca5df, 0x3c792d22, 0x3c830aa8, 0x3c89af9f, 0x3c9085db, 0x3c978dc5, 0x3c9ec7c2, 0x3ca63433,
    0x3cadd37d, 0x3cb5a601, 0x3cbdac20, 0x3cc5e639, 0x3cce54ab, 0x3cd6f7d5, 0x3cdfd010, 0x3ce8ddb9,
    0x3cf22131, 0x3cfb9ac6, 0x3d02a56c, 0x3d0798df, 0x3d0ca7e7, 0x3d11d2b2, 0x3d171965, 0x3d1c7c31,
    0x3d21fb3f, 0x3d2796b5, 0x3d2d4ebe, 0x3d332384, 0x3d39152e, 0x3d3f23e6, 0x3d454fd4, 0x3d4b991f,
    0x3d51ffef, 0x3d58846a, 0x3d5f26b7, 0x3d65e6fe, 0x3d6cc564, 0x3d73c20f, 0x3d7add29, 0x3d810b67,
    0x3d84b795, 0x3d887330, 0x3d8c3e4a, 0x3d9018f6, 0x3d940345, 0x3d97fd4a, 0x3d9c0716, 0x3da020bb,
    0x3da44a4b, 0x3da883d7, 0x3daccd70, 0x3db12728, 0x3db59112, 0x3dba0b3b, 0x3dbe95b5, 0x3dc33092,
    0x3dc7dbe2, 0x3dcc97b6, 0x3dd1641f, 0x3dd6412c, 0x3ddb2eef, 0x3de02d77, 0x3de53cd5, 0x3dea5d19,
    0x3def8e55, 0x3df4d093, 0x3dfa23ea, 0x3dff8864, 0x3e027f09, 0x3e054282, 0x3e080ea5, 0x3e0ae379,
    0x3e0dc107, 0x3e10a755, 0x3e13966c, 0x3e168e53, 0x3e198f11, 0x3e1c98ae, 0x3e1fab32, 0x3e22c6a3,
    0x3e25eb0b, 0x3e29186d, 0x3e2c4ed4, 0x3e2f8e45, 0x3e32d6c8, 0x3e362865, 0x3e398322, 0x3e3ce706,
    0x3e405419, 0x3e43ca62, 0x3e4749e8, 0x3e4ad2b1, 0x3e4e64c6, 0x3e52002b, 0x3e55a4e9, 0x3e595307,
    0x3e5d0a8b, 0x3e60cb7c, 0x3e6495e0, 0x3e6869bf, 0x3e6c4720, 0x3e702e0c, 0x3e741e84, 0x3e781890,
    0x3e7c1c38, 0x3e8014c2, 0x3e82203c, 0x3e84308d, 0x3e8645ba, 0x3e885fc5, 0x3e8a7eb2, 0x3e8ca283,
    0x3e8ecb3d, 0x3e90f8e1, 0x3e932b74, 0x3e9562f8, 0x3e979f71, 0x3e99e0e2, 0x3e9c274e, 0x3e9e72b7,
    0x3ea0c322, 0x3ea31892, 0x3ea57308, 0x3ea7d289, 0x3eaa3718, 0x3eaca0b7, 0x3eaf0f69, 0x3eb18333,
    0x3eb3fc18, 0x3eb67a18, 0x3eb8fd37, 0x3ebb8579, 0x3ebe12e1, 0x3ec0a571, 0x3ec33d2d, 0x3ec5da17,
    0x3ec87c33, 0x3ecb2383, 0x3ecdd00b, 0x3ed081cd, 0x3ed338cc, 0x3ed5f50b, 0x3ed8b68d, 0x3edb7d54,
    0x3ede4965, 0x3ee11ac1, 0x3ee3f16b, 0x3ee6cd67, 0x3ee9aeb6, 0x3eec955d, 0x3eef815d, 0x3ef272ba,
    0x3ef56976, 0x3ef86594, 0x3efb6717, 0x3efe6e02, 0x3f00bd2d, 0x3f02460e, 0x3f03d1a7, 0x3f055ff9,
    0x3f06f108, 0x3f0884d1, 0x3f0a1b57, 0x3f0bb49d, 0x3f0d50a2, 0x3f0eef69, 0x3f1090f2, 0x3f123540,
    0x3f13dc53, 0x3f15862d, 0x3f1732cf, 0x3f18e23b, 0x3f1a9471, 0x3f1c4973, 0x3f1e0143, 0x3f1fbbe1,
    0x3f217950, 0x3f23398f, 0x3f24fca2, 0x3f26c288, 0x3f288b43, 0x3f2a56d5, 0x3f2c253f, 0x3f2df681,
    0x3f2fca9e, 0x3f31a199, 0x3f337b6e, 0x3f355822, 0x3f3737b5, 0x3f391a28, 0x3f3aff7e, 0x3f3ce7b7,
    0x3f3ed2d4, 0x3f40c0d6, 0x3f42b1c0, 0x3f44a592, 0x3f469c4d, 0x3f4895f3, 0x3f4a9284, 0x3f4c9203,
    0x3f4e9470, 0x3f5099cd, 0x3f52a21a, 0x3f54ad59, 0x3f56bb8c, 0x3f58ccb3, 0x3f5ae0cf, 0x3f5cf7e2,
    0x3f5f11ee, 0x3f612ef2, 0x3f634eef, 0x3f6571ec, 0x3f6797e3, 0x3f69c0db, 0x3f6beccd, 0x3f6e1bc4,
    0x3f704db8, 0x3f7282b4, 0x3f74baae, 0x3f76f5b3, 0x3f7933b9, 0x3f7b74cb, 0x3f7db8e0, 0x3f800000,
};

pub fn srgb8ToF32(srgb8: u8) f32 {
    return @bitCast(f32, srgb8_to_f32_tab[srgb8]);
}

pub fn f32ToLinear8(f: f32) u8 {
    return @floatToInt(u8, std.math.round(f * 255));
}

pub fn bitFloat(comptime T: type, comptime int: comptime_int) T {
    const IntType = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = @typeInfo(T).Float.bits } });
    return @bitCast(f32, @as(IntType, int));
}

pub fn f32ToSrgb8Exact(f: f32) u8 {
    var s = @as(f32, undefined);
    if (!(f > 0)) {
        s = 0;
    } else if (f <= 0.0031308) {
        s = 12.92 * f;
    } else if (f < 1) {
        s = 1.055 * std.math.pow(f32, f, 1 / 2.4) - 0.055;
    } else {
        s = 1;
    }
    return @floatToInt(u8, s * 255);
}

const f32_to_srgb8_table = [104]u32{
    0x0073000d, 0x007a000d, 0x0080000d, 0x0087000d, 0x008d000d, 0x0094000d, 0x009a000d, 0x00a1000d,
    0x00a7001a, 0x00b4001a, 0x00c1001a, 0x00ce001a, 0x00da001a, 0x00e7001a, 0x00f4001a, 0x0101001a,
    0x010e0033, 0x01280033, 0x01410033, 0x015b0033, 0x01750033, 0x018f0033, 0x01a80033, 0x01c20033,
    0x01dc0067, 0x020f0067, 0x02430067, 0x02760067, 0x02aa0067, 0x02dd0067, 0x03110067, 0x03440067,
    0x037800ce, 0x03df00ce, 0x044600ce, 0x04ad00ce, 0x051400ce, 0x057b00c5, 0x05dd00bc, 0x063b00b5,
    0x06970158, 0x07420142, 0x07e30130, 0x087b0120, 0x090b0112, 0x09940106, 0x0a1700fc, 0x0a9500f2,
    0x0b0f01cb, 0x0bf401ae, 0x0ccb0195, 0x0d950180, 0x0e56016e, 0x0f0d015e, 0x0fbc0150, 0x10630143,
    0x11070264, 0x1238023e, 0x1357021d, 0x14660201, 0x156601e9, 0x165a01d3, 0x174401c0, 0x182401af,
    0x18fe0331, 0x1a9602fe, 0x1c1502d2, 0x1d7e02ad, 0x1ed4028d, 0x201a0270, 0x21520256, 0x227d0240,
    0x239f0443, 0x25c003fe, 0x27bf03c4, 0x29a10392, 0x2b6a0367, 0x2d1d0341, 0x2ebe031f, 0x304d0300,
    0x31d105b0, 0x34a80555, 0x37520507, 0x39d504c5, 0x3c37048b, 0x3e7c0458, 0x40a8042a, 0x42bd0401,
    0x44c20798, 0x488e071e, 0x4c1c06b6, 0x4f76065d, 0x52a50610, 0x55ac05cc, 0x5892058f, 0x5b590559,
    0x5e0c0a23, 0x631c0980, 0x67db08f6, 0x6c55087f, 0x70940818, 0x74a007bd, 0x787d076c, 0x7c330723,
};

pub fn f32ToSrgb8(f: f32) u8 {
    const almostone = bitFloat(f32, 0x3f7fffff); // 1-eps)
    const minval = bitFloat(f32, (127 - 13) << 23);

    const clampf = std.math.clamp(f, minval, almostone);
    const i = (@bitCast(u32, clampf) - @bitCast(u32, minval)) >> 20;
    const tab = f32_to_srgb8_table[i];
    const bias = (tab >> 16) << 9;
    const scale = tab & 0xffff;
    const t = (@bitCast(u32, clampf) >> 12) & 0xFF;
    return @intCast(u8, (bias + scale * t) >> 16);
}
pub fn rsqrt(t: anytype) @TypeOf(t) {
    return 1 / @sqrt(t);
}

pub fn lerp(a: anytype, b: @TypeOf(a), t: anytype) @TypeOf(a) {
    return a.mulScalar(t).add(b.mulScalar(1 - t));
}

pub fn Vec3(comptime T: type) type {
    return extern union {
        col: extern struct { r: T, g: T, b: T },
        pos: extern struct { x: T, y: T, z: T },
        arr: [3]T,

        pub fn init(a: T, b: T, c: T) @This() {
            return @This(){ .arr = [3]T{ a, b, c } };
        }

        pub fn dot(v1: @This(), v2: @This()) T {
            var ret = @as(T, 0);
            for (v1.arr) |_, i| {
                ret += v1.arr[i] * v2.arr[i];
            }
            return ret;
        }

        pub fn add(v1: @This(), v2: @This()) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] + v2.arr[i];
            }
            return ret;
        }

        pub fn sub(v1: @This(), v2: @This()) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] - v2.arr[i];
            }
            return ret;
        }
        pub fn mul(v1: @This(), v2: @This()) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] * v2.arr[i];
            }
            return ret;
        }

        pub fn div(v1: @This(), v2: @This()) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] / v2.arr[i];
            }
            return ret;
        }

        pub fn addScalar(v1: @This(), scalar: T) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] + scalar;
            }
            return ret;
        }

        pub fn subScalar(v1: @This(), scalar: T) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] - scalar;
            }
            return ret;
        }

        pub fn divScalar(v1: @This(), scalar: T) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] / scalar;
            }
            return ret;
        }

        pub fn mulScalar(v1: @This(), scalar: T) @This() {
            var ret = @as(@This(), undefined);
            for (ret.arr) |*s, i| {
                s.* = v1.arr[i] * scalar;
            }
            return ret;
        }

        pub fn squareLen(this: @This()) T {
            var square_len = @as(T, 0);
            for (this.arr) |i| {
                square_len += i * i;
            }
            return square_len;
        }

        pub fn normalize(this: @This()) @This() {
            var square_len = this.squareLen();
            return this.mulScalar(rsqrt(square_len));
        }
    };
}

pub fn Ray(comptime T: type) type {
    return struct {
        p: Vec3(T),
        dir: Vec3(T), // Must be normalized
        pub fn pointAtDistance(this: @This(), t: T) Vec3(T) {
            return this.p.add(this.dir.mulScalar(t));
        }
    };
}

pub fn randomInUnitSphere(rng: *std.rand.Random) Vec3(f32) {
    while (true) {
        const v = Vec3(f32).init(
            rng.float(f32) * 2 - 1,
            rng.float(f32) * 2 - 1,
            rng.float(f32) * 2 - 1,
        );
        if (v.squareLen() < 1) {
            return v;
        }
    }
}

pub fn randomUnitVec(rng: *std.rand.Random) Vec3(f32) {
    return Vec3(f32).init(
        rng.float(f32) * 2 - 1,
        rng.float(f32) * 2 - 1,
        rng.float(f32) * 2 - 1,
    ).normalize();
}

pub fn randomInUnitHemisphere(rng: *std.rand.Random, n: Vec3(f32)) Vec3(f32) {
    const randVec = randomInUnitSphere(rng);
    if (randVec.dot(n) > 0) {
        return randVec;
    } else {
        return randVec.mulScalar(-1);
    }
}
