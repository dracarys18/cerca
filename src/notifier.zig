pub fn Listener(comptime K: type, comptime V: type) type {
    return fn (key: K, value: V) void;
}

pub fn Notifier(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        /// Listener function which is passsed by the user
        listener: Listener(K, V),

        /// Initialise the Listener with listener function
        pub fn init(listener: Listener(K, V)) Self {
            return Self{ .listener = listener };
        }

        pub fn notify(self: Self, key: K, value: V) void {
            self.listener(key, value);
        }
    };
}
