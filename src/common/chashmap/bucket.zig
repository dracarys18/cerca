const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const RwLock = std.Thread.RwLock;

pub fn Bucket(comptime K: type, comptime V: type) type {
    return struct {
        key: K,
        value: V,
        is_tombstone: bool,

        const Self = @This();

        fn init(alloc: std.mem.Allocator, key: K, value: V) !*Self {
            var self = try alloc.create(Self);
            self.key = key;
            self.value = value;
            self.is_tombstone = false;

            return self;
        }
    };
}

pub fn BucketArray(comptime K: type, comptime V: type) type {
    return struct {
        buckets: []*Bucket(K, V),
        next: ?*BucketArray(K, V),
        allocator: std.mem.Allocator,
        size: usize,
        capacity: usize,
        lock: RwLock,

        const Self = @This();

        pub fn init(size: usize, alloc: std.mem.Allocator) !Self {
            const capacity: usize = @max(size * 2, 2);
            const buckets = try alloc.alloc(*Bucket(K, V), capacity);
            return Self{ .buckets = buckets, .allocator = alloc, .size = size, .capacity = capacity, .lock = RwLock{} };
        }

        pub fn deinit(self: *Self) void {
            self.lock.lock();
            defer self.lock.unlock();

            self.allocator.free(self.buckets);

            while (self.next) |next| {
                next.deinit();
            }

            self.capacity = 0;
            self.size = 0;
            self.* = undefined;
        }

        pub fn insert(self: *Self, index: usize, key: K, value: V) !void {
            self.lock.lock();
            defer self.lock.unlock();

            self.buckets[index] = try Bucket(K, V).init(key, value);
        }

        pub fn append(self: *Self, key: K, value: V) !void {
            assert(self.capacity < self.size);

            const index: usize = self.size - 1;
            return self.insert(index, key, value);
        }

        pub fn remove(self: *Self, index: usize) void {
            self.buckets[index].is_tombstone = true;
        }

        pub fn get(self: *Self, index: usize) ?V {
            const ele = self.buckets[index];
            return ele.value;
        }
    };
}
