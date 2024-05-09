const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Pixel = struct { r: f32, g: f32, b: f32, d: f32 };
const Vec3 = struct { r: f32, g: f32, b: f32 };
const Pos2 = struct { x: f32, y: f32 };
const Pos3 = struct { x: f32, y: f32, z: f32 };
const Data5 = struct { x: f32, y: f32, z: f32, u: f32, v: f32 };
const Data6 = struct { x: f32, y: f32, z: f32, u: f32, v: f32, b: f32 };

const Mat4 = [4][4]f32;
// [row][col], row{col,col,col,col}
const Identity = Mat4{ [4]f32{ 1, 0, 0, 0 }, [4]f32{ 0, 1, 0, 0 }, [4]f32{ 0, 0, 1, 0 }, [4]f32{ 0, 0, 0, 1 } };
const Zeros = Mat4{ [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 } };

var PixelMap: [640][480]Pixel = undefined;

var sampler: ?*sdl.SDL_Surface = null;

fn DrawPixel(a: Pos3, color: Vec3) void {
    if (a.x > -1.0 and a.x < 1.0 and a.y > -1.0 and a.y < 1.0 and a.z >= 0.0 and a.z < 1.0) {
        const x: usize = @as(usize, @intFromFloat(@floor(a.x * 640.0 / 2) + (640 / 2)));
        const y: usize = @as(usize, @intFromFloat(@floor(a.y * 480.0 / 2) + (480 / 2)));

        if (PixelMap[x][y].d > a.z)
            PixelMap[x][y] = .{ .r = color.r, .g = color.g, .b = color.b, .d = a.z };
    }
}

