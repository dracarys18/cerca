const std = @import("std");
const RwLock = std.Thread.RwLock;
const Allocator = std.mem.Allocator;

pub fn ChashMap(comptime K: type, comptime V: type) type {
    return struct {
        rwlock: RwLock,
        base: std.AutoHashMap(K, V),
        allocator: Allocator,

        const Self = @This();
        const KV = struct {
            key: K,
            value: V,
        };

        pub fn init(allocator: Allocator) Self {
            const base = std.AutoHashMap(K, V).init(allocator);

            return Self{
                .base = base,
                .rwlock = RwLock{},
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.base.deinit();
        }

        pub fn get(self: *Self, key: K) ?V {
            self.rwlock.lockShared();
            defer self.rwlock.unlockShared();

            return self.base.get(key);
        }

        pub fn put(self: *Self, key: K, value: V) Allocator.Error!void {
            self.rwlock.lock();
            defer self.rwlock.unlock();

            return self.base.put(key, value);
        }

        pub fn fetchRemove(self: *Self, key: K) ?KV {
            self.rwlock.lock();
            defer self.rwlock.unlock();

            const kv = self.base.fetchRemove(key);

            if (kv) |v| {
                return KV{ .key = v.key, .value = v.value };
            } else {
                return null;
            }
        }
    };
}
