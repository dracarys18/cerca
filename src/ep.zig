const DoubleLinkedList = @import("././ll.zig").DoubleLinkedList;
const Node = @import("././ll.zig").Node;
const std = @import("std");

/// EvictionPolicy for `Cache`
///
/// Currently supported Cache eviction algorithms are
/// - LRU
/// - SIEVE (TODO)
pub fn EvictionPolicy(comptime V: type) type {
    return enum {
        LeastRecentlyUsed,
        Sieve,

        const Self = @This();

        pub inline fn evict(self: Self, queue: *DoubleLinkedList(V)) void {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (queue.front) |front| {
                        queue.remove(front);
                    }
                },
                .Sieve => {
                    return;
                },
            }
        }

        pub inline fn get(self: Self, node: ?*Node(V), queue: *DoubleLinkedList(V)) ?V {
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

        pub inline fn insert(self: Self, allocator: std.mem.Allocator, node: ?*Node(V), queue: *DoubleLinkedList(V), value: V) !?*Node(V) {
            switch (self) {
                .LeastRecentlyUsed => {
                    if (node) |nonull_node| {
                        nonull_node.data = value;
                        queue.moveToBack(nonull_node);
                        return null;
                    } else {
                        const new_node = try Node(V).init(value, allocator);
                        queue.push_back(new_node);
                        return new_node;
                    }
                },
                .Sieve => return null,
            }
        }
    };
}
