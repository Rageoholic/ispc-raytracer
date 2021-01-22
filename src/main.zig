const std = @import("std");
const math = @import("math.zig");
const daedelus = @import("daedelus.zig");
const Vec3 = math.Vec3;
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;

const Vec3f = Vec3(f32);

const Material = union(enum) {
    Metal: struct {
        reflectCol: Vec3f,
        emitCol: Vec3f,
        reflectance: f32,
    },
};

const Sphere = struct {
    o: Vec3f,
    r: f32,
    m: Material,
};

const OutputType = enum { Linear, Srgb };

fn f32ToOut8(f: f32, out_type: OutputType) u8 {
    return switch (out_type) {
        .Srgb => math.f32ToSrgb8(f),
        .Linear => math.f32ToLinear8(f),
    };
}

extern fn raytraceIspc(u32, u32, [*]daedelus.Pixel, usize, [*]const ExternSphere) void;
const HitRecord = struct {
    p: Vec3f,
    n: Vec3f,
    t: f32,
    m: Material,
};

pub const ExternSphere = extern struct { o: Vec3f, r: f32 };

fn sphereToExternSphere(s: Sphere) ExternSphere {
    return .{ .o = s.o, .r = s.r };
}

fn reflect(v: Vec3f, n: Vec3f) Vec3f {
    return v.sub(n.mulScalar(2 * v.dot(n)));
}

fn hitSphere(s: Sphere, r: math.Ray(f32)) ?HitRecord {
    const oc =
        r.p.sub(s.o);
    const a = r.dir.squareLen();
    const half_b =
        oc.dot(r.dir);
    const c = oc.dot(oc) - (s.r * s.r);
    const discriminant = half_b * half_b - a * c;
    if (discriminant < 0) {
        return null;
    } else {
        const t1 = -half_b - @sqrt(discriminant) / a;
        const t2 = -half_b + @sqrt(discriminant) / a;
        if (t1 > 0.001) {
            const p = r.pointAtDistance(t1);
            const n = p.sub(s.o).normalize();
            return HitRecord{
                .p = p,
                .n = n,
                .t = t1,
                .m = s.m,
            };
        } else if (t2 > 0.001) {
            const p = r.pointAtDistance(t2);
            const n = p.sub(s.o).mulScalar(-1).normalize();
            return HitRecord{
                .p = p,
                .n = n,
                .t = t2,
                .m = s.m,
            };
        } else {
            return null;
        }
    }
}

fn rayColor(r: math.Ray(f32), spheres: []const Sphere, rng: *Random) Vec3f {
    const max_bounce_count = 8;
    var iter = ForwardInterator(u32).init(0, max_bounce_count, 1);
    var col = Vec3f.init(0, 0, 0);
    var accum = Vec3f.init(1, 1, 1);
    var ray = r;
    while (iter.next()) |_| {
        var min_t = std.math.inf_f32;
        var best_hit = @as(?HitRecord, null);
        for (spheres) |s| {
            if (hitSphere(s, ray)) |hit| {
                if (hit.t < min_t) {
                    best_hit = hit;
                    min_t = hit.t;
                }
            }
        }
        if (best_hit) |h| {
            switch (h.m) {
                .Metal => |m| {
                    const pure_bounce = reflect(ray.dir, h.n);
                    const random_bounce = h.n.add(math.randomInUnitHemisphere(rng, h.n));
                    var direction = math.lerp(pure_bounce, random_bounce, m.reflectance);
                    ray = math.Ray(f32){ .p = h.p, .dir = direction.normalize() };
                    col = col.add(m.emitCol.mul(accum));
                    accum = accum.mul(m.reflectCol);
                },
            }
        } else {
            const t = ray.dir.pos.y * 0.5 + 0.5;
            const white = Vec3f.init(1, 1, 1);
            const blue = Vec3f.init(0.5, 0.7, 1);
            const background = math.lerp(blue, white, t);

            col = col.add(background.mul(accum));
            break;
        }
    }
    return col;
}

