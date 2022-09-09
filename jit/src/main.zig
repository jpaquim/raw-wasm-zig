const std = @import("std");

export const data = [_]u8{
    // 0     1     2     3     4     5     6     7
    // (     )     *     +     ,     -     .     /
    // x     0     2     1     x     1     x     2
    0x00, 0x00, 0x02, 0x01, 0x00, 0x01, 0x00, 0x02, // precedence
    0x00, 0x00, 0x6c, 0x6a, 0x00, 0x6b, 0x00, 0x6d, // wasm op
    0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, // magic/version
    0x01, 0x05, 0x01, 0x60, 0x00, 0x01, 0x7f, // type: func () -> i32
    0x03, 0x02, 0x01, 0x00, // func: type 0
    0x07, 0x05, 0x01, 0x01, 0x30, 0x00, 0x00, // export: func 0 -> "0"
    0x0a, 0xff, 0x01, 0xff, 0x00,
};

// dummy zero data to fill with rest of wasm module
export const dummy = [_]u8{0} ** 100;

extern fn compile(i32) void;

extern fn consoleLogString(p: [*]const u8, l: usize) void;

extern fn consoleLogVar(p: [*]const u8, l: usize, v: i32) void;

fn logString(string: []const u8) void {
    consoleLogString(string.ptr, string.len);
}

fn logVar(name: []const u8, value: i32) void {
    consoleLogVar(name.ptr, name.len, value);
}

fn load(comptime T: type, index: i32, comptime offset: ?usize) i32 {
    // logString("load!");
    // logVar("index", index);
    // logVar("offset", (offset orelse 0));
    // logVar("position", index + (offset orelse 0));
    const value = @intCast(i32, @intToPtr(*T, @intCast(usize, index) + (offset orelse 0)).*);
    // logVar("value", value);
    return value;
}

fn store(comptime T: type, value: i32, index: i32, comptime offset: ?usize) void {
    // logString("store!");
    // logVar("value", value);
    // logVar("index", index);
    // logVar("offset", @intCast(i32, offset orelse 0));
    // logVar("position", index + @intCast(i32, offset orelse 0));
    @intToPtr(*T, @intCast(usize, index) + (offset orelse 0)).* = @intCast(T, value);
}

export fn gen() i32 {
    var p: i32 = 0;
    var d: i32 = 0;
    var o: i32 = 0;
    var count: i32 = 0;
    var c: i32 = 0;
    var op: i32 = 0;
    var oval: i32 = 0;

    err: {
        endparse: {
            while (true) {
                push: {
                    op: {
                        num: {
                            p += 1;
                            c = load(u8, p, 255);
                            if (c == 0) break :endparse;

                            op = c - 0x28;
                            switch (op) {
                                0 => break :push,
                                1, 2, 3, 5, 7 => break :op,
                                8, 9, 10, 11, 12, 13, 14, 15, 16, 17 => break :num,
                                else => break :err,
                            }
                        }
                        d += 2;
                        store(i16, ((c - 0x30) << 8) | 0x41, d, 45);

                        count += 1;
                        continue;
                    }
                    exit: {
                        while (true) {
                            if (o == 0) break :exit;

                            c = load(u8, p, 255);
                            oval = load(u8, o - 1, 512);
                            if (oval == 0 or load(u8, oval, 0) < load(u8, op, 0)) break :exit;

                            count -= 1;
                            if (count < 1) break :err;

                            o -= 1;

                            d += 1;
                            store(u8, load(u8, oval, 8), d, 46);
                            continue;
                        }
                    }
                    if (op != 1) break :push;

                    if (o == 0) break :err;

                    o -= 1;
                    continue;
                }
                o += 1;
                store(u8, op, o, 511);
                continue;
            }
        }
        exit: {
            while (true) {
                if (o == 0) break :exit;

                count -= 1;
                if (count < 1) break :err;

                d += 1;
                o -= 1;
                store(u8, load(u8, load(u8, o, 512), 8), d, 46);
                continue;
            }
        }
        if (count != 1) break :err;

        store(u8, 0xb, d, 47);

        store(u8, d + 4, 43, 0);

        store(u8, d + 2, 45, 0);

        compile(d + 32);
        return 1;
    }
    return 0;
}

// (func (export "call") (result i32)
//   (call_indirect (result i32) (i32.const 0)))
export fn call() i32 {
    // for stage1:
    // return @intToPtr(fn () i32, 0)(); // some kind of allowzero here
    // return @intToPtr(fn () i32, 1)();

    // for stage2:
    return @intToPtr(*const fn () i32, 1)();

    // other attempts, all generate unreachable
    // return @intToPtr(*allowzero const fn () i32, 0)();
    // var i: usize = 0;
    // return @intToPtr(*allowzero const fn () i32, i)();
    // var i: usize = 0;
    // return @call(.{ .modifier = .never_inline }, @intToPtr(*allowzero const fn () i32, i), .{});
}
