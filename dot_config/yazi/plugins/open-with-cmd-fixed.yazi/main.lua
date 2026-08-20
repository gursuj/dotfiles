-- Local fork of Ape/open-with-cmd.yazi.
-- Upstream appended " %*" (windows) / ' "$@"' (unix), but neither is a real
-- yazi placeholder any more -- Yazi 26 moved to its own %s/%h-style
-- substitution and stopped forwarding selected files as raw shell
-- positional args. On Windows, %* just isn't a cmd.exe token outside a
-- .bat script either, so it reached nvim literally as a filename. On unix,
-- "$@" now silently expands to nothing. Matches upstream's fix in
-- https://github.com/Ape/open-with-cmd.yazi/issues/10 -- %s works on both
-- platforms, no branch needed.
-- Not managed by `ya pkg` -- edit here, not via plugin update.
return {
	entry = function(_, job)
		local block = job.args[1] and job.args[1] == "block"

		local value, event = ya.input({
			title = block and "Open with (block):" or "Open with:",
			pos = { "hovered", y = 1, w = 50 },
		})

		if event == 1 then
			ya.emit("shell", {
				value .. " %s",
				block = block,
				orphan = not block,
			})
		end
	end,
}
