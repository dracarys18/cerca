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

        /// Matches the eviction policy and evicts the elements acccording to the policy selected
        pub inline fn evict(self: Self, ll: *DoubleLinkedList(K, V)) ?K {
            switch (self) {
                // LRU evicts the element in the front of the queue. Meaning a least recently used
                // element will always be at the front of the queue
                .LeastRecentlyUsed => {
                    if (ll.front) |front| {
                        return front.key;
                    }
                    return null;
                },

                // Sieve takes a little different approach to eviction, Instead of moving the element in
                // the queue everytime you get an element, SIEVE marks it as visited=true, this is what you call
                // a lazy promotion. And during eviction the first element from the back of the queue where the visited=false
                // is evicted and the prev to the node which is evicted is marked as `hand` from which the next eviction starts.
                // All the subsequent elements where visited = true from back to the hand will be demoted. Which is called quick demotion
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

        /// Matches the eviction policy and modifies the elements in the queue as defined
        pub inline fn get(self: Self, node: ?*Node(K, V), queue: *DoubleLinkedList(K, V)) ?V {
            switch (self) {
                // On every get the node is moved to back in LRU
                .LeastRecentlyUsed => {
                    if (node) |nonull_node| {
                        queue.moveToBack(nonull_node);
                        return nonull_node.data;
                    } else {
                        return null;
                    }
                },
                // SIEVE does not modify the queue, rather it just marks the node as visited
                .Sieve => {
                    if (node) |nonull_node| {
                        nonull_node.set_visited(true);
                        return nonull_node.data;
                    }
                    return null;
                },
            }
        }

        /// Matches the eviction policy and modifies the elements in the queue and cache as defined
        pub inline fn insert(self: Self, allocator: std.mem.Allocator, node: ?*Node(K, V), queue: *DoubleLinkedList(K, V), key: K, value: V) !?*Node(K, V) {
            switch (self) {
                // Every insert happens at the back of the queue
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
                // Every insert happens at the front of the queue
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
