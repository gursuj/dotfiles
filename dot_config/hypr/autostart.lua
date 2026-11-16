-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Nightlight schedule lives in ~/.config/hypr/hyprsunset.conf (warm 4000K from
-- 17:30, identity from 07:00). hyprsunset has to be running for the timed
-- profiles to fire, so it is launched with the session.
o.launch_on_start("hyprsunset")

-- GTD app, autostarted on the IdeaPad too.
o.launch_on_start("mindwtr")

-- Disable HDMI while locked: BenQ hotplug loop (omarchy #13812). See learnings.md.
o.launch_on_start("omarchy-hdmi-lockguard")

-- Break reminder. Config lives in dconf (org.gnome.desktop.break-reminders),
-- not a tracked file: movement 30 min / 3 min break, eyesight 30 min / 20 s.
o.launch_on_start("sane-break")
