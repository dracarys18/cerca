const DoubleLinkedList = @import("././ll.zig").DoubleLinkedList;
const Node = @import("././ll.zig").Node;
const Cache = @import("./cache.zig").Cache;

const std = @import("std");

/// EvictionPolicy for `Cache`
///
/// Currently supported Cache eviction algorithms are
/// - LRU
/// - SIEVE (TODO)
pub fn EvictionPolicy(comptime K: type, comptime V: type) type {
    return enum {
        LeastRecentlyUsed,
        Sieve,

        const Self = @This();

        pub inline fn evict(self: Self, cache: *Cache(K, V)) bool {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (cache.expiry.front) |front| {
                        const to_remove = front.key;
                        return cache.remove(to_remove);
                    }
                    return false;
                },
                .Sieve => {
                    var hand = cache.expiry.hand orelse cache.expiry.back;

                    while (hand) |node| : (hand = node.prev orelse cache.expiry.back) {
                        if (!node.visited) {
                            cache.expiry.hand = node.prev;
                            return cache.remove(node.key);
                        }
                        node.visited = false;
                    }
                    return false;
                },
            }
        }

        pub inline fn get(self: Self, node: ?*Node(K, V), queue: *DoubleLinkedList(K, V)) ?V {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (node) |nonull_node| {
                        queue.moveToBack(nonull_node);
                        return nonull_node.data;
                    } else {
                        return null;
                    }
                },
                .Sieve => {
                    if (node) |nonull_node| {
                        nonull_node.set_visited(true);
                        return nonull_node.data;
                    }
                    return null;
                },
            }
        }

        pub inline fn insert(self: Self, allocator: std.mem.Allocator, node: ?*Node(K, V), queue: *DoubleLinkedList(K, V), key: K, value: V) !?*Node(K, V) {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (node) |nonull_node| {
                        nonull_node.data = value;
                        queue.moveToBack(nonull_node);
                        return null;
                    } else {
                        const new_node = try Node(K, V).init(key, value, allocator);
                        const is_pushed = queue.push_back(new_node);

                        if (is_pushed) {
                            return new_node;
                        } else {
                            new_node.deinit();
                            return null;
                        }
                    }
                },
                .Sieve => {
                    if (node) |nonull_node| {
                        nonull_node.data = value;
                        nonull_node.visited = true;
                        return null;
                    } else {
                        const new_node = try Node(K, V).init(key, value, allocator);
                        const is_pushed = queue.push_front(new_node);

                        if (is_pushed) {
                            return new_node;
                        } else {
                            new_node.deinit();
                            return null;
                        }
                    }
                },
            }
        }
    };
}
