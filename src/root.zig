const std = @import("std");
const testing = std.testing;
const ll = @import("././ll.zig");

test "linkedlist_test" {
    var queue = ll.DoubleLinkedList(u64).empty();
    const node = try ll.Node(u64).new(1, testing.allocator);
    queue.push_front(node);

    testing.expect(if (queue.front) |front| return front.data == 1);
}
