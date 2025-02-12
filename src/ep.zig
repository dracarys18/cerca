const DoubleLinkedList = @import("ll").DoubleLinkedList;
const Node = @import("ll").Node;

const std = @import("std");

/// EvictionPolicy for `Cache`
///
/// Currently supported Cache eviction algorithms are
/// - LRU
/// - SIEVE
pub fn EvictionPolicy(comptime K: type, comptime V: type) type {
    return enum {
        LeastRecentlyUsed,
        Sieve,

        const Self = @This();

        pub inline fn evict(self: Self, ll: *DoubleLinkedList(K, V)) ?K {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (ll.front) |front| {
                        return front.key;
                    }
                    return null;
                },
                .Sieve => {
                    var hand = ll.hand orelse ll.back;

                    while (hand) |node| : (hand = node.prev orelse ll.back) {
                        if (!node.visited) {
                            ll.hand = node.prev;
                            return node.key;
                        }
                        node.visited = false;
                    }
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
