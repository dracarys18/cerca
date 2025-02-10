const std = @import("std");
const assert = std.debug.assert;

/// A single node of a queue
pub fn Node(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        key: K,
        data: V,
        inserted_at: i64,
        prev: ?*Self,
        next: ?*Self,
        allocator: std.mem.Allocator,

        pub fn init(key: K, value: V, allocator: std.mem.Allocator) !*Self {
            var node = try allocator.create(Self);
            errdefer _ = allocator.destroy(node);

            node.prev = null;
            node.next = null;
            node.key = key;
            node.data = value;
            node.allocator = allocator;
            node.inserted_at = std.time.milliTimestamp();

            return node;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }
    };
}

pub fn DoubleLinkedList(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        front: ?*Node(K, V),
        back: ?*Node(K, V),
        size: usize,

        pub fn empty() Self {
            return Self{
                .front = null,
                .back = null,
                .size = 0,
            };
        }

        pub fn push_front(self: *Self, value: *Node(K, V)) bool {
            if (self.front == value) {
                return false;
            }

            if (self.front == null) {
                self.front = value;
                self.back = value;
            } else {
                value.next = self.front;
                value.prev = null;

                self.front.?.prev = value;
                self.front = value;
            }

            self.size += 1;
            return true;
        }

        pub fn push_back(self: *Self, value: *Node(K, V)) bool {
            if (self.back == value) {
                return false;
            }

            if (self.back == null) {
                self.front = value;
                self.back = value;
            } else {
                value.prev = self.back;
                value.next = null;

                self.back.?.next = value;
                self.back = value;
            }

            self.size += 1;
            return true;
        }

        pub fn moveToBack(self: *Self, node: *Node(K, V)) void {
            self.remove(node);
            _ = self.push_back(node);
        }

        pub fn remove(self: *Self, node: *Node(K, V)) void {
            // If the node was intermediate of the queue
            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                self.front = node.next;
            }

            if (node.next) |next| {
                next.prev = node.prev;
            } else {
                self.back = node.prev;
            }

            self.size -= 1;
        }

        pub fn clear(self: *Self) void {
            var front = self.front;
            while (front) |fnl| {
                const next = fnl.next;
                fnl.deinit();

                front = next;
                self.size -= 1;
            }
            assert(self.size == 0);
            self.* = undefined;
        }

        pub fn print_queue(self: *Self) void {
            var front = self.front;

            while (front) |node| {
                std.debug.print("{}", .{node.data});
                front = node.next;
            }

            std.debug.print("\n", .{});
        }
    };
}
