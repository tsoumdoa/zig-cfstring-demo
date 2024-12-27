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
const CFTypeRef = *anyopaque;

pub extern "objc" fn CFStringCreateWithCharacters(
    alloc: CFAllocatorRef,
    chars: *const u16,
    numChars: CFIndex,
) CFStringRef;

extern "c" fn CFShow(obj: CFTypeRef) void;
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
    const unicode = std.unicode.utf8ToUtf16LeStringLiteral(str);
    return CFStringCreateWithCharacters(
        kCFAllocatorDefault,
        @as([*c]const u16, @ptrCast(unicode.ptr)),
        @as(isize, @intCast(unicode.len)),
    );
}

pub fn main() !void {
    const sub = "CPU Stats";
    const str = "CPU Core Performance States";
    const sub_cf_string = cfString(sub);
    const cf_string = cfString(str);
    CFShow(sub_cf_string);
    CFShow(cf_string);
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
    // it still fails with a memory error...
}