fn RasterizeTriangle(a: Data5, b: Data5, c: Data5, mvp: Mat4) void {
    const aMat = [4]f32{ a.x, a.y, a.z, 1.0 };
    const bMat = [4]f32{ b.x, b.y, b.z, 1.0 };
    const cMat = [4]f32{ c.x, c.x, c.z, 1.0 };

    const aPos: Pos3 = DivideW(MatVecMult(mvp, aMat));
    const bPos: Pos3 = DivideW(MatVecMult(mvp, bMat));
    const cPos: Pos3 = DivideW(MatVecMult(mvp, cMat));

    const aData: Data5 = .{ .x = aPos.x, .y = aPos.y, .z = aPos.z, .u = a.u, .v = a.v };
    const bData: Data5 = .{ .x = bPos.x, .y = bPos.y, .z = bPos.z, .u = b.u, .v = b.v };
    const cData: Data5 = .{ .x = cPos.x, .y = cPos.y, .z = cPos.z, .u = c.u, .v = c.v };

    //aPos = .{ .x = @fabs(aPos.x), .y = @fabs(aPos.y), .z = @fabs(aPos.z) };
    //aPos = Normalize(aPos);
    //bPos = .{ .x = @fabs(bPos.x), .y = @fabs(bPos.y), .z = @fabs(bPos.z) };
    //bPos = Normalize(bPos);
    //cPos = .{ .x = @fabs(cPos.x), .y = @fabs(cPos.y), .z = @fabs(cPos.z) };
    //cPos = Normalize(cPos);

    var u: Data5 = undefined;
    var i: Data5 = undefined;
    var l: Data5 = undefined;

    if (aData.y > bData.y) {
        if (bData.y > cData.y) {
            u = aData;
            i = bData;
            l = cData;
        } else if (aPos.y > cPos.y) {
            u = aData;
            i = cData;
            l = bData;
        } else { // cPos >>
            u = cData;
            i = aData;
            l = bData;
        }
    } else { // bPos > aPos
        if (aData.y > cData.y) {
            u = bData;
            i = aData;
            l = cData;
        } else if (bData.y > cData.y) {
            u = bData;
            i = cData;
            l = aData;
        } else { // cPos >>
            u = cData;
            i = bData;
            l = aData;
        }
    }

    //std.debug.print("{any}\n", .{aPos});
    //std.debug.print("VERTS: {any} {any} {any}\n", .{ aPos, bPos, cPos });
    //if (u.x >= 0.0 and u.x <= 1.0 and u.y >= 0.0 and u.y <= 1.0 and u.z >= 0.0 and u.z <= 1.0)
    //    PixelMap[@as(usize, @intFromFloat(@floor(u.x * 639.5)))][@as(usize, @intFromFloat(@floor(u.y * 479.5)))] = .{ .r = 1.0, .g = 0.0, .b = 0.0, .d = 0.0 };
    //if (i.x >= 0.0 and i.x <= 1.0 and i.y >= 0.0 and i.y <= 1.0 and i.z >= 0.0 and i.z <= 1.0)
    //    PixelMap[@as(usize, @intFromFloat(@floor(i.x * 639.5)))][@as(usize, @intFromFloat(@floor(i.y * 479.5)))] = .{ .r = 0.0, .g = 1.0, .b = 0.0, .d = 0.0 };
    //if (l.x >= 0.0 and l.x <= 1.0 and l.y >= 0.0 and l.y <= 1.0 and l.z >= 0.0 and l.z <= 1.0)
    //    PixelMap[@as(usize, @intFromFloat(@floor(l.x * 639.5)))][@as(usize, @intFromFloat(@floor(l.y * 479.5)))] = .{ .r = 0.0, .g = 0.0, .b = 1.0, .d = 0.0 };

    PixelMap[1][5] = .{ .r = 1.0, .g = 1.0, .b = 1.0, .d = 0.0 };

    //const slope: Pos3 = .{ .x = u.x - l.x, .y = u.y - l.y, .z = 0.5 };

    const epsilon: f32 = 0.0001;
    var rise: f32 = u.y - l.y;
    if (rise < epsilon and rise > -epsilon) rise = epsilon;
    var run: f32 = u.x - l.x;
    if (run < epsilon and run > -epsilon) run = epsilon;
    //const slope: f32 = rise / run;
    const srun: f32 = run * 480;
    const srise: f32 = rise * 640;
    const sflen: f32 = (if (srise > srun) srise else srun);
    if (true) { //(u.x < 1.0 and u.x > -1.0 and u.y < 1.0 and u.y > -1.0 and u.z < 1.0 and u.z > -1.0) or (i.x < 1.0 and i.x > -1.0 and i.y < 1.0 and i.y > -1.0 and i.z < 1.0 and i.z > -1.0) or ((l.x < 1.0 and l.x > -1.0) or (l.y < 1.0 and l.y > -1.0) or (l.z < 1.0 and l.z > -1.0))) {
        const len: usize = @as(usize, @intFromFloat(@ceil(@abs(sflen))));
        //std.debug.print("Slope: {any}, Length: {any}, IT: {any}\n", .{ slope, len, rise / sflen });
        for (0..len) |r| {
            //var lineoffset: f32 = 0.0;
            const fr: f32 = @as(f32, @floatFromInt(r));
            const xoffset: f32 = fr * (run / sflen);
            const yoffset: f32 = fr * (rise / sflen);

            var lrise: f32 = i.y - l.y;
            if (lrise < epsilon and lrise > -epsilon) lrise = epsilon;
            var lrun: f32 = i.x - l.x;
            if (lrun < epsilon and lrun > -epsilon) lrun = epsilon;
            const lslope: f32 = lrise / lrun;
            const lx: f32 = ((l.y + yoffset - i.y) / lslope) + i.x;

            var urise: f32 = i.y - u.y;
            if (urise < epsilon and urise > -epsilon) urise = epsilon;
            var urun: f32 = i.x - u.x;
            if (urun < epsilon and urun > -epsilon) urun = epsilon;
            const uslope: f32 = urise / urun;
            const ux: f32 = ((l.y + yoffset - i.y) / uslope) + i.x;

            const ldiff: f32 = l.x + xoffset - lx;
            const udiff: f32 = l.x + xoffset - ux;
            const diff: f32 = if (@abs(ldiff) < @abs(udiff)) ldiff else udiff;

            const fllen: f32 = @floor(((diff)) * 640);
            const llen: usize = @as(usize, @intFromFloat(@abs(fllen)));
            //std.debug.print("-----\n", .{});
            for (0..llen) |d| {
                const fd: f32 = @as(f32, @floatFromInt(d));
                const dd: f32 = if (fllen < 0) fd else -fd;

                const vpercent: f32 = @as(f32, @floatFromInt(r)) / @as(f32, @floatFromInt(len));
                _ = vpercent;
                const hpercent: f32 = @as(f32, @floatFromInt(d)) / @as(f32, @floatFromInt(llen));
                _ = hpercent;
                //const otherper: f32 = @abs(diff / (l.x + xoffset - i.x));

                const hlpercent: f32 = @abs(yoffset / (i.y - l.y));
                const hupercent: f32 = (1 - @abs(((l.y + yoffset) - i.y) / (u.y - i.y)));

                const hl: f32 = if (hlpercent <= 1.0 and hlpercent >= 0.0) hlpercent else if (hlpercent < 0.0) 0.0 else 1.0;
                _ = hl;
                const hu: f32 = if (hupercent <= 1.0 and hupercent >= 0.0) hupercent else if (hupercent < 0.0) 0.0 else 1.0;
                _ = hu;

                //if (hlpercent < 1.0) std.debug.print("What!\n", .{});

                //const uval: f32 = (i.u * hl * hu * hpercent) + ((1 - vpercent) * (1 - hl) * l.u) + (vpercent * (1 - hu) * u.u);
                //const vval: f32 = (i.v * hl * hu * hpercent) + ((1 - vpercent) * (1 - hl) * l.v) + (vpercent * (1 - hu) * u.v);
                //const bval: f32 = (i.b * hl * hu * hpercent) + ((1 - vpercent) * (1 - hl) * l.b) + (vpercent * (1 - hu) * u.b);

                const outPos: Pos3 = .{ .x = l.x + xoffset + (dd / 640), .y = l.y + yoffset, .z = l.z };

                // Just use distances for now.
                const lvec: Pos2 = .{ .x = outPos.x - l.x, .y = outPos.y - l.y };
                const ivec: Pos2 = .{ .x = outPos.x - i.x, .y = outPos.y - i.y };
                const uvec: Pos2 = .{ .x = outPos.x - u.x, .y = outPos.y - u.y };
                const ldis: f32 = @sqrt((lvec.x * lvec.x) + (lvec.y * lvec.y));
                const idis: f32 = @sqrt((ivec.x * ivec.x) + (ivec.y * ivec.y));
                const udis: f32 = @sqrt((uvec.x * uvec.x) + (uvec.y * uvec.y));
                const uval: f32 = (ldis * l.u) + (idis * i.u) + (udis * u.u);
                const vval: f32 = (ldis * l.v) + (idis * i.v) + (udis * u.v);
                //const bval: f32 = (ldis * l.b) + (idis * i.b) + (udis * u.b);
                const dColor: f32 = @sqrt((uval * uval) + (vval * vval));

                var outColor: Vec3 = undefined;
                if (sampler) |s| {
                    const sxpos: usize = @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(s.*.w)) * (uval / dColor))));
                    const sypos: usize = @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(s.*.h)) * (vval / dColor))));
                    const bpp: isize = s.*.format.*.BytesPerPixel;
                    //* Here p is the address to the pixel we want to set */
                    const p: [*c]u32 = (@as([*c]u32, @ptrCast(@alignCast(s.*.pixels))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @intCast(sypos)) * s.*.pitch))))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @intCast(sxpos)) * bpp))));
                    const pixel = p.*; //@as(u32, @bitCast(@as(c_uint, @truncate(@as([*c]u32, @ptrCast(@alignCast(p))).*)))); //@as(u32, @bitCast(@as(c_uint, @truncate(pixel))))

                    var outR: u8 = 0;
                    var outG: u8 = 0;
                    var outB: u8 = 0;
                    sdl.SDL_GetRGB(pixel, s.*.format, &outR, &outG, &outB);

                    outColor = .{ .r = (@as(f32, @floatFromInt(outR)) / 255.0), .g = (@as(f32, @floatFromInt(outG)) / 255.0), .b = (@as(f32, @floatFromInt(outB)) / 255.0) };

                    //outColor = .{ .r = (uval / dColor), .g = (vval / dColor), .b = 0.0 };
                } else {
                    outColor = .{ .r = (uval / dColor), .g = (vval / dColor), .b = 0.0 };
                }

                //const outColor: Vec3 = Normalize(.{.r = uval, .g = vval, .b = bval});
                //std.debug.print("UVAL: {}, HL: {}, HU: {}\n", .{ uval, hl, hu });

                //if (uval > 1 or uval < 0) std.debug.print("ERROR!!\n", .{});

                //const uval: f32 = (hpercent * i.u) + (((vpercent * u.u) + ((1 - vpercent) * l.u)) * (1 - hpercent));
                //const vval: f32 = (hpercent * i.v) + (((vpercent * u.v) + ((1 - vpercent) * l.v)) * (1 - hpercent));

                DrawPixel(outPos, outColor);
            }

            //DrawPixel(.{ .x = l.x + xoffset, .y = l.y + yoffset, .z = 0.5 }, .{ .r = 0.5, .g = 0.0, .b = 0.5 });
        }
    }

    //DrawPixel(.{ .x = u.x, .y = u.y, .z = 0.0 }, .{ .r = 1.0, .g = 0.0, .b = 0.0 });
    //DrawPixel(.{ .x = i.x, .y = i.y, .z = 0.0 }, .{ .r = 0.0, .g = 1.0, .b = 0.0 });
    //DrawPixel(.{ .x = l.x, .y = l.y, .z = 0.0 }, .{ .r = 0.0, .g = 0.0, .b = 1.0 });
}

