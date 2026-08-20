-- Swayimg config (converted from old INI syntax, swayimg >= 5.5 uses Lua).
-- Old file backed up at config.ini.bak.
-- Ref: /usr/share/doc/swayimg/CONFIG.md, /usr/share/swayimg/swayimg.lua (LSP defs)

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.mode = "viewer"
swayimg.antialiasing = true          -- was "mks13"; 5.5 only supports bool
swayimg.decoration = false
swayimg.overlay = false
swayimg.appid = "swayimg"
-- NOTE: old general.position/size are no longer config-settable; use
-- CLI flags --position and --size instead.

--------------------------------------------------------------------------------
-- Image list
--------------------------------------------------------------------------------
swayimg.imagelist.order = "numeric"
swayimg.imagelist.recursive = false
swayimg.imagelist.adjacent = true    -- old list.all=yes
swayimg.imagelist.fsmon = true

--------------------------------------------------------------------------------
-- Text overlay (old [font] + [info])
--------------------------------------------------------------------------------
swayimg.text.visible = true
swayimg.text.font = "JetBrains Mono SemiBold"
swayimg.text.size = 14
swayimg.text.color = 0xffcccccc
swayimg.text.background = 0x00000000
swayimg.text.shadow = 0xd0000000
swayimg.text.timeout = 5
swayimg.text.status_timeout = 3

--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.default_scale = "optimal"
swayimg.viewer.default_position = "center"
swayimg.viewer.history = 1
swayimg.viewer.preload = 1
swayimg.viewer.set_window_background(0xaa000000) -- old viewer.window=#000000AA

-- old [info.viewer] scheme
swayimg.viewer.set_text("topleft", {
  "{name}",
  "{format}",
  "{sizehr}",
  "{frame.width}x{frame.height}",
  "EXIF date:\t{meta.Exif.Photo.DateTimeOriginal}",
  "EXIF camera:\t{meta.Exif.Image.Model}",
})
swayimg.viewer.set_text("topright", { "{list.index} of {list.total}" })
swayimg.viewer.set_text("bottomleft", {
  "Scale:\t{scale}",
  "Frame:\t{frame.index} of {frame.total}",
})

swayimg.viewer.on_signal("USR1", function() swayimg.viewer.reload() end)
swayimg.viewer.on_signal("USR2", function() swayimg.viewer.open("next") end)

