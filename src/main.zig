const std = @import("std");
const ll = @import("./cache.zig");
const EvictionPolicy = @import("./ep.zig").EvictionPolicy;

pub fn main() !void {
    // var ll = DoubleLinkedList(u64).empty();

    // var node = Node(u64).new(0);
    // ll.push_front(&node);

    // ll.print_queue();
    // var node1 = Node(u64).new(1);
    // ll.push_back(&node1);

    // var node2 = Node(u64).new(2);
    // ll.push_back(&node2);

    // ll.print_queue();
    // ll.remove(&node1);
    // ll.print_queue();

    var arena = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = arena.allocator();

    var cache = ll.CacheBuilder(u64, u64).new(EvictionPolicy(u64).LeastRecentlyUsed).with_limit(10).build(allocator);
    defer cache.deinit();

    _ = try cache.insert(1, 1);
    _ = try cache.insert(2, 2);
    _ = try cache.insert(3, 3);
    _ = try cache.insert(4, 4);
    _ = try cache.insert(5, 1);
    _ = try cache.insert(6, 2);
    _ = try cache.insert(7, 3);
    _ = try cache.insert(8, 4);
    _ = try cache.insert(9, 1);
    _ = try cache.insert(10, 2);
    _ = try cache.insert(11, 3);
    _ = try cache.insert(12, 4);

    if (cache.get(1)) |v| {
        std.debug.print("Success {}", .{v});
    }
}
