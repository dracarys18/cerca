const Bucket = @import("./bucket.zig").Bucket;
const atomic = @import("std").atomic;

pub fn ChashMap(comptime K: type, comptime V: type) type {
    return struct { bucket: atomic.Value(Bucket(K, V)) };
}
