pub fn Notifier(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        /// Listener function which is passsed by the user
        listener: *const fn (key: K, value: V) void,

        /// Initialise the Listener with listener function
        pub fn init(listener: fn (key: K, value: V) void) Self {
            return Self{ .listener = listener };
        }

        pub fn notify(self: Self, key: K, value: V) void {
            self.listener(key, value);
        }
    };
}
