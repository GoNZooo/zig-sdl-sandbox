const std = @import("std");
const debug = std.debug;

const c = @import("./c.zig");

const GameState = struct {
    box: MovingRectangle,
    tick: u64,
    running: bool,
};

const MovingRectangle = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    w: u32,
    h: u32,
};

pub fn main() anyerror!void {
    var window: ?*c.SDL_Window = null;
    var surface: ?*c.SDL_Surface = null;

    var game = GameState{
        .box = MovingRectangle{ .x = 50.0, .y = 50.0, .dx = 0, .dy = 0, .w = 10, .h = 10 },
        .tick = 0,
        .running = true,
    };

    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        const error_value = c.SDL_GetError();
        debug.warn("Unable to initialize SDL: {}\n", .{error_value});
        c.exit(1);
    } else {
        window = c.SDL_CreateWindow(
            "SDL Sandbox",
            c.SDL_WINDOWPOS_UNDEFINED,
            c.SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            c.SDL_WINDOW_SHOWN,
        );
        if (window == null) {
            debug.warn("Unable to create window: {}\n", .{c.SDL_GetError()});
            c.exit(1);
        } else {
            surface = c.SDL_GetWindowSurface(window);
        }
    }

    var keyboard: [*]const u8 = undefined;
    while (game.running) : (game.tick += 1) {
        _ = c.SDL_PumpEvents();
        keyboard = c.SDL_GetKeyboardState(null);
        update(&game, keyboard);
        render(window.?, surface.?, game);
        _ = c.SDL_Delay(10);
    }

    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}

fn update(game: *GameState, keyboard: [*]const u8) void {
    defer game.tick += 1;
    debug.warn("x={}, y={}\n", .{ @floatToInt(c_int, game.box.x), @floatToInt(c_int, game.box.y) });
    // debug.warn("dx={}, dy={}\n", .{ game.box.dx, game.box.dy });
    if (keyboard[c.SDL_SCANCODE_ESCAPE] == 1) {
        game.running = false;
    }
    if (keyboard[c.SDL_SCANCODE_W] == 1) {
        game.box.dy -= 0.5;
    }
    if (keyboard[c.SDL_SCANCODE_S] == 1) {
        game.box.dy += 0.5;
    }
    if (keyboard[c.SDL_SCANCODE_A] == 1) {
        game.box.dx -= 0.5;
    }
    if (keyboard[c.SDL_SCANCODE_D] == 1) {
        game.box.dx += 0.5;
    }

    game.box.dx += -game.box.dx / 25;
    game.box.dy += -game.box.dy / 25;

    clampedAddFloat(&game.box.x, game.box.dx, 0, @intToFloat(f32, width - game.box.w));
    clampedAddFloat(&game.box.y, game.box.dy, 0, @intToFloat(f32, height - game.box.h));
}

fn render(window: *c.SDL_Window, surface: *c.SDL_Surface, game: GameState) void {
    _ = c.SDL_FillRect(surface, null, c.SDL_MapRGB(surface.format, 0xff, 0xff, 0xff));

    const box_rectangle = c.SDL_Rect{
        .x = @floatToInt(c_int, game.box.x),
        .y = @floatToInt(c_int, game.box.y),
        .w = 10,
        .h = 10,
    };

    _ = c.SDL_FillRect(surface, &box_rectangle, c.SDL_MapRGB(surface.format, 0, 0, 0));

    _ = c.SDL_UpdateWindowSurface(window);
}

fn clampedAddFloat(value: *f32, f: f32, lower_limit: f32, upper_limit: f32) void {
    value.* += f;

    if (value.* < lower_limit) {
        value.* = lower_limit;
    } else if (value.* > upper_limit) {
        value.* = upper_limit;
    }
}

const width: u32 = 640;
const height: u32 = 480;