fn DivideW(v: [4]f32) Pos3 {
    return .{ .x = v[0] / v[3], .y = v[1] / v[3], .z = v[2] / v[3] };
}

fn Normalize(vec: Pos3) Pos3 {
    const d: f32 = @sqrt((vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z));
    return .{ .x = vec.x / d, .y = vec.y / d, .z = vec.z / d };
}

fn CrossProd(a: Pos3, b: Pos3) Pos3 {
    return .{ .x = (a.y * b.z) - (a.z * b.y), .y = (a.z * b.x) - (a.x * b.z), .z = (a.x * b.y) - (a.y * b.x) };
}

fn DotProd(a: Pos3, b: Pos3) f32 {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
}

// View Matrix
fn LookAt(eye: Pos3, look: Pos3, up: Pos3) Mat4 {
    const n: Pos3 = Normalize(look); //.{ .x = look.x - eye.x, .y = look.y - eye.y, .z = look.z - eye.z });
    const v: Pos3 = Normalize(CrossProd(up, n));
    const u: Pos3 = CrossProd(v, n);

    var result: Mat4 = Identity;
    result[0][0] = v.x;
    result[1][0] = v.y;
    result[2][0] = v.z;
    result[0][1] = u.x;
    result[1][1] = u.y;
    result[2][1] = u.z;
    result[0][2] = n.x;
    result[1][2] = n.y;
    result[2][2] = n.z;
    result[0][3] = -DotProd(eye, v);
    result[1][3] = -DotProd(eye, u);
    result[2][3] = -DotProd(eye, n);
    return result;
}

