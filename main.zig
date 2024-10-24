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
//      - Optional in quotes since the impl can be "if no args, don't add a label/add generic"
//
//
// can be tested using format `zig run main.zig -- arg_1 arg_2 ... arg_n`

const std = @import("std");
const File = std.fs.File;
const print = std.debug.print;

const Time = struct { hours: u64, minutes: u64, seconds: u64 };

pub fn main() !void {
    const test_time = std.time.timestamp();
    var only_time = @rem(test_time, std.time.s_per_day);
    // EST(-ish; daylight savings time sucks)
    only_time -= (std.time.s_per_hour * 4);
    const my_time = secToTime(only_time);

    print("{d:2}:{d:2}.{d:2}\n\n\n", .{ my_time.hours, my_time.minutes, my_time.seconds });

    const c_file = openConfFile(); // TODO: catch potential err here
    defer c_file.close();
    // TODO: write timestamp to config file

    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    for (args, 1..) |arg, i| {
        print("arg_{}: {s}\n", .{ i, arg });
    }
}

//CONSIDER: add ns/ms support for more detailed timestamps?

fn secToTime(s: i64) Time {
    const h: i64 = @divFloor(s, 3600);
    const u_h: u64 = @intCast(h);
    const m: i64 = @divFloor((s - (h * 3600)), 60);
    const u_m: u64 = @intCast(m);
    const rs: i64 = (s - (h * 3600) - (m * 60));
    const u_s: u64 = @intCast(rs);
    return Time{ .hours = u_h, .minutes = u_m, .seconds = u_s };
}

/// Makes it if it doesn't yet exist; returns the file for use
fn openConfFile() !File {
    const cwd: std.fs.Dir = std.fs.cwd();

    // If I'm reading the docs right, we should be able to try creating the file,
    // and the default `exclusive=false` flag on the call should make it so that
    // if the file already exists, then it just opens it.

    const file: std.fs.File = try cwd.createFile(".timestump", .{});
    // Caller needs to close file!!!
    return file;
}
