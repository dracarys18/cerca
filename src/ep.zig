const DoubleLinkedList = @import("././ll.zig").DoubleLinkedList;
const Node = @import("././ll.zig").Node;
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

        pub inline fn evict(self: Self, queue: *DoubleLinkedList(K, V)) ?K {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (queue.front) |front| {
                        const key = front.key;
                        queue.remove(front);

                        return key;
                    }
                    return null;
                },
                .Sieve => {
                    return null;
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
                .Sieve => return null,
            }
        }
    };
}
