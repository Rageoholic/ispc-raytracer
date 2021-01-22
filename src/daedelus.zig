const builtin = @import("builtin");

const windows = @import("platform/windows.zig");

pub usingnamespace if (builtin.os.tag == .windows) windows else @compileError("Make a platform impl for this platform");
