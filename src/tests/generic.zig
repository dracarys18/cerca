const Builder = @import("cache").CacheBuilder;
const EvictionPolicy = @import("ep").EvictionPolicy;

const std = @import("std");
const testing = std.testing;

var something: i32 = 10;

fn eviction(_: i32, _: i32) void {
    something -= 1;
}

test "Test if Eviction listener works" {
    const ep = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    var cache = Builder(i32, i32).new(ep).with_eviction_listener(eviction).build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(0, 0);
    _ = try cache.insert(1, 0);

    _ = cache.remove(0);
    _ = cache.remove(1);

    try testing.expectEqual(8, something);
}
