const std = @import("std");

pub fn Node(comptime V: type) type {
    return struct {
        const Self = @This();

        data: V,
        prev: ?*Self,
        next: ?*Self,

        pub fn new(value: V, allocator: std.mem.Allocator) !*Self {
            var node = try allocator.create(Self);

            node.prev = null;
            node.next = null;
            node.data = value;

            return node;
        }
    };
}

pub fn DoubleLinkedList(comptime V: type) type {
    return struct {
        const Self = @This();

        front: ?*Node(V),
        back: ?*Node(V),
        size: usize,

        pub fn empty() Self {
            return Self{
                .front = null,
                .back = null,
                .size = 0,
            };
        }

        pub fn push_front(self: *Self, value: *Node(V)) void {
            if (self.front == value) {
                return;
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
        }

        pub fn push_back(self: *Self, value: *Node(V)) void {
            if (self.back == value) {
                return;
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
        }

        pub fn moveToBack(self: *Self, node: *Node(V)) void {
            // If the next is null node is already at the back
            if (node.next == null) {
                return;
            }

            // Queue has only one element
            if (self.front == self.back) {
                return;
            }

            // If the node is already in the back
            if (self.back == node) {
                return;
            }

            // If the node was intermediate of the queue
            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                // Node was in the front
                self.front = node.next;
            }

            node.prev = self.back;
            node.next = null;

            self.back.?.next = node;
            self.back = node;
        }

        pub fn remove(self: *Self, node: *Node(V)) void {
            // If the node was intermediate of the queue
            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                self.front = node.next;
            }

            if (node.next) |next| {
                next.prev = node.prev;
            } else {
                self.back = node.next;
            }

            node.prev = null;
            node.next = null;
            self.size -= 1;
        }

        pub fn print_queue(self: *Self) void {
            var front = self.front;

            std.debug.print("Queue \t", .{});
            while (front) |node| {
                std.debug.print("{}", .{node.data});
                front = node.next;
            }

            std.debug.print("\n", .{});
        }
    };
}

pub fn CacheBuilder(comptime K: type, comptime V: type) type {
    return struct {
        ttl: ?u64,
        limit: ?usize,

        const Self = @This();
        pub fn new() Self {
            return Self{ .ttl = null, .limit = null };
        }

        pub fn with_ttl(self: *Self, ttl: u64) *Self {
            self.ttl = ttl;
            return self;
        }

        pub fn with_limit(self: *Self, limit: usize) *Self {
            self.limit = limit;
            return self;
        }

        pub fn build(self: *Self, allocator: std.mem.Allocator) Cache(K, V) {
            return Cache(K, V).initOptions(allocator, self.ttl orelse 100000, self.limit orelse 2);
        }
    };
}

pub fn Cache(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, Node(V)),
        expiry: DoubleLinkedList(K),
        allocator: std.mem.Allocator,
        ttl: u64,
        limit: usize,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .inner = std.AutoHashMap(K, Node(V)).init(allocator), .expiry = DoubleLinkedList(K).empty(), .allocator = allocator, .ttl = null, .limit = 2 };
        }

        pub fn initOptions(allocator: std.mem.Allocator, ttl: u64, limit: usize) Self {
            return Self{ .inner = std.AutoHashMap(K, Node(V)).init(allocator), .expiry = DoubleLinkedList(K).empty(), .allocator = allocator, .ttl = ttl, .limit = limit };
        }

        pub fn deinit(self: *Self) void {
            self.inner.deinit();
        }

        pub fn insert(self: *Self, key: K, value: V) !void {
            const node = try Node(V).new(value, self.allocator);
            try self.inner.put(key, node.*);
            self.expiry.push_back(node);

            std.debug.print("Size: {}\n Limit: {} \n", .{ self.expiry.size, self.limit });
            if (self.expiry.size >= self.limit) {
                self.evict();
            }

            self.expiry.print_queue();
        }

        pub fn evict(self: *Self) void {
            if (self.expiry.front) |front| {
                std.debug.print("Evicting {}", .{front.data});
                self.expiry.remove(front);
            }
        }

        pub fn get(self: *Self, key: K) ?V {
            const node = self.inner.getPtr(key);

            if (node) |nonull_node| {
                self.expiry.moveToBack(nonull_node);
                return nonull_node.data;
            } else {
                return null;
            }
        }

        pub fn remove(self: *Self, key: K) bool {
            const value = self.inner.get(key);

            if (value) |node| {
                self.expiry.remove(&node);
                return self.inner.remove(key);
            } else {
                return false;
            }
        }
    };
}
