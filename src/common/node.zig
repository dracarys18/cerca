const std = @import("std");

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
        visited: bool,

        pub fn init(key: K, value: V, allocator: std.mem.Allocator) !*Self {
            var node = try allocator.create(Self);
            errdefer _ = allocator.destroy(node);

            const curr = std.time.milliTimestamp();

            node.prev = null;
            node.next = null;
            node.key = key;
            node.data = value;
            node.allocator = allocator;
            node.inserted_at = curr;
            node.visited = false;

            return node;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }

        pub fn set_visited(self: *Self, val: bool) void {
            self.visited = val;
        }

        pub fn set_modified(self: *Self, val: i64) void {
            self.modified_at = val;
        }
    };
}
