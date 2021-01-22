const std = @import("std");
const Allocator = std.mem.Allocator;

const windows = std.os.windows;

const WNDPROC = fn (windows.HWND, windows.UINT, windows.WPARAM, windows.LPARAM) callconv(windows.WINAPI) windows.LRESULT;

extern "user32" fn MessageBoxW(
    hWnd: ?HWND,
    lpText: LPCWSTR,
    lpCaption: LPCWSTR,
    uType: UINT,
) callconv(WINAPI) c_int;

extern "user32" fn AdjustWindowRectEx(lpRect: *RECT, dwStyle: windows.DWORD, bMenu: windows.BOOL, dwExStyle: windows.DWORD) callconv(windows.WINAPI) windows.BOOL;

extern "user32" fn DefWindowProcW(windows.HWND, windows.UINT, windows.WPARAM, windows.LPARAM) callconv(windows.WINAPI) windows.LRESULT;

extern "kernel32" fn OutputDebugStringW(lpOutputString: windows.LPCWSTR) callconv(windows.WINAPI) void;

extern "user32" fn DestroyWindow(hWnd: windows.HWND) callconv(windows.WINAPI) windows.BOOL;

extern "user32" fn GetClientRect(hWnd: windows.HWND, lpRect: *RECT) callconv(windows.WINAPI) windows.BOOL;
extern "user32" fn ValidateRect(hWnd: HWND, lpRect: *const RECT) callconv(WINAPI) BOOL;
extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(WINAPI) HDC;
extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(WINAPI) BOOL;

extern "gdi32" fn StretchDIBits(
    hdc: HDC,
    xDest: c_int,
    yDest: c_int,
    DestWidth: c_int,
    DestHeight: c_int,
    xSrc: c_int,
    ySrc: c_int,
    SrcWidth: c_int,
    SrcHeight: c_int,
    lpBits: *const c_void,
    lpbmi: *const BITMAPINFO,
    iUsage: UINT,
    rop: DWORD,
) callconv(WINAPI) c_int;

pub const Pixel = extern union {
    bits: u32,
    array: [4]u8,
    comp: struct {
        b: u8,
        g: u8,
        r: u8,
        a: u8,
    },
};
usingnamespace windows;

const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = @sizeOf(@This()),
    biWidth: LONG,
    biHeight: LONG,
    biPlanes: WORD = 1,
    biBitCount: WORD = 32,
    biCompression: DWORD = 0,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: LONG = 0,
    biYPelsPerMeter: LONG = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

const RGBQUAD = extern struct {
    rgbBlue: BYTE,
    rgbGreen: BYTE,
    rgbRed: BYTE,
    rgbReserved: BYTE,
};

const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

extern "user32" fn GetMessageW(
    lpmsg: *MSG,
    hwnd: ?HWND,
    wMsgFilterMin: UINT,
    wMsgFilterMax: UINT,
) callconv(WINAPI) BOOL;

const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: BOOL,
    rcPaint: RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]BYTE,
};

extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(WINAPI) LRESULT;

const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(@This()),
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: c_int,
    cbWndExtra: c_int,
    hInstance: HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?LPCWSTR,
    lpszClassName: LPCWSTR,
    hIconSm: ?HICON,
};

const CW_USEDEFAULT = @bitCast(i32, @as(u32, 0x80000000));

extern "user32" fn PostMessageW(
    hWnd: HWND,
    Msg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) BOOL;

const MSG = user32.MSG;

const CS_OWNDC = 0x0020;

extern "user32" fn RegisterClassExW(arg1: *const WNDCLASSEXW) callconv(WINAPI) ATOM;
extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: HINSTANCE) callconv(WINAPI) BOOL;
extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
    dwStyle: DWORD,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWindParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: ?LPVOID,
) callconv(WINAPI) ?HWND;

extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) callconv(WINAPI) LONG_PTR;
extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(WINAPI) LONG_PTR;

const WS_OVERLAPPED = 0;
const WS_CAPTION = 0x00C00000;
const WS_SYSMENU = 0x00080000;
const WS_THICKFRAME = 0x00040000;
const WS_VISIBLE = 0x10000000;