fn Translate(m: Mat4, v: Pos3) Mat4 {
    var r = m;
    r[0][3] += v.x;
    r[1][3] += v.y;
    r[2][3] += v.z;
    //r[0][3] = m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z + m[3][0];
    //r[1][3] = m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z + m[3][1];
    //r[2][3] = m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z + m[3][2];
    //r[3][3] = m[0][3] * v.x + m[1][3] * v.y + m[2][3] * v.z + m[3][3];
    return r;
}

// Projection Matrix
fn Perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var m = Zeros;
    const range: f32 = @tan(std.math.degreesToRadians(fov / 2.0));
    m[0][0] = 1.0 / (aspect * range);
    m[1][1] = 1.0 / range;
    m[2][2] = -(far + near) / (far - near);
    m[3][2] = -1.0;
    m[2][3] = -((far * near) / (far - near));
    return m;
}

fn RenderSurface(s: *sdl.SDL_Surface) void {
    for (0..640) |x| {
        for (0..480) |y| {
            const temp = PixelMap[x][y];
            SetPixel(s, x, y, @intFromFloat(temp.r * 255.0), @intFromFloat(temp.g * 255.0), @intFromFloat(temp.b * 255.0));
        }
    }
}

fn Clear() void {
    for (0..640) |x| {
        for (0..480) |y| {
            PixelMap[x][y] = .{ .r = 0, .g = 0, .b = 0, .d = 1 };
        }
    }
}

