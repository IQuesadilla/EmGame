const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Pixel = struct { r: f32, g: f32, b: f32, d: f32 };
const Vec3 = struct { r: f32, g: f32, b: f32 };
const Pos3 = struct { x: f32, y: f32, z: f32 };

const Mat4 = [4][4]f32;
// [col][row], col{row,row,row,row}
const Identity = Mat4{ [4]f32{ 1, 0, 0, 0 }, [4]f32{ 0, 1, 0, 0 }, [4]f32{ 0, 0, 1, 0 }, [4]f32{ 0, 0, 0, 1 } };
const Zeros = Mat4{ [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 }, [4]f32{ 0, 0, 0, 0 } };

var PixelMap: [640][480]Pixel = undefined;

fn RasterizeTriangle(a: Pos3, b: Pos3, c: Pos3, mvp: Mat4) void {
    var aMat = [4]f32{ a.x, a.y, a.z, 1.0 };
    var bMat = [4]f32{ b.x, b.y, b.z, 1.0 };
    var cMat = [4]f32{ c.x, c.x, c.z, 1.0 };

    var aPos: Pos3 = DivideW(MatVecMult(mvp, aMat));
    var bPos: Pos3 = DivideW(MatVecMult(mvp, bMat));
    var cPos: Pos3 = DivideW(MatVecMult(mvp, cMat));

    //aPos = .{ .x = @fabs(aPos.x), .y = @fabs(aPos.y), .z = @fabs(aPos.z) };
    //aPos = Normalize(aPos);
    //bPos = .{ .x = @fabs(bPos.x), .y = @fabs(bPos.y), .z = @fabs(bPos.z) };
    //bPos = Normalize(bPos);
    //cPos = .{ .x = @fabs(cPos.x), .y = @fabs(cPos.y), .z = @fabs(cPos.z) };
    //cPos = Normalize(cPos);

    var u: Pos3 = undefined;
    var i: Pos3 = undefined;
    var l: Pos3 = undefined;

    if (aPos.y > bPos.y) {
        if (bPos.y > cPos.y) {
            u = aPos;
            i = bPos;
            l = cPos;
        } else if (aPos.y > cPos.y) {
            u = aPos;
            i = cPos;
            l = bPos;
        } else { // cPos >>
            u = cPos;
            i = aPos;
            l = bPos;
        }
    } else { // bPos > aPos
        if (aPos.y > cPos.y) {
            u = bPos;
            i = aPos;
            l = cPos;
        } else if (bPos.y > cPos.y) {
            u = bPos;
            i = cPos;
            l = aPos;
        } else { // cPos >>
            u = cPos;
            i = bPos;
            l = aPos;
        }
    }

    //std.debug.print("{any}\n", .{aPos});
    std.debug.print("VERTS: {any} {any} {any}\n", .{ aPos, bPos, cPos });
    if (u.x >= 0.0 and u.x <= 1.0 and u.y >= 0.0 and u.y <= 1.0 and u.z >= 0.0 and u.z <= 1.0)
        PixelMap[@as(usize, @intFromFloat(@floor(u.x * 639.5)))][@as(usize, @intFromFloat(@floor(u.y * 479.5)))] = .{ .r = 1.0, .g = 0.0, .b = 0.0, .d = 0.0 };
    if (i.x >= 0.0 and i.x <= 1.0 and i.y >= 0.0 and i.y <= 1.0 and i.z >= 0.0 and i.z <= 1.0)
        PixelMap[@as(usize, @intFromFloat(@floor(i.x * 639.5)))][@as(usize, @intFromFloat(@floor(i.y * 479.5)))] = .{ .r = 0.0, .g = 1.0, .b = 0.0, .d = 0.0 };
    if (l.x >= 0.0 and l.x <= 1.0 and l.y >= 0.0 and l.y <= 1.0 and l.z >= 0.0 and l.z <= 1.0)
        PixelMap[@as(usize, @intFromFloat(@floor(l.x * 639.5)))][@as(usize, @intFromFloat(@floor(l.y * 479.5)))] = .{ .r = 0.0, .g = 0.0, .b = 1.0, .d = 0.0 };

    PixelMap[1][1] = .{ .r = 1.0, .g = 1.0, .b = 1.0, .d = 0.0 };

    // !! Find longest edge (only matters in 2D)
    // Find direction to render in (direction of third vertex)
}

fn DivideW(v: [4]f32) Pos3 {
    return .{ .x = v[0] / v[3], .y = v[1] / v[3], .z = v[2] / v[3] };
}

fn Normalize(vec: Pos3) Pos3 {
    var d: f32 = @sqrt((vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z));
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
    var n: Pos3 = .{ .x = look.x - eye.x, .y = look.y - eye.y, .z = look.z - eye.z };
    var v: Pos3 = CrossProd(n, up);
    var u: Pos3 = CrossProd(v, n);
    //n = Normalize(n);
    //v = Normalize(v);
    //u = Normalize(u);

    var result: Mat4 = Identity;
    result[0][0] = v.x;
    result[1][0] = v.y;
    result[2][0] = v.z;
    result[0][1] = u.x;
    result[1][1] = u.y;
    result[2][1] = u.z;
    result[0][2] = -n.x;
    result[1][2] = -n.y;
    result[2][2] = -n.z;
    result[3][0] = -DotProd(eye, v);
    result[3][1] = -DotProd(eye, u);
    result[3][2] = DotProd(eye, n);
    return result;
}