const WindowCreatePipe = struct {
    out_win: ?*Instance.Window = null,
    in_name: []const u8,
    in_width: i32,
    in_height: i32,
    in_x: ?i32,
    in_y: ?i32,
    in_flags: WindowCreateFlags,
    reset_event: std.Thread.ResetEvent,
};

const WindowCreateFlags = struct {
    resizable: bool,
};

pub const Bitmap = struct {
    pixels: []Pixel,
    width: usize,
    height: usize,
    stride: usize,
    pixel_rows: usize,
    x_offset: usize,
    y_offset: usize,
    direction: Direction,
    const Direction = enum { TopDown, BottomUp };
    pub fn create(allocator: *Allocator, width: usize, height: usize, direction: Direction) !@This() {
        const pixels = try allocator.alloc(Pixel, width * height);
        return @This(){
            .pixels = pixels,
            .width = width,
            .height = height,
            .pixel_rows = height,
            .stride = width,
            .direction = direction,
            .x_offset = 0,
            .y_offset = 0,
        };
    }

    pub fn subBitmap(this: *@This(), x: usize, y: usize, width: usize, height: usize) @This() {
        var bmp = this.*;
        bmp.x_offset += x;
        bmp.y_offset += y;
        bmp.width = width;
        bmp.height = height;
        return bmp;
    }

    const Row = struct { row: usize, pixels: []Pixel };

    pub fn getPixel(this: *@This(), x: usize, y: usize) *Pixel {
        return &this.pixels[x + this.x_offset + (y + this.y_offset) * this.stride];
    }

    const RowIterator = struct {
        current: usize = 0,
        pixels: []Pixel,
        height: usize,
        width: usize,
        stride: usize,
        pixel_rows: usize,
        x_offset: usize,
        y_offset: usize,
        pub fn next(self: *@This()) ?Row {
            if (self.current == self.height) {
                return null;
            } else {
                const whole_bitmap_row_start_index = (self.current + self.y_offset) * self.stride;
                const sub_bitmap_row_start_index = whole_bitmap_row_start_index + self.x_offset;
                const sub_bitmap_row_end_index = sub_bitmap_row_start_index + self.width;
                const row = .{
                    .row = self.current,
                    .pixels = self.pixels[sub_bitmap_row_start_index..sub_bitmap_row_end_index],
                };
                self.current += 1;
                return row;
            }
        }
    };

    pub fn rowIterator(self: *@This()) RowIterator {
        return .{
            .pixels = self.pixels,
            .height = self.height,
            .stride = self.stride,
            .pixel_rows = self.pixel_rows,
            .width = self.width,
            .x_offset = self.x_offset,
            .y_offset = self.y_offset,
        };
    }

    pub fn release(self: *@This(), allocator: *Allocator) void {
        allocator.free(self.pixels);
        self.* = undefined;
    }
};

