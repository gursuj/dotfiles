-- Personal keybindings, layered on Omarchy's defaults (t14).
--
-- Omarchy's own set lives in /usr/share/omarchy/default/hypr/bindings/*.lua and
-- must never be edited. Here: o.rebind replaces one of its binds, o.bind adds a
-- new one, hl.unbind disables one without a replacement.
--
-- Ported from the IdeaPad's monolithic hyprland.lua. Every conflict with
-- Omarchy's defaults was resolved deliberately -- the resolved mapping is
-- documented in the t14 branch's learnings.md.
--
-- NOTE: the external keyboard at the desk has no arrow keys, which is why
-- monitor movement lives on A/D (+SHIFT) rather than on the arrow keys.

---------------------------------------------------------------
-- terminal / close
---------------------------------------------------------------
-- SUPER+Q was the terminal on the IdeaPad. Omarchy binds both Q and W to close,
-- so Q is stolen back for the terminal and close keeps W (plus SHIFT+C for the
-- old muscle memory; that key was the HEY calendar web app, now uninstalled --
-- unbind is explicit because o.bind would otherwise leave both actions on it).
o.rebind("SUPER + Q", "Terminal", o.launch_terminal())
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Close window", hl.dsp.window.close())

---------------------------------------------------------------
-- maximize / file manager
---------------------------------------------------------------
-- Omarchy's SUPER+F (fullscreen) and SUPER+ALT+F (full width) stay untouched;
-- the IdeaPad's SUPER+F "maximize" lands on SHIFT+F. That frees the file
-- manager, which moves to E (was the HEY web app).
o.rebind("SUPER + SHIFT + F", "Maximize window", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.rebind("SUPER + E", "File manager", { omarchy = "nautilus" })
-- SUPER+T (float toggle) and SUPER+P (pseudo) stay Omarchy's.

---------------------------------------------------------------
-- exit
---------------------------------------------------------------
-- Omarchy's SHIFT+M was Spotify (not installed -- bind only); reused for exit.
-- Under uwsm this ends the Hyprland session and lands back on the SDDM greeter,
-- not a bare tty.
o.rebind("SUPER + SHIFT + M", "Exit Hyprland", hl.dsp.exit())

---------------------------------------------------------------
-- vim-style focus (Omarchy's arrows still work)
---------------------------------------------------------------
-- J and L were Omarchy's "toggle split" and "cycle layout"; both displaced to Z
-- (V and X are taken by Omarchy's universal paste/cut; the "cycle back" bind is dropped).
o.rebind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.rebind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.rebind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + Z", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + Z", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

---------------------------------------------------------------
-- tab = last window
---------------------------------------------------------------
-- SUPER+Tab was "next workspace"; the workspace keys (1..0) cover that, so
-- CTRL+Tab / CTRL+SHIFT+Tab take it over. Omarchy's "former workspace" bind on
-- CTRL+Tab is the casualty.
o.rebind("SUPER + TAB", "Last window", hl.dsp.focus({ last = true }))
o.rebind("SUPER + CTRL + TAB", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + CTRL + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))

---------------------------------------------------------------
-- keybindings guide
---------------------------------------------------------------
-- Omarchy's SUPER+SLASH was "monitor scale up" (unused here); the key now opens
-- the same guide `omarchy menu keybindings --print` documents.
hl.unbind("SUPER + SLASH")
o.bind("SUPER + SLASH", "Keybindings", "omarchy menu keybindings")

-- Password manager: Omarchy's SHIFT+SLASH was 1Password; Bitwarden instead
-- (native package in extra). The browser extension still does the filling.
o.rebind("SUPER + SHIFT + SLASH", "Bitwarden", o.launch("bitwarden"))

---------------------------------------------------------------
-- monitors
---------------------------------------------------------------
-- Omarchy's SUPER+A ("select all", i.e. send CTRL+A to the focused app) is
-- dropped: with no arrow keys on the external keyboard, A/D are needed for
-- moving workspaces/windows between monitors. Omarchy's own
-- SUPER+SHIFT+ALT+arrows / SUPER+SHIFT+CTRL+arrows monitor binds stay as well.
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Move workspace to upper monitor", o.workspaces.move_to_monitor("u"))
o.bind("SUPER + D", "Move workspace to lower monitor", o.workspaces.move_to_monitor("d"))
-- SHIFT+A was the ChatGPT web app, SHIFT+D the Docker TUI; both replaced. The
-- Docker TUI moves to CTRL+SHIFT+D (needs lazydocker installed, else it no-ops).
o.rebind("SUPER + SHIFT + A", "Send window to upper monitor", o.workspaces.move_window_to_monitor("u"))
o.rebind("SUPER + SHIFT + D", "Send window to lower monitor", o.workspaces.move_window_to_monitor("d"))
o.bind("SUPER + CTRL + SHIFT + D", "Docker TUI", { tui = "omarchy-launch-docker-tui" })

---------------------------------------------------------------
-- removed web apps (handle baked into the key, so unbind both halves)
---------------------------------------------------------------
-- Omarchy's HEY email/calendar handlers were uninstalled; their leftover binds
-- would still try to open a web app that no longer exists.
hl.unbind("SUPER + SHIFT + ALT + E")  -- "New email" (HEY)
hl.unbind("SUPER + SHIFT + E")        -- "Email" (HEY)
hl.unbind("SUPER + SHIFT + Y")        -- "YouTube"
hl.unbind("SUPER + SHIFT + X")        -- "X"

---------------------------------------------------------------
-- scratchpad + number-row moves
---------------------------------------------------------------
-- Omarchy's SHIFT+S was the Google Maps web app; it now moves the focused
-- window to the scratchpad without following it. (Omarchy's ALT+S still does
-- the same thing; this just puts it on the key the IdeaPad used.)
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Moving a window to a numbered workspace must NOT follow it: the window goes,
-- the focus stays where it is. Omarchy binds the row by keycode
-- (SUPER + code:10..19), so the rebind has to use the same form -- a keysym
-- rebind ("SUPER + 1") does not replace a code bind, it adds a second one.
for i = 1, 10 do
    local key = "code:" .. (i + 9)
    o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. i .. " (no follow)",
             o.workspaces.move_window(i, false))
end

---------------------------------------------------------------
-- workspace keys: focus the workspace that has something in it
---------------------------------------------------------------
-- Omarchy gives every monitor its own block of ten (the panel 1-10, the next
-- monitor 11-20) and SUPER+2 means "slot 2 of the focused monitor", so a key
-- pressed over the external screen opens an empty slot there while the one
-- worth seeing sits on the other screen. Prefer a populated workspace: the
-- focused monitor's own first (a repeat press stays put), then the lowest
-- populated slot anywhere. With nothing populated, fall back to Omarchy's own
-- focus, which reuses or creates the local slot.
local function focus_slot(slot)
    local focused = hl.get_active_monitor()
    local focused_id = focused and o.workspaces.workspace_id(focused, slot)
    local best = nil

    for _, workspace in ipairs(hl.get_workspaces()) do
        local occupied = not workspace.special and workspace.id > 0 and (workspace.windows or 0) > 0

        if occupied and (workspace.id - 1) % 10 + 1 == slot then
            if workspace.id == focused_id then
                best = workspace.id
                break
            elseif not best or workspace.id < best then
                best = workspace.id
            end
        end
    end

    if best then
        hl.dispatch(hl.dsp.focus({ workspace = tostring(best) }))
    else
        hl.dispatch(o.workspaces.focus(slot))
    end
end

-- Exposed on o.workspaces so the keybindings menu can replay it, the way
-- Omarchy's own actions are addressable: `hyprctl dispatch
-- 'o.workspaces.focus_occupied(5)'` runs exactly what the key runs.
function o.workspaces.focus_occupied(slot)
    return function() focus_slot(slot) end
end

-- Same keycode form as Omarchy's row: a keysym rebind ("SUPER + 5") would add a
-- second binding instead of replacing the code one.
for i = 1, 10 do
    local key = "code:" .. (i + 9)
    o.rebind("SUPER + " .. key, "Focus workspace " .. i .. " (wherever it has windows)",
             function() focus_slot(i) end)
end

---------------------------------------------------------------
-- browser / swallow
---------------------------------------------------------------
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + CTRL + SLASH", "Toggle window swallow", hl.dsp.window.toggle_swallow())

---------------------------------------------------------------
-- picture-in-picture helper on SUPER+P; Omarchy's "pseudo" moves to SHIFT+P
---------------------------------------------------------------
-- One-way: float the focused window, shrink to 32% of monitor width using the
-- window's own aspect ratio, lock that ratio persistently, then pin.
--
-- Pseudo (Omarchy's own SUPER+P) is rebound to SHIFT+P just below.
o.rebind("SUPER + P", "Picture-in-picture", function()
    local win = hl.get_active_window()
    if not win then return end

    local mon = win.monitor or hl.get_active_monitor()
    if not mon then return end

    if not win.floating then
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end

    local sz   = win.size
    local curW = (sz and (sz.x or sz.w)) or mon.width
    local curH = (sz and (sz.y or sz.h)) or mon.height

    local targetW = mon.width * 0.32
    local targetH = targetW * (curH / curW)

    -- keep_aspect_ratio has to be a persistent window property (value 1, not a
    -- Lua boolean) -- the resize dispatcher's own flag only covers that single
    -- call, so a later manual drag could still distort the window.
    hl.dispatch(hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = 1, window = win }))
    hl.dispatch(hl.dsp.window.resize({ x = targetW, y = targetH }))

    if not win.pinned then
        hl.dispatch(hl.dsp.window.pin())
    end
end)

-- pseudo window: Omarchy's own SUPER+P, displaced by the PiP helper above.
-- SHIFT+P was the Google Photos web app; it is uninstalled.
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Pseudo window", hl.dsp.window.pseudo())

---------------------------------------------------------------
-- free resize on SUPER+R (dwm-style, ported from the IdeaPad)
---------------------------------------------------------------
-- Press once, move the mouse without holding a button, press R/Escape/Enter (or
-- click) to stop. For floating windows the corner nearest the cursor at press
-- time becomes the anchor, so grabbing near the top-left grows that way.
local MIN_SIZE = 20
local free_resize = { active = false, win = nil, timer = nil }

local function stop_free_resize()
    free_resize.active = false
    if free_resize.timer then free_resize.timer:set_enabled(false) end
    free_resize.timer = nil
    free_resize.win   = nil
    hl.dispatch(hl.dsp.submap("reset"))
end

hl.define_submap("free_resize", function()
    hl.bind("Escape", stop_free_resize)
    hl.bind("Return", stop_free_resize)
    hl.bind("mouse:272", stop_free_resize)
    hl.bind("mouse:273", stop_free_resize)
end)

hl.bind("SUPER + R", function()
    if free_resize.active then
        stop_free_resize()
        return
    end

    local win = hl.get_active_window()
    if not win then return end

    local start = hl.get_cursor_pos()
    if not start then return end

    free_resize.active = true
    free_resize.win    = win

    if win.floating then
        local pos = win.at
        local sz  = win.size
        local baseX, baseY = (pos and (pos.x or pos[1])) or 0, (pos and (pos.y or pos[2])) or 0
        local baseW, baseH = (sz and (sz.x or sz.w)) or 1, (sz and (sz.y or sz.h)) or 1

        local dirX = ((start.x - baseX) / baseW < 0.5) and -1 or 1
        local dirY = ((start.y - baseY) / baseH < 0.5) and -1 or 1

        free_resize.timer = hl.timer(function()
            if not free_resize.active then return end
            local cur = hl.get_cursor_pos()
            if not cur then return end

            local dx = cur.x - start.x
            local dy = cur.y - start.y

            local newW = math.max(MIN_SIZE, baseW + dirX * dx)
            local newH = math.max(MIN_SIZE, baseH + dirY * dy)
            local newX = (dirX < 0) and (baseX + (baseW - newW)) or baseX
            local newY = (dirY < 0) and (baseY + (baseH - newH)) or baseY

            hl.dispatch(hl.dsp.window.resize({ x = newW, y = newH, window = free_resize.win }))
            hl.dispatch(hl.dsp.window.move({ x = newX, y = newY, window = free_resize.win }))
        end, { type = "repeat", timeout = 16 })
    else
        local last = start
        free_resize.timer = hl.timer(function()
            if not free_resize.active then return end
            local cur = hl.get_cursor_pos()
            if not cur then return end

            local dx = cur.x - last.x
            local dy = cur.y - last.y

            if dx ~= 0 or dy ~= 0 then
                hl.dispatch(hl.dsp.window.resize({ x = dx, y = dy, relative = true, window = free_resize.win }))
            end

            last = cur
        end, { type = "repeat", timeout = 16 })
    end

    hl.dispatch(hl.dsp.submap("free_resize"))
end, { submap_universal = true })

---------------------------------------------------------------
-- resize / volume / brightness / media
---------------------------------------------------------------
o.bind("SUPER + SHIFT + H", "Resize left",  hl.dsp.window.resize({ x = -100, y = 0,   relative = true }))
o.bind("SUPER + SHIFT + L", "Resize right", hl.dsp.window.resize({ x = 100,  y = 0,   relative = true }))
o.bind("SUPER + SHIFT + J", "Resize down",  hl.dsp.window.resize({ x = 0,    y = 100, relative = true }))
o.bind("SUPER + SHIFT + K", "Resize up",    hl.dsp.window.resize({ x = 0,    y = -100, relative = true }))

o.bind("SUPER + EQUAL",     "Volume up",   "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", { locked = true })
o.bind("SUPER + MINUS",     "Volume down", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { locked = true })
o.bind("SUPER + SHIFT + EQUAL", "Brightness up",   "brightnessctl s 8%+", { locked = true })
o.bind("SUPER + SHIFT + MINUS", "Brightness down", "brightnessctl s 8%-", { locked = true })

-- External monitor (BenQ GW2270, DDC/CI). Needs ddcutil + i2c-dev + i2c group.
-- Omarchy already uses CTRL+XF86* for the keyboard backlight, hence CTRL+SHIFT
-- (coarse) and SUPER (fine) here. --sn pins this specific monitor; --noverify
-- keeps each press fast instead of probing every bus.
local benq_sn = "3BG00085019"
-- CTRL + brightness: Omarchy binds these to the keyboard backlight (its macOS
-- convention). On the T14 the external panel is what we want on those keys; the
-- keyboard backlight keeps its own XF86KbdBrightnessUp/Down keys.
hl.unbind("CTRL + XF86MonBrightnessUp")
hl.unbind("CTRL + XF86MonBrightnessDown")
o.bind("CTRL + XF86MonBrightnessUp",   "External brightness up",   "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 + 8", { locked = true, repeating = true })
o.bind("CTRL + XF86MonBrightnessDown", "External brightness down", "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 - 8", { locked = true, repeating = true })

o.bind("CTRL + SHIFT + XF86MonBrightnessUp",   "External brightness up",   "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 + 8", { locked = true })
o.bind("CTRL + SHIFT + XF86MonBrightnessDown", "External brightness down", "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 - 8", { locked = true })
o.bind("SUPER + XF86MonBrightnessUp",   "External brightness up fine",   "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 + 2", { locked = true })
o.bind("SUPER + XF86MonBrightnessDown", "External brightness down fine", "ddcutil --sn " .. benq_sn .. " --noverify setvcp 10 - 2", { locked = true })

o.bind("SUPER + BRACKETRIGHT", "Next track",     "playerctl next",       { locked = true })
o.bind("SUPER + BRACKETLEFT",  "Previous track", "playerctl previous",   { locked = true })
o.bind("SUPER + BACKSLASH",    "Play/pause",     "playerctl play-pause", { locked = true })

o.bind("SUPER + PERIOD", "Emoji picker", "rofimoji -r '' -a type copy")

---------------------------------------------------------------
-- screenshots
---------------------------------------------------------------
-- Omarchy owns PRINT (omarchy-capture-screenshot: picker for region/window/
-- screen, copies *and* saves), plus SUPER+PRINT colour picker, SUPER+CTRL+PRINT
-- OCR and the SUPER+CTRL+C capture menu. hyprshot is not installed here, so its
-- old binds are gone; SHIFT+PRINT is the "save a region without the picker"
-- shortcut the IdeaPad used.
o.bind("SHIFT + PRINT", "Screenshot: save region", "omarchy-capture-screenshot region save")

---------------------------------------------------------------
-- touchpad gestures
---------------------------------------------------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down", scale = 0.5, action = "float" })

---------------------------------------------------------------
-- Omarchy's own reference notes (kept from the shipped file)
---------------------------------------------------------------
-- See current bindings and descriptions:
--   omarchy menu keybindings --print
-- To disable every Omarchy default binding, set in ~/.config/hypr/hyprland.lua
-- before require("default.hypr.omarchy"): omarchy_default_bindings = false
-- To disable all preinstalled app/webapp bindings:
--   omarchy_preinstalled_bindings = false