fn raytraceRegion(
    bitmap: *daedelus.Bitmap,
    spheres: []const Sphere,
    full_image_offset_x: usize,
    full_image_offset_y: usize,
    full_image_width: usize,
    full_image_height: usize,
    camera_pos: Vec3f,
    rng: *Random,
    out_type: OutputType,
) void {
    const focal_length = 1;
    const aspect = @intToFloat(f32, full_image_width) / @intToFloat(f32, full_image_height);
    const view_width = 2.0;
    const view_height = view_width / aspect;

    const horizontal = Vec3f.init(view_width, 0, 0);
    const vertical = Vec3f.init(0, view_height, 0);
    const upper_left_corner = vertical.divScalar(2).sub(horizontal.divScalar(2)).sub(Vec3f.init(0, 0, focal_length));

    var row_iterator = bitmap.rowIterator();
    while (row_iterator.next()) |row| {
        for (row.pixels) |*p, i| {
            {
                const sample_count = 25;
                var iterator = ForwardInterator(u32).init(0, sample_count, 1);
                var col = Vec3f.init(0, 0, 0);
                while (iterator.next()) |_| {
                    const u =
                        (@intToFloat(f32, i + bitmap.x_offset - full_image_offset_x) +
                        rng.float(f32)) /
                        @intToFloat(f32, full_image_width - 1);
                    const v =
                        (@intToFloat(f32, row.row + bitmap.y_offset - full_image_offset_y) +
                        rng.float(f32)) /
                        @intToFloat(f32, full_image_height - 1);
                    const ray = math.Ray(f32){
                        .dir = upper_left_corner.add(horizontal.mulScalar(u)).sub(
                            vertical.mulScalar(v),
                        ).normalize(),
                        .p = camera_pos,
                    };
                    col = col.add(rayColor(ray, spheres, rng));
                }
                p.* = .{
                    .comp = .{
                        .r = f32ToOut8(col.col.r / sample_count, out_type),
                        .g = f32ToOut8(col.col.g / sample_count, out_type),
                        .b = f32ToOut8(col.col.b / sample_count, out_type),
                        .a = 255,
                    },
                };
            }
        }
    }
}

const RaytraceRegionThreadContext = struct {
    bmp: *daedelus.Bitmap,
    full_image_width: usize,
    full_image_height: usize,
    full_image_offset_x: usize,
    full_image_offset_y: usize,
    camera_pos: Vec3f,
    spheres: []const Sphere,
    rng_seed: u64,
    out_type: OutputType,
};

fn raytraceRegionThread(c: RaytraceRegionThreadContext) void {
    var r = std.rand.DefaultPrng.init(c.rng_seed);
    raytraceRegion(
        c.bmp,
        c.spheres,
        c.full_image_offset_x,
        c.full_image_offset_y,
        c.full_image_width,
        c.full_image_height,
        c.camera_pos,
        &r.random,
        c.out_type,
    );
}

fn raytraceZigScalar(
    bitmap: *daedelus.Bitmap,
    spheres: []const Sphere,
    camera_pos: Vec3f,
    out_type: OutputType,
) !void {
    var sub_bitmaps = @as([16]daedelus.Bitmap, undefined);
    var threads = @as([sub_bitmaps.len]*std.Thread, undefined);
    const n = std.math.sqrt(sub_bitmaps.len);
    std.debug.assert(n * n == sub_bitmaps.len);
    for (sub_bitmaps) |*b, i| {
        b.* = bitmap.subBitmap(bitmap.width / n * (i % n), bitmap.height / n * (i / n), bitmap.width / n, bitmap.height / n);
        threads[i] = try std.Thread.spawn(RaytraceRegionThreadContext{
            .bmp = b,
            .full_image_width = bitmap.width,
            .full_image_height = bitmap.height,
            .full_image_offset_x = 0,
            .full_image_offset_y = 0,
            .camera_pos = camera_pos,
            .spheres = spheres,
            .out_type = out_type,
            .rng_seed = i,
        }, raytraceRegionThread);
    }
    for (threads) |t| {
        t.wait();
    }
}

