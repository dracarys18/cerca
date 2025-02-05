const std = @import("std");
const Node = @import("./ll.zig").Node;
const DoubleLinkedList = @import("./ll.zig").DoubleLinkedList;
const EvictionPolicy = @import("./ep.zig").EvictionPolicy;
const defaults = @import("./defaults.zig");

/// Builder for the Cache. With toggles for various features.
pub fn CacheBuilder(comptime K: type, comptime V: type) type {
    return struct {
        /// Sets the maximum capacity of the Cache
        limit: usize,

        /// Sets the EvictionPolicy of the Cache
        eviction: EvictionPolicy(K, V),

        const Self = @This();

        /// Default Constructor for the CacheBuilder. Note that it's mandatory to choose eviction policy at this step
        pub fn new(eviction: EvictionPolicy(K, V)) Self {
            return Self{ .limit = defaults.DEFAULT_MAX_CAPACITY, .eviction = eviction };
        }

        /// Sets the limit variable to passed limit. Otherwise the limit would be 100
        pub fn with_limit(self: Self, limit: usize) Self {
            return Self{ .limit = limit, .eviction = self.eviction };
        }

        /// Builds a Cache(K,V)
        pub fn build(self: Self, allocator: std.mem.Allocator) Cache(K, V) {
            return Cache(K, V).initOptions(allocator, self);
        }
    };
}

/// Cache is a thread-safe (TODO) in-memory cache with the goal of faster retrieval with efficiency from in-memory
///
/// `Cache` supports different kinds of evictions. So far it supports
/// - LRU
/// - SIEVE (TODO)
pub fn Cache(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, *Node(K, V)),
        expiry: DoubleLinkedList(K, V),
        allocator: std.mem.Allocator,
        eviction: EvictionPolicy(K, V),
        limit: usize,

        const Self = @This();

        fn initOptions(allocator: std.mem.Allocator, builder: CacheBuilder(K, V)) Self {
            return Self{ .inner = std.AutoHashMap(K, *Node(K, V)).init(allocator), .expiry = DoubleLinkedList(K, V).empty(), .allocator = allocator, .limit = builder.limit, .eviction = builder.eviction };
        }

        /// Releases all the memory allocated by `Cache`
        pub fn deinit(self: *Self) void {
            self.expiry.clear();
            self.inner.deinit();

            self.* = undefined;
        }

        /// Inserts an element into the the Cache
        pub fn insert(self: *Self, key: K, value: V) !bool {
            const node = self.inner.get(key);
            const new_node = try self.eviction.insert(self.allocator, node, &self.expiry, key, value);
            var is_inserted = false;

            errdefer if (new_node) |nonull_node| {
                nonull_node.deinit();
            };

            if (new_node) |nonull_node| {
                try self.inner.put(key, nonull_node);
                is_inserted = true;
            }

            if (self.expiry.size > self.limit) {
                const to_remove = self.eviction.evict(&self.expiry);
                if (to_remove) |key_to_remove| {
                    _ = self.remove(key_to_remove);
                }
            }

            return is_inserted;
        }

        /// Get an element from the cache
        pub fn get(self: *Self, key: K) ?V {
            const node = self.inner.get(key);
            return self.eviction.get(node, &self.expiry);
        }

        /// Remove an element from the cache
        pub fn remove(self: *Self, key: K) bool {
            const value = self.inner.fetchRemove(key);

            if (value) |kv| {
                self.expiry.remove(kv.value);
                kv.value.deinit();
                return true;
            } else {
                return false;
            }
        }
    };
}
