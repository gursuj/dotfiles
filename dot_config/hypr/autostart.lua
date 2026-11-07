-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Nightlight schedule lives in ~/.config/hypr/hyprsunset.conf (warm 4000K from
-- 17:30, identity from 07:00). hyprsunset has to be running for the timed
-- profiles to fire, so it is launched with the session.
o.launch_on_start("hyprsunset")
