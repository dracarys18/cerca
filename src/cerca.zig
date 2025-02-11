const std = @import("std");
const testing = std.testing;
const defaults = @import("./defaults.zig");

pub const CacheBuilder = @import("./cache.zig").CacheBuilder;
pub const Cache = @import("./cache.zig").Cache;
pub const EvictionPolicy = @import("./ep.zig").EvictionPolicy;

test "CacheBuilder initializes with default limit (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy);
    try testing.expectEqual(defaults.DEFAULT_MAX_CAPACITY, builder.limit);
}

test "CacheBuilder sets custom limit (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(200);
    try testing.expectEqual(200, builder.limit);
}

test "Cache initializes with builder options (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(200);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    try testing.expectEqual(200, cache.limit);
    try testing.expectEqual(eviction_policy, cache.eviction);
}

test "Cache inserts and retrieves elements (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);

    try testing.expectEqual(@as(?i32, 10), cache.get(1));
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
}

test "Cache evicts elements when limit is reached (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);
    _ = try cache.insert(3, 30); // This should evict the least recently used item (key 1)

    try testing.expectEqual(@as(?i32, null), cache.get(1)); // 1 should be evicted
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
    try testing.expectEqual(@as(?i32, 30), cache.get(3));
}

test "Cache removes elements correctly (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);

    try testing.expect(cache.remove(1));
    try testing.expectEqual(@as(?i32, null), cache.get(1)); // 1 should be removed
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
}

test "Cache updates duplicate keys (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    const inserted = try cache.insert(1, 20); // Should not insert duplicate key

    try testing.expect(!inserted); // Should return false for duplicate key
    try testing.expectEqual(@as(?i32, 20), cache.get(1)); // Value should be updated to 20
}

test "Test if TTL actually works (LRU)" {
    const eviction_policy = EvictionPolicy(i32, i32).LeastRecentlyUsed;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2).with_ttl(100);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();
    _ = try cache.insert(1, 10);

    std.time.sleep(100 * std.time.ns_per_ms);
    try testing.expectEqual(@as(?i32, null), cache.get(1));
}

test "CacheBuilder initializes with default limit (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy);
    try testing.expectEqual(defaults.DEFAULT_MAX_CAPACITY, builder.limit);
}

test "CacheBuilder sets custom limit (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(200);
    try testing.expectEqual(200, builder.limit);
}

test "Cache initializes with builder options (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(200);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    try testing.expectEqual(200, cache.limit);
    try testing.expectEqual(eviction_policy, cache.eviction);
}

test "Cache inserts and retrieves elements (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);

    try testing.expectEqual(@as(?i32, 10), cache.get(1));
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
}

test "Cache evicts elements when limit is reached (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);
    _ = try cache.insert(3, 30); // This should evict the least recently used item (key 1)

    try testing.expectEqual(@as(?i32, null), cache.get(1)); // 1 should be evicted
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
    try testing.expectEqual(@as(?i32, 30), cache.get(3));
}

test "Cache removes elements correctly (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    _ = try cache.insert(2, 20);

    try testing.expect(cache.remove(1));
    try testing.expectEqual(@as(?i32, null), cache.get(1)); // 1 should be removed
    try testing.expectEqual(@as(?i32, 20), cache.get(2));
}

test "Cache updates duplicate keys (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();

    _ = try cache.insert(1, 10);
    const inserted = try cache.insert(1, 20); // Should not insert duplicate key

    try testing.expect(!inserted); // Should return false for duplicate key
    try testing.expectEqual(@as(?i32, 20), cache.get(1)); // Value should be updated to 20
}

test "Test if TTL actually works (Sieve)" {
    const eviction_policy = EvictionPolicy(i32, i32).Sieve;
    const builder = CacheBuilder(i32, i32).new(eviction_policy).with_limit(2).with_ttl(100);
    var cache = builder.build(testing.allocator);
    defer cache.deinit();
    errdefer cache.deinit();
    _ = try cache.insert(1, 10);

    std.time.sleep(100 * std.time.ns_per_ms);
    try testing.expectEqual(@as(?i32, null), cache.get(1));
}
