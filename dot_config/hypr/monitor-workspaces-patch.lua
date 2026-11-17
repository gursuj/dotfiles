-- Keep a workspace's slot number when its monitor is unplugged.
--
-- Omarchy's monitor-workspaces.lua renumbers an unplugged monitor's workspaces
-- into the block of the monitor they landed on, appended after its highest one
-- (ws 12 on HDMI becomes 4 on the panel). Here "workspace 2" is a slot (see
-- bindings.lua), so ws 12 should become 2 when that is free, and only append
-- when it is taken. Replug still sends it back (merged state is untouched).
--
-- The file is package-owned, so it is patched as text at load time rather than
-- forked: Omarchy updates keep flowing in. If the text no longer matches
-- (upstream changed merge()), the stock file loads unchanged and a warning
-- goes to stderr -- re-check this patch then.
--
-- Must be required before default.hypr.omarchy, which requires the module.

local MODULE = "default.hypr.monitor-workspaces"
local path = (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/monitor-workspaces.lua"

local FROM = "local id = append_slot(by_connector[workspace.monitor.name])"
local TO = [[local id = (function(block)
        local wanted = block * SLOTS + (old - 1) % SLOTS + 1
        if not hl.get_workspace(wanted) then
          return wanted
        end
        return append_slot(block)
      end)(by_connector[workspace.monitor.name])]]

package.preload[MODULE] = function(name)
  local file = assert(io.open(path, "r"))
  local source = file:read("*a")
  file:close()

  local start, stop = source:find(FROM, 1, true)
  if start then
    source = source:sub(1, start - 1) .. TO .. source:sub(stop + 1)
  else
    io.stderr:write("monitor-workspaces-patch: merge() text changed upstream, running stock file\n")
  end

  return assert(load(source, "@" .. path))(name)
end
