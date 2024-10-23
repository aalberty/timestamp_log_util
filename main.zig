const std = @import("std");
const Instant = std.time.Instant;
const print = std.debug.print;

// Been having an issue where my mouse periodically spazzes out; it'd be nice to have
// a quick tool to fire & forget when the issue starts so I can later try to track
// down the issue in logs somewhere.
// This means the program as a whole should:
//
// - Have an option to run with no input; this allows the fire & forget.
//      - This means we need some type of config or standard landing place for the
//          target log file.
// - "Optional" input parameter for a message to come after the timestamp so we can
//      indicate why we took that timestamp if we have multiple issues going on at
//      the same time
//
//
// Below are the stubs for these features:

const Time = struct { hours: u64, minutes: u64, seconds: u64 };

pub fn main() !void {
    // Inherently x-platform
    const test_time = std.time.timestamp();
    var only_time = @rem(test_time, std.time.s_per_day);
    // EST
    only_time -= (std.time.s_per_hour * 4);
    const my_time = secToTime(only_time);

    // This gets us the formatted timestamp that we would want to log out
    print("{d:2}:{d:2}.{d:2}\n\n\n", .{ my_time.hours, my_time.minutes, my_time.seconds });

    // can be tested using format `zig run main.zig -- arg_1 arg_2 ... arg_n`
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // This part works

    const args = try std.process.argsAlloc(arena);

    for (args, 1..) |arg, i| {
        print("arg_{}: {s}\n", .{ i, arg });
    }
}

//CONSIDER: add ns/ms support for more detailed timestamps?

/// Swap seconds to HH:MM.SS format
fn secToTime(s: i64) Time {
    const h: i64 = @divFloor(s, 3600);
    const u_h: u64 = @intCast(h);
    const m: i64 = @divFloor((s - (h * 3600)), 60);
    const u_m: u64 = @intCast(m);
    const rs: i64 = (s - (h * 3600) - (m * 60));
    const u_s: u64 = @intCast(rs);
    return Time{ .hours = u_h, .minutes = u_m, .seconds = u_s };
}