fn windowProc(win: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(WINAPI) LRESULT {
    const fail_result = 1;
    return switch (msg) {
        user32.WM_CLOSE => {
            const window = @intToPtr(*Instance.Window, @bitCast(usize, GetWindowLongPtrW(win, 0)));
            window.addEvent(.{ .CloseRequest = {} }) catch return 1;
            return 0;
        },

        user32.WM_CREATE => {
            const createstruct = @intToPtr(*CREATESTRUCTW, @bitCast(usize, lparam));
            const wcs = @ptrCast(*WindowCreationInfo, @alignCast(
                @alignOf(WindowCreationInfo),
                createstruct.lpCreateParams,
            ));
            _ = SetWindowLongPtrW(win, 0, @bitCast(LONG_PTR, @ptrToInt(wcs.window)));
            var client_rect = @as(RECT, undefined);
            _ = GetClientRect(win, &client_rect);
            wcs.window.* = .{
                .allocator = wcs.allocator,
                .hwnd = win,
                .event_queue = std.atomic.Queue(Instance.Window.Event).init(),
                ._size = .{
                    .width = @intCast(u32, client_rect.right - client_rect.left),
                    .height = @intCast(u32, client_rect.bottom - client_rect.top),
                },
                .hdc = user32.GetDC(win) orelse return fail_result,
            };
            return 0;
        },

        user32.WM_SIZE => {
            const window = @intToPtr(*Instance.Window, @bitCast(usize, GetWindowLongPtrW(win, 0)));
            const size = lparam;
            var client_rect = @as(RECT, undefined);
            _ = GetClientRect(win, &client_rect);
            const width = @intCast(u32, client_rect.right - client_rect.left);
            const height = @intCast(u32, client_rect.bottom - client_rect.top);
            const dim = window._size.get();
            if (width != dim.width or height != dim.height) {
                window.addEvent(.{
                    .WindowResize = .{
                        .width = width,
                        .height = height,
                        .old_width = dim.width,
                        .old_height = dim.height,
                    },
                }) catch return fail_result;
                window._size.set(width, height);
            }
            return 0;
        },
        user32.WM_PAINT => {
            const window = @intToPtr(*Instance.Window, @bitCast(usize, GetWindowLongPtrW(win, 0)));
            var ps = @as(PAINTSTRUCT, undefined);
            _ = BeginPaint(win, &ps);
            _ = ValidateRect(win, &ps.rcPaint);
            window.addEvent(.{
                .RedrawRequest = .{
                    .x = ps.rcPaint.left,
                    .y = ps.rcPaint.top,
                    .width = @intCast(u32, ps.rcPaint.right - ps.rcPaint.left),
                    .height = @intCast(u32, ps.rcPaint.bottom - ps.rcPaint.top),
                },
            }) catch unreachable;
            _ = EndPaint(win, &ps);
            return 0;
        },

        else => DefWindowProcW(win, msg, wparam, lparam),
    };
}

fn messageWindowProc(win: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(WINAPI) LRESULT {
    return switch (msg) {
        else => DefWindowProcW(win, msg, wparam, lparam),
    };
}

const MessageThreadInputInfo = struct {
    message_window_ready: *std.Thread.ResetEvent,
    message_window: *?HWND,
    allocator: *Allocator,
    instance_name: []const u8,
};

const windows_private_message_start = 0x400;
const message_loop_terminate = windows_private_message_start + 0;
const message_loop_create_window = windows_private_message_start + 1;
const message_loop_show_window = windows_private_message_start + 2;

const CREATESTRUCTW = extern struct {
    lpCreateParams: LPVOID,
    hInstance: HINSTANCE,
    hMenu: HMENU,
    hwndParent: HWND,
    cy: c_int,
    cx: c_int,
    y: c_int,
    x: c_int,
    style: LONG,
    lpszName: LPCWSTR,
    lpszClass: LPCWSTR,
    dwExStyle: DWORD,
};

const WindowCreationInfo = struct {
    allocator: *Allocator,
    window: *Instance.Window,
};

fn messageLoop(
    allocator: *Allocator,
    message_wnd: HWND,
    reg_win_class_name: [:0]const u16,
    hinstance: HINSTANCE,
) !void {
    var message = @as(MSG, undefined);
    while (GetMessageW(&message, null, 0, 0) > 0) {
        switch (message.message) {
            message_loop_terminate => return, // WE DONE

            message_loop_show_window => {
                _ = user32.ShowWindow(message.hWnd.?, @bitCast(i32, @intCast(u32, message.wParam)));
            },

            message_loop_create_window => {
                // Unwrap the pipe we got sent in the lparam of the message
                const window_create_pipe = @intToPtr(*WindowCreatePipe, @bitCast(usize, message.lParam));
                defer window_create_pipe.reset_event.set();

                const name = std.unicode.utf8ToUtf16LeWithNull(allocator, window_create_pipe.in_name) catch continue;
                defer allocator.free(name);

                const window = allocator.create(Instance.Window) catch continue;
                var window_rect = RECT{ .left = 0, .right = window_create_pipe.in_width, .top = 0, .bottom = window_create_pipe.in_height };
                const base_style = @as(DWORD, WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU);
                const window_style = base_style | (if (window_create_pipe.in_flags.resizable) @as(DWORD, WS_THICKFRAME) else 0);
                _ = AdjustWindowRectEx(&window_rect, window_style, 0, 0);
                var wcs = WindowCreationInfo{ .allocator = allocator, .window = window };
                if (CreateWindowExW(
                    0,
                    reg_win_class_name,
                    name,
                    window_style,
                    window_create_pipe.in_x orelse CW_USEDEFAULT,
                    window_create_pipe.in_y orelse CW_USEDEFAULT,
                    window_rect.right - window_rect.left,
                    window_rect.bottom - window_rect.top,
                    null,
                    null,
                    hinstance,
                    &wcs,
                )) |_| {
                    window_create_pipe.out_win = window;
                }
            },

            else => {
                _ = user32.TranslateMessage(&message);
                _ = DispatchMessageW(&message);
            },
        }
    }
    return error.EarlyExit;
}

fn messageThread(input_info: MessageThreadInputInfo) !void {
    const allocator = input_info.allocator;
    const canon_name = std.unicode.utf8ToUtf16LeWithNull(allocator, input_info.instance_name) catch |err| {
        input_info.message_window_ready.set();
        return err;
    };
    defer allocator.free(canon_name);

    const fake_name = std.mem.concat(allocator, u8, &[_][]const u8{ input_info.instance_name, "messagewindow" }) catch |err| {
        input_info.message_window_ready.set();
        return err;
    };
    defer allocator.free(fake_name);

    const message_windowclass_name = std.unicode.utf8ToUtf16LeWithNull(allocator, fake_name) catch |err| {
        input_info.message_window_ready.set();
        return err;
    };
    defer allocator.free(message_windowclass_name);

    const hinstance = @ptrCast(HINSTANCE, kernel32.GetModuleHandleW(null));
    const wndclass = WNDCLASSEXW{
        .style = CS_OWNDC,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = @sizeOf(*Instance.Window),
        .hInstance = hinstance,
        .hIcon = null,
        .hbrBackground = null,
        .hCursor = null,
        .lpszMenuName = null,
        .lpszClassName = canon_name,
        .hIconSm = null,
    };

    const message_wndclass = WNDCLASSEXW{
        .style = 0,
        .lpfnWndProc = messageWindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hinstance,
        .hIcon = null,
        .hbrBackground = null,
        .hCursor = null,
        .lpszMenuName = null,
        .lpszClassName = message_windowclass_name,
        .hIconSm = null,
    };

    if (RegisterClassExW(&wndclass) == 0) {
        input_info.message_window_ready.set();
        std.log.err("{}", .{kernel32.GetLastError()});
        return error.OsError;
    }
    defer _ = UnregisterClassW(wndclass.lpszClassName, wndclass.hInstance);

    if (RegisterClassExW(&message_wndclass) == 0) {
        input_info.message_window_ready.set();
        std.log.err("{}", .{kernel32.GetLastError()});
        return error.OsError;
    }
    defer _ = UnregisterClassW(message_wndclass.lpszClassName, wndclass.hInstance);

    const message_window_name = [_:0]u16{'a'};

    if (CreateWindowExW(
        0,
        message_windowclass_name,
        message_window_name[0..],
        0,
        0,
        0,
        0,
        0,
        null,
        null,
        hinstance,
        null,
    )) |message_window| {
        _ = user32.ShowWindow(message_window, user32.SW_HIDE);
        _ = user32.ShowWindow(message_window, user32.SW_HIDE);
        defer _ = DestroyWindow(message_window);
        @atomicStore(?HWND, input_info.message_window, message_window, .SeqCst);
        input_info.message_window_ready.set();
        try messageLoop(allocator, message_window, canon_name, hinstance);
    } else {
        input_info.message_window_ready.set();
        return error.FailedToCreateInstance;
    }
}

pub const Instance = struct {
    instance_name: []u8,
    allocator: *std.mem.Allocator,
    message_thread: *std.Thread,
    message_window: HWND,

    pub fn init(allocator: *std.mem.Allocator, their_instance_name: []const u8) !@This() {
        // We don't want to take ownership but we need this
        const instance_name = try allocator.dupe(u8, their_instance_name);
        errdefer allocator.free(instance_name);

        var message_window_opt = @as(?HWND, null);
        var message_thread_ready: std.Thread.ResetEvent = @as(std.Thread.ResetEvent, undefined);
        try message_thread_ready.init();
        defer message_thread_ready.deinit();

        // Spawn a thread that will spin on the windows message queue
        // and make windows for us
        const message_thread = try std.Thread.spawn(
            MessageThreadInputInfo{
                .message_window_ready = &message_thread_ready,
                .message_window = &message_window_opt,
                .instance_name = instance_name,
                .allocator = allocator,
            },
            messageThread,
        );
        errdefer message_thread.wait();

        message_thread_ready.wait();

        if (message_window_opt) |message_window| {
            return @This(){
                .instance_name = instance_name,
                .allocator = allocator,
                .message_thread = message_thread,
                .message_window = message_window,
            };
        } else {
            return error.InstanceCreationFailed;
        }
    }

    const Window = struct {
        allocator: *Allocator,
        hwnd: HWND,
        _size: _Size,
        hdc: HDC,

        // TODO: Verify the atomics in here. I'm pretty sure I'm right but I'm not 100%
        event_queue: EventQueue,
        waiter_queue: ?*Node = null,

        const Dim = struct { width: u32, height: u32 };

        const _Size = struct {
            mutex: std.Thread.Mutex = .{},
            width: u32,
            height: u32,
            fn get(self: *@This()) Dim {
                const lock = self.mutex.acquire();
                defer lock.release();
                return .{ .width = self.width, .height = self.height };
            }
            fn set(self: *@This(), width: u32, height: u32) void {
                const lock = self.mutex.acquire();
                defer lock.release();
                self.width = width;
                self.height = height;
            }
        };

        const Node = struct {
            reset_event: std.Thread.StaticResetEvent = .{},
            next: ?*Node,
        };

        const EventQueue = std.atomic.Queue(Event);
        pub fn close(self: *@This()) void {
            _ = DestroyWindow(self.hwnd);
            const allocator = self.allocator;
            allocator.destroy(self);
        }

        const Event = union(enum) {
            CloseRequest: void, RedrawRequest: struct { x: i32, y: i32, width: u32, height: u32 }, WindowResize: struct {
                width: u32,
                height: u32,
                old_width: u32,
                old_height: u32,
            }
        };

        fn addEvent(self: *@This(), event: Event) !void {
            const node = try self.allocator.create(Instance.Window.EventQueue.Node);
            node.* = .{ .data = event };
            self.event_queue.put(node);
            while (@atomicLoad(?*Node, &self.waiter_queue, .Monotonic)) |waiter_node| {
                if (@cmpxchgWeak(?*Node, &self.waiter_queue, waiter_node, waiter_node.next, .Monotonic, .Monotonic)) |_| {} else {
                    waiter_node.reset_event.set();
                    return;
                }
            }
        }

        pub fn getSize(self: *@This()) Dim {
            return self._size.get();
        }

        pub fn getEvent(self: *@This()) Event {
            if (self.pollEvent()) |event| {
                return event;
            } else {
                while (true) {
                    var node = Node{ .next = @atomicLoad(?*Node, &self.waiter_queue, .Monotonic) };
                    if (self.pollEvent()) |event| {
                        return event;
                    } else {
                        if (@cmpxchgWeak(?*Node, &self.waiter_queue, node.next, &node, .Monotonic, .Monotonic)) |_| {} else {
                            node.reset_event.wait();
                        }
                    }
                }
            }
        }

        pub fn pollEvent(self: *@This()) ?Event {
            if (self.event_queue.get()) |event| {
                defer self.allocator.destroy(event);
                _ = self.event_queue.remove(event);
                return event.data;
            } else {
                return null;
            }
        }

        pub fn show(self: *@This()) void {
            _ = PostMessageW(self.hwnd, message_loop_show_window, user32.SW_SHOW, 0);
        }
        pub fn hide(self: *@This()) void {
            _ = PostMessageW(self.hwnd, message_loop_show_window, user32.SW_HIDE, 0);
        }
        pub fn blit(
            self: *@This(),
            bitmap: Bitmap,
            dest_x: u32,
            dest_y: u32,
        ) error{BlitError}!void {
            const bitmapinfo = BITMAPINFOHEADER{
                .biWidth = @intCast(i32, bitmap.stride),
                .biHeight = @intCast(i32, bitmap.height) * switch (bitmap.direction) {
                    .TopDown => @as(i32, -1),
                    .BottomUp => @as(i32, 1),
                },
            };

            // TODO: we don't actually want a stretch? What the fuck
            // else do we call
            if (StretchDIBits(
                self.hdc,
                @intCast(c_int, dest_x),
                @intCast(c_int, dest_y),
                @intCast(c_int, bitmap.width),
                @intCast(c_int, bitmap.height),
                @intCast(c_int, bitmap.x_offset),
                @intCast(c_int, bitmap.y_offset),
                @intCast(c_int, bitmap.width),
                @intCast(c_int, bitmap.height),
                bitmap.pixels.ptr,
                @ptrCast(*const BITMAPINFO, &bitmapinfo),
                0,
                0x00CC0020,
            ) == 0 and bitmap.height != 0) {
                return error.BlitError;
            }
        }
    };

    pub fn createWindow(
        self: *@This(),
        title: []const u8,
        width: i32,
        height: i32,
        x: ?i32,
        y: ?i32,
        create_flags: WindowCreateFlags,
    ) !*Window {
        const allocator = self.allocator;

        var window_create_pipe = WindowCreatePipe{
            .in_name = title,
            .in_width = width,
            .in_height = height,
            .in_x = x,
            .in_y = y,
            .in_flags = create_flags,
            .reset_event = @as(std.Thread.ResetEvent, undefined),
        };
        try window_create_pipe.reset_event.init();

        _ = PostMessageW(self.message_window, message_loop_create_window, 0, @bitCast(LPARAM, @ptrToInt(&window_create_pipe)));
        window_create_pipe.reset_event.wait();
        if (window_create_pipe.out_win) |window| {
            return window;
        } else {
            return error.CouldNotCreateWindow;
        }
    }

    pub fn deinit(self: *@This()) void {
        _ = PostMessageW(self.message_window, message_loop_terminate, 0, 0);
        self.message_thread.wait();
        self.allocator.free(self.instance_name);
    }
};

const OutputDebugStringError = error{InvalidUtf8};

fn flushBuf(buf: []u16, buf_chars: usize) void {
    buf[buf_chars] = 0;
    const slice = buf[0..buf_chars :0];
    OutputDebugStringW(slice.ptr);
}

fn outputDebugString(_: void, str: []const u8) OutputDebugStringError!usize {
    var buf: [4096]u16 = undefined;
    var buf_chars = @as(usize, 0);
    var view = try std.unicode.Utf8View.init(str);
    var iter = view.iterator();
    while (iter.nextCodepoint()) |codepoint| {
        if (codepoint < 0x10000) {
            const short = @intCast(u16, codepoint);
            if (buf_chars + 2 == buf.len) {
                flushBuf(buf[0..], buf_chars);
                buf_chars = 0;
            }
            buf[buf_chars] = short;
            buf_chars += 1;
        } else {
            if (buf_chars + 3 == buf.len) {
                flushBuf(buf[0..], buf_chars);
                buf_chars = 0;
            }
            const high = @intCast(u16, (codepoint - 0x10000) >> 10) + 0xD800;
            const low = @intCast(u16, codepoint & 0x3FF) + 0xDC00;
            buf[buf_chars] = std.mem.nativeToLittle(u16, high);
            buf[buf_chars + 1] = std.mem.nativeToLittle(u16, low);

            buf_chars += 2;
        }
    }
    flushBuf(buf[0..], buf_chars);

    return str.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .emerg => "emergency",
        .alert => "alert",
        .crit => "critical",
        .err => "error",
        .warn => "warning",
        .notice => "notice",
        .info => "info",
        .debug => "debug",
    };
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const held = std.debug.getStderrMutex().acquire();
    defer held.release();
    const use_windows_log = std.builtin.os.tag == .windows and std.builtin.subsystem != null and std.builtin.subsystem.? == .Windows;
    var writer = if (use_windows_log) std.io.Writer(void, OutputDebugStringError, outputDebugString){ .context = {} } else std.io.getStdErr().writer();

    _ = writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch {};
}

const MB_ICONEXCLAMATION = 0x00000030;

pub fn fatalErrorMessage(allocator: *Allocator, error_str: []const u8, title: []const u8) void {
    const error_str_u16 = std.unicode.utf8ToUtf16LeWithNull(allocator, error_str) catch |_| return;
    defer allocator.free(error_str_u16);
    const title_u16 = std.unicode.utf8ToUtf16LeWithNull(allocator, title) catch |_| return;
    defer allocator.free(title_u16);
    _ = MessageBoxW(null, error_str_u16, title_u16, MB_ICONEXCLAMATION);
}