fn SetPixel(s: *sdl.SDL_Surface, xpos: usize, ypos: usize, r: u8, g: u8, b: u8) void {
    const bpp: isize = s.*.format.*.BytesPerPixel;
    const x: c_int = @as(c_int, @intCast(xpos));
    const y: c_int = @as(c_int, @intCast(ypos));
    //* Here p is the address to the pixel we want to set */
    var p: [*c]u8 = (@as([*c]u8, @ptrCast(@alignCast(s.*.pixels))) + @as(usize, @bitCast(@as(isize, @intCast(y * s.*.pitch))))) + @as(usize, @bitCast(@as(isize, @intCast(x * bpp))));
    const pixel = sdl.SDL_MapRGB(s.*.format, r, g, b);

    switch (bpp) {
        @as(c_int, 1) => {
            p.* = @as(u8, @bitCast(@as(u8, @truncate(pixel))));
        },

        @as(c_int, 2) => {
            @as([*c]u16, @ptrCast(@alignCast(p))).* = @as(u16, @bitCast(@as(c_ushort, @truncate(pixel))));
        },

        @as(c_int, 3) => {
            if (@as(c_int, sdl.SDL_BYTEORDER) == @as(c_int, sdl.SDL_BIG_ENDIAN)) {
                p[@as(c_uint, @intCast(@as(c_int, 0)))] = @as(u8, @bitCast(@as(u8, @truncate((pixel >> @intCast(16)) & @as(u32, @bitCast(@as(c_int, 255)))))));
                p[@as(c_uint, @intCast(@as(c_int, 1)))] = @as(u8, @bitCast(@as(u8, @truncate((pixel >> @intCast(8)) & @as(u32, @bitCast(@as(c_int, 255)))))));
                p[@as(c_uint, @intCast(@as(c_int, 2)))] = @as(u8, @bitCast(@as(u8, @truncate(pixel & @as(u32, @bitCast(@as(c_int, 255)))))));
            } else {
                p[@as(c_uint, @intCast(@as(c_int, 0)))] = @as(u8, @bitCast(@as(u8, @truncate(pixel & @as(u32, @bitCast(@as(c_int, 255)))))));
                p[@as(c_uint, @intCast(@as(c_int, 1)))] = @as(u8, @bitCast(@as(u8, @truncate((pixel >> @intCast(8)) & @as(u32, @bitCast(@as(c_int, 255)))))));
                p[@as(c_uint, @intCast(@as(c_int, 2)))] = @as(u8, @bitCast(@as(u8, @truncate((pixel >> @intCast(16)) & @as(u32, @bitCast(@as(c_int, 255)))))));
            }
        },

        @as(c_int, 4) => {
            @as([*c]u32, @ptrCast(@alignCast(p))).* = @as(u32, @bitCast(@as(c_uint, @truncate(pixel))));
        },

        else => unreachable,
    }
}

