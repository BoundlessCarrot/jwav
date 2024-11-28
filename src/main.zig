const std = @import("std");
// const rl = @import("raylib");

// const riffID = enum {
//
// };

const ew = std.mem.endsWith;
const eql = std.mem.eql;

const Container = struct {
    allocator: std.mem.Allocator,
    chunkLookupTable: std.StringHashMap(usize),
    filename: []const u8 = undefined,

    const Self = @This();

    fn deinit(self: *Self) void {
        self.chunkLookupTable.deinit();
        // self.allocator.free(self.filename);
    }

    fn init(allocator: std.mem.Allocator) Container {
        return Container{
            .allocator = allocator,
            .chunkLookupTable = std.StringHashMap(usize).init(allocator),
        };
    }
};

fn openWavFile(container: Container) void {
    if (!ew(u8, container.filename, ".wav")) {
        std.log.err("It seems this filetype may be unsupported\n", .{});
        return;
    }

    const file = std.fs.cwd().openFile(container.filename, .{}) catch |err| {
        std.log.err("Unable to open file: {s}\n", .{@errorName(err)});
        return;
    };
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var headerBuf: [44]u8 = undefined;
    const bytes_read = in_stream.read(&headerBuf) catch |err| {
        std.log.err("Unable to parse header: {s}\n", .{@errorName(err)});
        return;
    };

    std.debug.print("{s}\n", .{headerBuf});
    std.debug.print("{d}\n", .{bytes_read});

    // const riffID: []const u8 = in_stream[0..4];
    // const waveID: []const u8 = in_stream[4..8];
    //
    // if (!eql(u8, riffID, "RIFF") and eql(u8, waveID, "WAVE")) {
    //     std.log.err("Invalid .wav file\n", .{});
    //     return;
    // }
    //
    // container.chunkLookupTable.put(riffID, 0);
    //
    // const stat = file.stat() catch |err| {
    //     std.log.err("Unable to get file details: {s}\n", .{@errorName(err)});
    //     return;
    // };
    // const size = stat.size;
    //
    // var pos: usize = 8;
    // try file.seekTo(pos);
    //
    // while (pos <= size) : (file.seekTo(pos) catch |err| {
    //     std.log.err("Unable to seek to position {d}: {s}\n", .{ pos, @errorName(err) });
    //     return;
    // }) {
    //     const chunkID: []const u8 = in_stream[pos..(pos + 4)];
    //     container.chunkLookupTable.put(chunkID, pos);
    //
    //     const chunkSize = in_stream.readInt(usize);
    //     pos += chunkSize;
    // }
}

fn handleCommandLineArgs(args: *std.process.ArgIterator, container: *Container) void {
    while (args.next()) |arg| {
        if (eql(u8, arg, "--file")) {
            container.filename = args.next().?;
        } else {
            std.debug.print("Argument {s} not recognized\n", .{arg});
            std.process.exit(0);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    _ = args.skip();

    var container = Container.init(gpa.allocator());
    defer container.deinit();

    handleCommandLineArgs(&args, &container);

    openWavFile(container);

    // std.debug.print("{any}\n", .{container.chunkLookupTable});
}
