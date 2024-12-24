const std = @import("std");
const objc = @import("objc");

const CFIndex = isize;
const CFAllocatorRef = *anyopaque;
const CFStringEncoding = u32;
const CFStringRef = *anyopaque;
const CFRange = extern struct {
    location: CFIndex,
    length: CFIndex,
};

const kCFStringEncodingUTF8: CFStringEncoding = 0x08000100;
const kCFAllocatorDefault: CFAllocatorRef = @as(*anyopaque, undefined);
const kCFAllocatorNull: CFAllocatorRef = @as(*anyopaque, undefined);

extern "c" fn CFStringCreateWithBytesNoCopy(
    alloc: CFAllocatorRef,
    bytes: [*c]const u8,
    numBytes: CFIndex,
    encoding: CFStringEncoding,
    isExternalRepresentation: bool,
    contentsDeallocator: CFAllocatorRef,
) CFStringRef;

extern "c" fn CFStringGetBytes(
    theString: CFStringRef,
    range: CFRange,
    encoding: CFStringEncoding,
    lossByte: u8,
    isExternalRepresentation: bool,
    buffer: *anyopaque,
    maxBufLen: CFIndex,
    usedBufLen: *CFIndex,
) callconv(.C) isize;

inline fn cfString(str: []const u8) CFStringRef {
    const str_len = str.len;
    const quo = str_len / 8;
    const mod = str_len % 8;
    const aligned_len = 8 * (quo + (if (mod == 0) 0 else 1));

    return CFStringCreateWithBytesNoCopy(
        kCFAllocatorDefault,
        @as([*c]const u8, @ptrCast((str.ptr))),
        @as(isize, @intCast(aligned_len)),
        kCFStringEncodingUTF8,
        false,
        kCFAllocatorNull,
    );
}

pub fn main() !void {
    const str = "Hello, world!";
    const cf_string = cfString(str);
    defer std.c.free(cf_string);

    var buffer_w: [str.len:0]u8 = undefined;
    const range = CFRange{
        .location = 0,
        .length = @as(CFIndex, @intCast(str.len)),
    };

    var used_buf_len: CFIndex = 0;
    const result = CFStringGetBytes(
        cf_string,
        range,
        kCFStringEncodingUTF8,
        0,
        false,
        &buffer_w,
        @as(CFIndex, @intCast(buffer_w.len)),
        &used_buf_len,
    );
    _ = result;
    std.debug.print("encoded: {s}\n", .{str});
    std.debug.print("decoded: {s}\n", .{buffer_w});

    std.testing.expectEqualStrings(str, buffer_w[0..]) catch |err| {
        std.debug.print("error: {any}\n", .{err});
        return err;
    };
}

test "test" {
    // todo add test cases for varying lengths

}