fn MatMult(a: Mat4, b: Mat4) Mat4 {
    var result: Mat4 = Identity;
    result[0][0] = a[0][0] * b[0][0] + a[0][1] * b[1][0] + a[0][2] * b[2][0] + a[0][3] * b[3][0];
    result[0][1] = a[0][0] * b[0][1] + a[0][1] * b[1][1] + a[0][2] * b[2][1] + a[0][3] * b[3][1];
    result[0][2] = a[0][0] * b[0][2] + a[0][1] * b[1][2] + a[0][2] * b[2][2] + a[0][3] * b[3][2];
    result[0][3] = a[0][0] * b[0][3] + a[0][1] * b[1][3] + a[0][2] * b[2][3] + a[0][3] * b[3][3];

    // Row 1
    result[1][0] = a[1][0] * b[0][0] + a[1][1] * b[1][0] + a[1][2] * b[2][0] + a[1][3] * b[3][0];
    result[1][1] = a[1][0] * b[0][1] + a[1][1] * b[1][1] + a[1][2] * b[2][1] + a[1][3] * b[3][1];
    result[1][2] = a[1][0] * b[0][2] + a[1][1] * b[1][2] + a[1][2] * b[2][2] + a[1][3] * b[3][2];
    result[1][3] = a[1][0] * b[0][3] + a[1][1] * b[1][3] + a[1][2] * b[2][3] + a[1][3] * b[3][3];

    // Row 2
    result[2][0] = a[2][0] * b[0][0] + a[2][1] * b[1][0] + a[2][2] * b[2][0] + a[2][3] * b[3][0];
    result[2][1] = a[2][0] * b[0][1] + a[2][1] * b[1][1] + a[2][2] * b[2][1] + a[2][3] * b[3][1];
    result[2][2] = a[2][0] * b[0][2] + a[2][1] * b[1][2] + a[2][2] * b[2][2] + a[2][3] * b[3][2];
    result[2][3] = a[2][0] * b[0][3] + a[2][1] * b[1][3] + a[2][2] * b[2][3] + a[2][3] * b[3][3];

    // Row 3
    result[3][0] = a[3][0] * b[0][0] + a[3][1] * b[1][0] + a[3][2] * b[2][0] + a[3][3] * b[3][0];
    result[3][1] = a[3][0] * b[0][1] + a[3][1] * b[1][1] + a[3][2] * b[2][1] + a[3][3] * b[3][1];
    result[3][2] = a[3][0] * b[0][2] + a[3][1] * b[1][2] + a[3][2] * b[2][2] + a[3][3] * b[3][2];
    result[3][3] = a[3][0] * b[0][3] + a[3][1] * b[1][3] + a[3][2] * b[2][3] + a[3][3] * b[3][3];

    return result;
}