-- keybindings
swayimg.viewer.on_key("Home", function() swayimg.viewer.open("first") end)
swayimg.viewer.on_key("End", function() swayimg.viewer.open("last") end)
swayimg.viewer.on_key("Prior", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("Shift+Space", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("Next", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("Space", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("Shift+r", function() swayimg.viewer.open("random") end)
swayimg.viewer.on_key("Shift+d", function() swayimg.viewer.open("prev_dir") end)
swayimg.viewer.on_key("d", function() swayimg.viewer.open("next_dir") end)
swayimg.viewer.on_key("Shift+o", function()
  local frame = swayimg.viewer.frame
  if frame > 0 then swayimg.viewer.frame = frame - 1 end
end)
swayimg.viewer.on_key("o", function() swayimg.viewer.frame = swayimg.viewer.frame + 1 end)

-- skip_file: drop current image from list, keep file on disk, advance
swayimg.viewer.on_key("c", function()
  local img = swayimg.viewer.get_image()
  if img then
    swayimg.imagelist.remove(img.path)
    swayimg.viewer.open("next")
  end
end)

swayimg.viewer.on_key("s", function() swayimg.viewer.animation = not swayimg.viewer.animation end)
swayimg.viewer.on_key("f", function() swayimg.fullscreen = not swayimg.fullscreen end)
swayimg.viewer.on_key("Return", function() swayimg.mode = "gallery" end)

-- step move 10px
local function step(dx, dy)
  local pos = swayimg.viewer.get_position()
  swayimg.viewer.set_abs_position(pos.x + dx, pos.y + dy)
end
swayimg.viewer.on_key("h", function() step(10, 0) end)
swayimg.viewer.on_key("l", function() step(-10, 0) end)
swayimg.viewer.on_key("k", function() step(0, 10) end)
swayimg.viewer.on_key("j", function() step(0, -10) end)
swayimg.viewer.on_key("Left", function() step(10, 0) end)
swayimg.viewer.on_key("Right", function() step(-10, 0) end)
swayimg.viewer.on_key("Up", function() step(0, 10) end)
swayimg.viewer.on_key("Down", function() step(0, -10) end)

swayimg.viewer.on_key("Equal", function() swayimg.viewer.scale = swayimg.viewer.scale * 1.1 end)
swayimg.viewer.on_key("Plus", function() swayimg.viewer.scale = swayimg.viewer.scale * 1.1 end)
swayimg.viewer.on_key("Minus", function() swayimg.viewer.scale = swayimg.viewer.scale / 1.1 end)
swayimg.viewer.on_key("w", function() swayimg.viewer.set_fix_scale("width") end)
swayimg.viewer.on_key("Shift+w", function() swayimg.viewer.set_fix_scale("height") end)
swayimg.viewer.on_key("0", function() swayimg.viewer.set_fix_scale("fit") end)
swayimg.viewer.on_key("Shift+0", function() swayimg.viewer.set_fix_scale("fill") end)
swayimg.viewer.on_key("BackSpace", function() swayimg.viewer.set_fix_scale("optimal") end)
swayimg.viewer.on_key("z", function() swayimg.viewer.set_fix_scale("keep") end)

swayimg.viewer.on_key("bracketleft", function() swayimg.viewer.rotate(270) end)
swayimg.viewer.on_key("bracketright", function() swayimg.viewer.rotate(90) end)
swayimg.viewer.on_key("m", function() swayimg.viewer.flip_vertical() end)
swayimg.viewer.on_key("Shift+m", function() swayimg.viewer.flip_horizontal() end)
swayimg.viewer.on_key("a", function() swayimg.antialiasing = not swayimg.antialiasing end)
swayimg.viewer.on_key("r", function() swayimg.viewer.reload() end)
swayimg.viewer.on_key("i", function() swayimg.text.visible = not swayimg.text.visible end)

-- delete file from disk + list, advance
swayimg.viewer.on_key("Shift+Delete", function()
  local img = swayimg.viewer.get_image()
  if img then
    os.remove(img.path)
    swayimg.text.status = "File removed: " .. img.path
    swayimg.imagelist.remove(img.path)
    swayimg.viewer.open("next")
  end
end)

swayimg.viewer.on_key("Escape", function() swayimg.exit() end)
swayimg.viewer.on_key("q", function() swayimg.exit() end)

-- mouse
swayimg.viewer.on_mouse("ScrollLeft", function() step(-5, 0) end)
swayimg.viewer.on_mouse("ScrollRight", function() step(5, 0) end)
swayimg.viewer.on_mouse("ScrollUp", function() step(0, 5) end)
swayimg.viewer.on_mouse("ScrollDown", function() step(0, -5) end)
swayimg.viewer.on_mouse("Ctrl+ScrollUp", function() swayimg.viewer.scale = swayimg.viewer.scale * 1.1 end)
swayimg.viewer.on_mouse("Ctrl+ScrollDown", function() swayimg.viewer.scale = swayimg.viewer.scale / 1.1 end)
swayimg.viewer.on_mouse("Shift+ScrollUp", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_mouse("Shift+ScrollDown", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_mouse("Alt+ScrollUp", function()
  local frame = swayimg.viewer.frame
  if frame > 0 then swayimg.viewer.frame = frame - 1 end
end)
swayimg.viewer.on_mouse("Alt+ScrollDown", function() swayimg.viewer.frame = swayimg.viewer.frame + 1 end)

--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.thumb_size = 200
swayimg.gallery.aspect = "fill"
swayimg.gallery.cache = 100
swayimg.gallery.pstore = false
swayimg.gallery.window_color = 0xaa000000     -- old gallery.window=#000000AA
swayimg.gallery.unselected_color = 0xff202020 -- old gallery.background
swayimg.gallery.selected_color = 0xff404040   -- old gallery.select
swayimg.gallery.border_color = 0xff000000     -- old gallery.border
-- NOTE: old gallery.shadow has no equivalent field in 5.5.

swayimg.gallery.set_text("bottomright", { "{name}" })

swayimg.gallery.on_key("Home", function() swayimg.gallery.select("first") end)
swayimg.gallery.on_key("End", function() swayimg.gallery.select("last") end)
swayimg.gallery.on_key("h", function() swayimg.gallery.select("left") end)
swayimg.gallery.on_key("l", function() swayimg.gallery.select("right") end)
swayimg.gallery.on_key("k", function() swayimg.gallery.select("up") end)
swayimg.gallery.on_key("j", function() swayimg.gallery.select("down") end)
swayimg.gallery.on_key("Left", function() swayimg.gallery.select("left") end)
swayimg.gallery.on_key("Right", function() swayimg.gallery.select("right") end)
swayimg.gallery.on_key("Up", function() swayimg.gallery.select("up") end)
swayimg.gallery.on_key("Down", function() swayimg.gallery.select("down") end)
swayimg.gallery.on_key("Prior", function() swayimg.gallery.select("pgup") end)
swayimg.gallery.on_key("Next", function() swayimg.gallery.select("pgdown") end)

swayimg.gallery.on_key("c", function()
  local img = swayimg.gallery.get_image()
  if img then swayimg.imagelist.remove(img.path) end
end)

swayimg.gallery.on_key("f", function() swayimg.fullscreen = not swayimg.fullscreen end)
swayimg.gallery.on_key("Return", function() swayimg.mode = "viewer" end)
swayimg.gallery.on_key("a", function() swayimg.antialiasing = not swayimg.antialiasing end)
swayimg.gallery.on_key("r", function() swayimg.gallery.reload() end)
swayimg.gallery.on_key("i", function() swayimg.text.visible = not swayimg.text.visible end)

swayimg.gallery.on_key("Shift+Delete", function()
  local img = swayimg.gallery.get_image()
  if img then
    os.remove(img.path)
    swayimg.text.status = "File removed: " .. img.path
    swayimg.imagelist.remove(img.path)
  end
end)

swayimg.gallery.on_key("Escape", function() swayimg.exit() end)
swayimg.gallery.on_key("q", function() swayimg.exit() end)

swayimg.gallery.on_mouse("ScrollLeft", function() swayimg.gallery.select("left") end)
swayimg.gallery.on_mouse("ScrollRight", function() swayimg.gallery.select("right") end)
swayimg.gallery.on_mouse("ScrollUp", function() swayimg.gallery.select("up") end)
swayimg.gallery.on_mouse("ScrollDown", function() swayimg.gallery.select("down") end)
