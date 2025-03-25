const std = @import("std");
const assert = std.debug.assert;
const Node = @import("ll").Node;
const DoubleLinkedList = @import("ll").DoubleLinkedList;
const EvictionPolicy = @import("ep").EvictionPolicy;
const Notifier = @import("notify").Notifier;
const defaults = @import("defaults");
const map = @import("chashmap");

/// Builder for the Cache. With toggles for various features.
pub fn CacheBuilder(comptime K: type, comptime V: type) type {
    return struct {
        /// Sets the maximum capacity of the Cache
        limit: usize,

        /// Sets the EvictionPolicy of the Cache
        eviction: EvictionPolicy(K, V),

        /// TTL - Time to live for an object
        ttl: ?i64,

        /// Listener function to execute when the key is evicted
        listener: ?fn (key: K, value: V) void,

        const Self = @This();

        /// Default Constructor for the CacheBuilder. Note that it's mandatory to choose eviction policy at this step
        pub fn new(eviction: EvictionPolicy(K, V)) Self {
            return Self{ .limit = defaults.DEFAULT_MAX_CAPACITY, .eviction = eviction, .ttl = null, .listener = null };
        }

        /// Sets the limit variable to passed limit. Otherwise the limit would be 100
        pub fn with_limit(self: Self, limit: usize) Self {
            return Self{ .limit = limit, .eviction = self.eviction, .ttl = self.ttl, .listener = self.listener };
        }

        /// Sets the TTL in milliseconds for the cache
        pub fn with_ttl(self: Self, ttl: i64) Self {
            return Self{ .limit = self.limit, .eviction = self.eviction, .ttl = ttl, .listener = self.listener };
        }

        /// Executes the passed function on every eviction
        pub fn with_eviction_listener(self: Self, listener: fn (key: K, value: V) void) Self {
            return Self{ .limit = self.limit, .eviction = self.eviction, .ttl = self.ttl, .listener = listener };
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
        inner: map.ChashMap(K, *Node(K, V)),
        expiry: DoubleLinkedList(K, V),
        allocator: std.mem.Allocator,
        eviction: EvictionPolicy(K, V),
        notifier: ?Notifier(K, V),
        limit: usize,
        ttl: ?i64,

        const Self = @This();

        fn initOptions(allocator: std.mem.Allocator, builder: CacheBuilder(K, V)) Self {
            return Self{ .inner = map.ChashMap(K, *Node(K, V)).init(allocator), .expiry = DoubleLinkedList(K, V).empty(), .allocator = allocator, .limit = builder.limit, .eviction = builder.eviction, .ttl = builder.ttl, .notifier = if (builder.listener) |listener| Notifier(K, V).init(listener) else null };
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
                const key_evict = self.eviction.evict(&self.expiry);

                if (key_evict) |evict| {
                    assert(self.remove(evict));
                }
            }

            return is_inserted;
        }

        /// Get an element from the cache
        pub fn get(self: *Self, key: K) ?V {
            const node = self.inner.get(key);

            if (node) |node_nonull| {
                if (self.ttl) |actual_ttl| {
                    const now = std.time.milliTimestamp();

                    if (now - node_nonull.inserted_at > actual_ttl) {
                        assert(self.remove(key));
                        return null;
                    }
                }
            }

            return self.eviction.get(node, &self.expiry);
        }

        /// Remove an element from the cache
        pub fn remove(self: *Self, key: K) bool {
            const value = self.inner.fetchRemove(key);

            if (value) |kv| {
                self.notify(kv.key, kv.value.data);
                self.expiry.remove(kv.value);
                kv.value.deinit();
                return true;
            } else {
                return false;
            }
        }

        fn notify(self: *Self, key: K, value: V) void {
            if (self.notifier) |notifier| {
                notifier.notify(key, value);
            }
        }
    };
}