fn MatVecMult(matrix: [4][4]f32, vector: [4]f32) [4]f32 {
    var result: [4]f32 = undefined;

    // Compute each element of the resulting 4x1 matrix
    result[0] = matrix[0][0] * vector[0] + matrix[0][1] * vector[1] + matrix[0][2] * vector[2] + matrix[0][3] * vector[3];
    result[1] = matrix[1][0] * vector[0] + matrix[1][1] * vector[1] + matrix[1][2] * vector[2] + matrix[1][3] * vector[3];
    result[2] = matrix[2][0] * vector[0] + matrix[2][1] * vector[1] + matrix[2][2] * vector[2] + matrix[2][3] * vector[3];
    result[3] = matrix[3][0] * vector[0] + matrix[3][1] * vector[1] + matrix[3][2] * vector[2] + matrix[3][3] * vector[3];

    return result;
}

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    const window: *sdl.SDL_Window = sdl.SDL_CreateWindow("mygpu", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, 640, 480, 0) orelse return;
    defer sdl.SDL_DestroyWindow(window);
    const surface: *sdl.SDL_Surface = sdl.SDL_GetWindowSurface(window);

    sampler = sdl.SDL_LoadBMP("sample.bmp");

    std.debug.print("BPP: {}\n", .{surface.*.format.*.BytesPerPixel});

    const Speed: f32 = 0.02;
    var CubePos: Pos3 = .{ .x = 0.0, .y = 0.0, .z = -0.2 };
    var CameraDir: Pos3 = .{ .x = 0, .y = 0, .z = 1 };
    var CameraLoc: Pos3 = .{ .x = 0, .y = 0, .z = 0 };

    var CamUp: bool = false;
    var CamDown: bool = false;
    var CamLeft: bool = false;
    var CamRight: bool = false;
    var CamForward: bool = false;
    var CamBackward: bool = false;

    var PerformLoop: bool = true;
    while (PerformLoop) {
        Clear();

        const proj: Mat4 = Perspective(90.0, 640.0 / 480.0, 0.1, 100.0);
        const view: Mat4 = LookAt(CameraLoc, CameraDir, .{ .x = 0, .y = -1, .z = 0 });
        var model: Mat4 = Identity;

        model = Translate(model, CubePos);
        //std.debug.print("Model: {any}\nView: {any}\nProj: {any}\n", .{ model, view, proj });

        const mvp = MatMult(proj, MatMult(view, model));

        const lowerx: f32 = -0.02;
        const lowery: f32 = -0.02;
        const lowerz: f32 = -0.02;
        const upperx: f32 = 0.02;
        const uppery: f32 = 0.02;
        const upperz: f32 = 0.02;
        _ = upperz;

        //std.debug.print("{any}\n", .{mvp});
        RasterizeTriangle(.{ .x = lowerx, .y = uppery, .z = lowerz, .u = 0.0, .v = 1.0 }, .{ .x = upperx, .y = lowery, .z = lowerz, .u = 1.0, .v = 0.0 }, .{ .x = lowerx, .y = lowery, .z = lowerz, .u = 0.0, .v = 0.0 }, mvp);
        RasterizeTriangle(.{ .x = upperx, .y = lowery, .z = lowerz, .u = 1.0, .v = 0.0 }, .{ .x = lowerx, .y = uppery, .z = lowerz, .u = 0.0, .v = 1.0 }, .{ .x = upperx, .y = uppery, .z = lowerz, .u = 1.0, .v = 1.0 }, mvp);
        //RasterizeTriangle(.{ .x = lowerx, .y = uppery, .z = upperz }, .{ .x = upperx, .y = lowery, .z = upperz }, .{ .x = lowerx, .y = lowery, .z = upperz }, mvp);
        //RasterizeTriangle(.{ .x = upperx, .y = lowery, .z = upperz }, .{ .x = lowerx, .y = uppery, .z = upperz }, .{ .x = upperx, .y = uppery, .z = upperz }, mvp);

        RenderSurface(surface);

        _ = sdl.SDL_UpdateWindowSurface(window);
        std.time.sleep(16666666);

        if (CamUp) CameraLoc.y -= Speed;
        if (CamDown) CameraLoc.y += Speed;
        if (CamLeft) CameraLoc.x += Speed;
        if (CamRight) CameraLoc.x -= Speed;
        if (CamForward) CameraLoc.z -= Speed;
        if (CamBackward) CameraLoc.z += Speed;

        var e: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e) != 0) {
            switch (e.type) {
                sdl.SDL_QUIT => {
                    PerformLoop = false;
                },
                sdl.SDL_KEYDOWN => {
                    switch (e.key.keysym.sym) {
                        sdl.SDLK_w => {
                            CamForward = true;
                        },
                        sdl.SDLK_s => {
                            CamBackward = true;
                        },
                        sdl.SDLK_d => {
                            CamRight = true;
                        },
                        sdl.SDLK_a => {
                            CamLeft = true;
                        },
                        sdl.SDLK_e => {
                            CamUp = true;
                        },
                        sdl.SDLK_q => {
                            CamDown = true;
                        },
                        sdl.SDLK_ESCAPE => {
                            PerformLoop = false;
                        },
                        sdl.SDLK_UP => {
                            CameraDir.y += Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_DOWN => {
                            CameraDir.y -= Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_RIGHT => {
                            CameraDir.x += Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_LEFT => {
                            CameraDir.x -= Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_j => {
                            CubePos.x -= Speed;
                        },
                        sdl.SDLK_l => {
                            CubePos.x += Speed;
                        },
                        sdl.SDLK_i => {
                            CubePos.z -= Speed;
                        },
                        sdl.SDLK_k => {
                            CubePos.z += Speed;
                        },
                        sdl.SDLK_o => {
                            CubePos.y += Speed;
                        },
                        sdl.SDLK_u => {
                            CubePos.y -= Speed;
                        },
                        else => {},
                    }
                },
                sdl.SDL_KEYUP => {
                    switch (e.key.keysym.sym) {
                        sdl.SDLK_w => {
                            CamForward = false;
                        },
                        sdl.SDLK_s => {
                            CamBackward = false;
                        },
                        sdl.SDLK_d => {
                            CamRight = false;
                        },
                        sdl.SDLK_a => {
                            CamLeft = false;
                        },
                        sdl.SDLK_e => {
                            CamUp = false;
                        },
                        sdl.SDLK_q => {
                            CamDown = false;
                        },
                        sdl.SDLK_UP => {
                            CameraDir.y += Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_DOWN => {
                            CameraDir.y -= Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_RIGHT => {
                            CameraDir.x += Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_LEFT => {
                            CameraDir.x -= Speed;
                            CameraDir = Normalize(CameraDir);
                        },
                        sdl.SDLK_j => {
                            CubePos.x -= Speed;
                        },
                        sdl.SDLK_l => {
                            CubePos.x += Speed;
                        },
                        sdl.SDLK_i => {
                            CubePos.z -= Speed;
                        },
                        sdl.SDLK_k => {
                            CubePos.z += Speed;
                        },
                        sdl.SDLK_o => {
                            CubePos.y += Speed;
                        },
                        sdl.SDLK_u => {
                            CubePos.y -= Speed;
                        },
                        else => {},
                    }
                },
                else => {},
                //model[0][3] += Speed;
            }
        }
    }
}

test "matrix multiplication" {
    const a = Mat4{ [4]f32{ 1, 2, 3, 4 }, [4]f32{ 4, 1, 2, 3 }, [4]f32{ 3, 4, 1, 2 }, [4]f32{ 2, 3, 4, 1 } };
    const result = MatMult(a, a);

    const expected: [4][4]f32 = [4][4]f32{
        [4]f32{ 26, 28, 26, 20 },
        [4]f32{ 20, 26, 28, 26 },
        [4]f32{ 26, 20, 26, 28 },
        [4]f32{ 28, 26, 20, 26 },
    };

    var i: u8 = 0;
    for (expected) |row| {
        //std.debug.print("[{}]: {any}\n", .{ @divFloor(i, 4), result[@divFloor(i, 4)] });
        for (row) |elem| {
            try std.testing.expectEqual(result[@divFloor(i, 4)][@mod(i, 4)], elem);
            i += 1;
        }
    }
    //std.testing.assert()
}

test "matrix vector multiplication" {
    const matrix: [4][4]f32 = [4][4]f32{
        [4]f32{ 1, 2, 3, 4 },
        [4]f32{ 5, 6, 7, 8 },
        [4]f32{ 9, 10, 11, 12 },
        [4]f32{ 13, 14, 15, 16 },
    };
    const vector: [4]f32 = [4]f32{ 1, 2, 3, 4 };
    const expected: [4]f32 = [4]f32{ 30, 70, 110, 150 };

    const result = MatVecMult(matrix, vector);

    var i: usize = 0;
    for (expected) |elem| {
        try std.testing.expectEqual(result[i], elem);
        i += 1;
    }
}

test "projection matrix" {
    const result = Perspective(90.0, 640.0 / 480.0, 0.1, 100.0);
    std.debug.print("Proj: {any}\n", .{result});
}

test "view matrix" {
    const Position: Pos3 = .{ .x = 0, .y = 0, .z = 0 };
    const Front: Pos3 = .{ .x = 0, .y = 0, .z = 1 };
    const Up: Pos3 = .{ .x = 0, .y = 1, .z = 0 };
    const View: Mat4 = LookAt(Position, Front, Up);
    std.debug.print("View: {any}\n", .{View});
}
