const std = @import("std");

extern fn compile(i32) void;

export fn gen() i32 {
    // var p: i32 = undefined;
    // var d: i32 = undefined;
    // var o: i32 = undefined;
    // var count: i32 = undefined;
    // var c: i32 = undefined;
    // var op: i32 = undefined;
    // var oval: i32 = undefined;
    var p: i32 = 0;
    var d: i32 = 0;
    var o: i32 = 0;
    var count: i32 = 0;
    var c: i32 = 0;
    var op: i32 = 0;
    var oval: i32 = 0;

    err: {
        endparse: {
            while (true)  {
                push: {
                    op: {
                        num: {
                            p += 1;
                            c = @intToPtr(*u8, @intCast(usize, p) + 255).*;
                            if (c == 0) break :endparse;

                            op = c - 0x28;
                            // op = c - 40;
                            switch (op) {
                                0 => break :push,
                                1, 2, 3, 5, 7 => break :op,
                                8, 9, 10, 11, 12, 13, 14, 15, 16, 17 => break :num,
                                else => break :err,
                            }
                        }
                        d += 2;
                        @intToPtr(*i16, @intCast(usize, d) + 45).* = @intCast(i16, ((c - 0x30) << 8) | 0x41);

                        count += 1;
                        continue;
                    }
                    exit: {
                        while (true) {
                            if (o == 0) break :exit;
                            oval = @intToPtr(*u8, @intCast(usize, o) - 1 + 512).*;
                            if (oval == 0 or @intToPtr(*u8, @intCast(usize, oval)).* < @intToPtr(*u8, @intCast(usize, op)).*) break :exit;

                            count -= 1;
                            if (count < 1) break :err;

                            o -= 1;

                            d += 1;
                            @intToPtr(*u8, @intCast(usize, d) + 46).* = @intToPtr(*u8, @intCast(usize, oval) + 8).*;
                            continue;
                        }
                    }
                    if (op != 1) break :push;

                    if (o == 0) break :err;

                    o -= 1;
                    continue;
                }
                o += 1;
                @intToPtr(*u8, @intCast(usize, o) + 511).* = @intCast(u8, op);
                continue;
            }
        }
        exit: {
            while (true)  {
                if (o == 0) break :exit;

                count -= 1;
                if (count < 1) break :err;

                d += 1;
                o -= 1;
                @intToPtr(*u8, @intCast(usize, d) + 46).* = @intToPtr(*u8, @intToPtr(*u8, @intCast(usize, o) + 512).* + 8).*;
                continue ;
            }
        }
        if (count != 1) break :err;

        @intToPtr(*u8, @intCast(usize, d) + 47).* = 0xb;

        @intToPtr(*u8, 43).* = @intCast(u8, d + 4);

        @intToPtr(*u8, 45).* = @intCast(u8, d + 2);

        compile(d + 32);
        return 1;
    }
    return 0;
}

export fn call() i32 {
    return @intToPtr(fn () i32, 1)();
}

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

// export const data: []const u8 =
//   //  0   1   2   3   4   5   6   7
//   //  (   )   *   +   ,   -   .   /
//   //  x   0   2   1   x   1   x   2
//   "\x00\x00\x02\x01\x00\x01\x00\x02"  // precedence
//   ++ "\x00\x00\x6c\x6a\x00\x6b\x00\x6d"  // wasm op

//   ++ "\x00\x61\x73\x6d\x01\x00\x00\x00"  // magic/version
//   ++ "\x01\x05\x01\x60\x00\x01\x7f"     // type: func () -> i32
//   ++ "\x03\x02\x01\x00"              // func: type 0
//   ++ "\x07\x05\x01\x01\x30\x00\x00"     // export: func 0 -> "0"
//   ++ "\x0a\xff\x01\xff\x00";