fn Translate(m: Mat4, v: Pos3) Mat4 {
    var r = m;
    r[0][3] = m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3];
    r[1][3] = m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3];
    r[2][3] = m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3];
    r[3][3] = m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3];
    return r;
}

// Projection Matrix
fn Perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var m = Zeros;
    var range: f32 = @tan(std.math.degreesToRadians(f32, fov / 2.0));
    m[0][0] = 1.0 / (aspect * range);
    m[1][1] = 1.0 / range;
    m[2][2] = (far) / (far - near);
    m[3][2] = 1.0;
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
            PixelMap[x][y] = .{ .r = 0, .g = 0, .b = 0, .d = 0 };
        }
    }
}

fn SetPixel(s: *sdl.SDL_Surface, xpos: usize, ypos: usize, r: u8, g: u8, b: u8) void {
    var bpp: isize = s.*.format.*.BytesPerPixel;
    var x: c_int = @as(c_int, @intCast(xpos));
    var y: c_int = @as(c_int, @intCast(ypos));
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

    var window: *sdl.SDL_Window = sdl.SDL_CreateWindow("mygpu", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, 640, 480, 0) orelse return;
    defer sdl.SDL_DestroyWindow(window);
    var surface: *sdl.SDL_Surface = sdl.SDL_GetWindowSurface(window);

    std.debug.print("BPP: {}\n", .{surface.*.format.*.BytesPerPixel});

    const Speed: f32 = 0.05;
    var xpos: f32 = 0.0;
    var ypos: f32 = 0.0;
    var zpos: f32 = 0.0;

    var id: usize = 0;
    var PerformLoop: bool = true;
    while (PerformLoop) {
        var e: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e) != 0) {
            switch (e.type) {
                sdl.SDL_QUIT => {
                    PerformLoop = false;
                },
                sdl.SDL_KEYDOWN => {
                    switch (e.key.keysym.sym) {
                        sdl.SDLK_w => {
                            //model[1][3] += Speed;
                            zpos += Speed;
                        },
                        sdl.SDLK_s => {
                            //model[1][3] -= Speed;
                            zpos -= Speed;
                        },
                        sdl.SDLK_d => {
                            //model[0][3] += Speed;
                            xpos += Speed;
                        },
                        sdl.SDLK_a => {
                            //model[0][3] -= Speed;
                            xpos -= Speed;
                        },
                        sdl.SDLK_e => {
                            //model[2][3] += Speed;
                            ypos += Speed;
                        },
                        sdl.SDLK_q => {
                            //model[2][3] -= Speed;
                            ypos -= Speed;
                        },
                        else => {},
                    }
                },
                else => {},
                //model[0][3] += Speed;
            }
        }

        Clear();

        var proj: Mat4 = Perspective(90.0, 640.0 / 480.0, 0.1, 100.0);
        var view: Mat4 = LookAt(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 }, .{ .x = 0, .y = 1, .z = 0 });
        var model: Mat4 = Identity;

        model = Translate(model, .{ .x = xpos, .y = ypos, .z = zpos });
        std.debug.print("Model: {any}\nView: {any}\nProj: {any}\n", .{ model, view, proj });

        var mvp = MatMult(model, MatMult(view, proj));

        //std.debug.print("{any}\n", .{mvp});
        RasterizeTriangle(.{ .x = 0.02, .y = 0.02, .z = 0.05 }, .{ .x = 0.02, .y = 0.05, .z = 0.05 }, .{ .x = 0.05, .y = 0.02, .z = 0.05 }, mvp);

        // for (270..370) |x| {
        //     for (id..id + 100) |y| {
        //         //PixelMap[x][y] = .{ .r = 1.0, .g = 0.0, .b = 1.0, .d = 0.0 };
        //         //SetPixel(surface, 100 + x, 100 + y, 255, 0, 0);
        //     }
        // }
        id += 1;
        if (id == 380) id = 0;
        //const outPos: [4]f32{};

        RenderSurface(surface);

        _ = sdl.SDL_UpdateWindowSurface(window);
        std.time.sleep(16666666);
    }

    defer sdl.SDL_Quit();
    //var Model = Identity;
    //_ = Model;
}

test "matrix multiplication" {
    var a = Mat4{ [4]f32{ 1, 2, 3, 4 }, [4]f32{ 4, 1, 2, 3 }, [4]f32{ 3, 4, 1, 2 }, [4]f32{ 2, 3, 4, 1 } };
    var result = MatMult(a, a);

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
    var result = Perspective(90.0, 640.0 / 480.0, 0.1, 100.0);
    std.debug.print("Proj: {any}\n", .{result});
}

test "view matrix" {
    var Position: Pos3 = .{ .x = 0, .y = 0, .z = 0 };
    var Front: Pos3 = .{ .x = 0, .y = 0, .z = 1 };
    var Up: Pos3 = .{ .x = 0, .y = 1, .z = 0 };
    var View: Mat4 = LookAt(Position, Front, Up);
    std.debug.print("View: {any}\n", .{View});
}