fn renderToBitmap(
    allocator: *Allocator,
    bitmap: *daedelus.Bitmap,
    spheres: []const Sphere,
    camera_pos: Vec3f,
    out_type: OutputType,
) !void {
    const use_ispc = false;
    if (use_ispc) {
        const espheres = try allocator.alloc(ExternSphere, spheres.len);
        defer allocator.free(espheres);
        for (espheres) |*s, i| {
            s.* = sphereToExternSphere(spheres[i]);
        }
        raytraceIspc(bitmap.width, bitmap.height, bitmap.pixels.ptr, espheres.len, espheres.ptr);
    } else {
        try raytraceZigScalar(bitmap, spheres, camera_pos, out_type);
    }
}

fn ForwardInterator(comptime T: type) type {
    return struct {
        steps: usize = 0,
        low: T,
        high: T,
        step: T,
        pub fn init(low: T, high: T, step: T) @This() {
            std.debug.assert(low < high);
            return .{ .low = low, .high = high, .step = step };
        }
        pub fn next(this: *@This()) ?T {
            const i = @intCast(T, this.steps * this.step + this.low);
            if (i < this.high) {
                this.steps += 1;
                return i;
            } else {
                return null;
            }
        }
    };
}

const default_output_type = .Srgb;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;
    var daedelus_instance = daedelus.Instance.init(allocator, "ispc_raytracer") catch |err| {
        daedelus.fatalErrorMessage(allocator, "Couldn't create instance", "Fatal error");
        return;
    };
    defer daedelus_instance.deinit();

    const window = daedelus_instance.createWindow(
        "ispc-raytracer",
        800,
        400,
        null,
        null,
        .{ .resizable = false },
    ) catch {
        daedelus.fatalErrorMessage(allocator, "Couldn't create window", "Fatal error");
        return;
    };
    defer window.close();

    const window_dim = window.getSize();
    window.show(); // TODO: show loading screen of some kind?

    var bitmap = daedelus.Bitmap.create(allocator, window_dim.width, window_dim.height, .TopDown) catch unreachable;
    defer bitmap.release(allocator);
    const spheres = [_]Sphere{
        .{
            .o = Vec3f.init(0, 0, -1),
            .r = 0.5,
            .m = .{
                .Metal = .{
                    .reflectCol = Vec3f.init(0.7, 0.3, 0.3),
                    .emitCol = Vec3f.init(0, 0, 0),
                    .reflectance = 0,
                },
            },
        },
        .{
            .o = Vec3f.init(0, -100.5, -1),
            .r = 100,
            .m = .{
                .Metal = .{
                    .reflectCol = Vec3f.init(0.8, 0.8, 0),
                    .emitCol = Vec3f.init(0, 0, 0),
                    .reflectance = 0,
                },
            },
        },

        .{
            .o = Vec3f.init(-1, 0, -1),
            .r = 0.5,
            .m = .{
                .Metal = .{
                    .reflectCol = Vec3f.init(0.8, 0.8, 0.8),
                    .emitCol = Vec3f.init(0, 0, 0),
                    .reflectance = 0.7,
                },
            },
        },

        .{
            .o = Vec3f.init(1, 0, -1),
            .r = 0.5,
            .m = .{
                .Metal = .{
                    .reflectCol = Vec3f.init(0.8, 0.6, 0.2),
                    .emitCol = Vec3f.init(0, 0, 0),
                    .reflectance = 0,
                },
            },
        },
    };
    const timer = std.time.Timer.start() catch unreachable;
    const start_time = timer.read();

    renderToBitmap(allocator, &bitmap, spheres[0..], Vec3f.init(0, 0, 1), default_output_type) catch {
        daedelus.fatalErrorMessage(allocator, "rendering failed", "rendering error");
    };
    const end_time = timer.read();
    const raycast_time = @intToFloat(f32, (end_time - start_time)) * 1e-9;

    const stderr = std.io.getStdErr().writer();
    _ = stderr.print("Finished raycasting in {} seconds\n", .{raycast_time}) catch {};

    var running = true;

    while (running) {
        switch (window.getEvent()) {
            .CloseRequest => |_| {
                running = false;
            },
            .RedrawRequest => |redraw_request| {
                window.blit(bitmap, 0, 0) catch {
                    unreachable;
                };
            },
            .WindowResize => {
                daedelus.fatalErrorMessage(allocator, "How did this resize?", "Fatal error");
                return;
            },
        }
    }
}

//pub const log = daedelus.log;

export fn printSizeT(x: usize) void {
    std.log.err("{}", .{x});
}
