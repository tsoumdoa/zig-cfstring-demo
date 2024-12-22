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

fn cfString(string: []const u8) CFStringRef {
    return CFStringCreateWithBytesNoCopy(
        kCFAllocatorDefault,
        @as([*c]const u8, @ptrCast(string.ptr)),
        @as(isize, @intCast(string.len)),
        kCFStringEncodingUTF8,
        false,
        kCFAllocatorNull,
    );
}

pub fn main() !void {
    const string = "Hello, world!";
    const cf_string = cfString(string);
    defer std.c.free(cf_string);

    var buffer_w: [string.len:0]u8 = undefined;
    const range = CFRange{
        .location = 0,
        .length = @as(CFIndex, @intCast(string.len)),
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

    std.debug.print("result: {any}\n", .{result});

    std.testing.expectEqualStrings(string, buffer_w[0..]) catch |err| {
        std.debug.print("error: {any}\n", .{err});
        return err;
    };
}

test "test" {
    const string = "Hello, world!";
    const cf_string = cfString(string);
    defer std.c.free(cf_string);

    var buffer_w: [string.len:0]u8 = undefined;
    const range = CFRange{
        .location = 0,
        .length = @as(CFIndex, @intCast(string.len)),
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

    std.debug.print("result: {any}\n", .{result});

    std.testing.expectEqualStrings(string, buffer_w[0..]) catch |err| {
        std.debug.print("error: {any}\n", .{err});
        return err;
    };
}
