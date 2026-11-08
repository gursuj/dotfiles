/* Colours are gated on the mode this theme is built for. Omarchy renders this
 * file again on every theme switch, but a system light/dark flip without one
 * used to leave the old palette pinned over Firefox's chrome -- with the gate,
 * a flip in the other direction falls back to Firefox's own palette instead of
 * showing the wrong one. Layout (the collapsed tab strip) applies either way.
 */
@media (prefers-color-scheme: {{ mode }}) {
/* Firefox chrome in the Omarchy theme.
 *
 * Rendered by `omarchy-theme-refresh` (and every theme switch) from
 * ~/.config/omarchy/themed/firefox-userChrome.css.tpl into
 * ~/.local/state/omarchy/current/theme/firefox-userChrome.css, which the
 * profile's chrome/userChrome.css symlinks to -- edit the tracked .tpl in the
 * dotfiles repo, not either generated copy.
 *
 * Colours come from the theme's colors.toml. `browser.theme.native-theme` is
 * off in user.js, otherwise GTK repaints the chrome on top of this.
 */
:root {
  --toolbar-bgcolor: {{ background }} !important;
  --toolbar-color: {{ foreground }} !important;
  --toolbar-field-background-color: {{ dark_background }} !important;
  --toolbar-field-color: {{ foreground }} !important;
  --toolbar-field-border-color: {{ muted }} !important;
  --toolbar-field-focus-background-color: {{ darker_background }} !important;
  --toolbar-field-focus-color: {{ bright_foreground }} !important;

  --lwt-accent-color: {{ background }} !important;
  --lwt-text-color: {{ foreground }} !important;
  --lwt-toolbar-field-background-color: {{ dark_background }} !important;
  --lwt-toolbar-field-color: {{ foreground }} !important;
  --lwt-toolbar-field-border-color: {{ muted }} !important;

  --tab-selected-bgcolor: {{ background }} !important;
  --tab-selected-textcolor: {{ foreground }} !important;

  --arrowpanel-background: {{ dark_background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: {{ muted }} !important;

  --sidebar-background-color: {{ background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --sidebar-border-color: {{ muted }} !important;

  --button-hover-bgcolor: {{ lighter_background }} !important;
  --button-active-bgcolor: {{ selection }} !important;
  --urlbar-box-bgcolor: {{ dark_background }} !important;
  --urlbar-box-text-color: {{ foreground }} !important;
  --urlbar-box-hover-bgcolor: {{ lighter_background }} !important;
  --focus-outline-color: {{ accent }} !important;
}


#navigator-toolbox {
  background-color: {{ background }} !important;
  border-bottom: 1px solid {{ muted }} !important;
  appearance: none !important;
}

#nav-bar {
  background-color: {{ background }} !important;
  box-shadow: none !important;
  border-top: none !important;
}

.titlebar-button > .toolbarbutton-icon {
  color: {{ foreground }} !important;
}

#urlbar,
#searchbar {
  border-radius: 6px !important;
}

#urlbar[focused="true"] > #urlbar-background {
  outline: 1px solid {{ accent }} !important;
  outline-offset: -1px !important;
}

/* Bookmarks bar is hidden by pref; if it is ever shown, keep it in theme. */
#PersonalToolbar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

#sidebar-box,
#sidebar-header {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

#sidebar-header {
  border-bottom: 1px solid {{ muted }} !important;
}

findbar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  border-top: 1px solid {{ muted }} !important;
}

/* Panels (menu, extensions, downloads) read as part of the same surface. */
panelview,
.panel-subview-body {
  background-color: {{ dark_background }} !important;
  color: {{ foreground }} !important;
}

/* Scrollbars, so long panels and the sidebar don't fall back to stock grey. */
* {
  scrollbar-color: {{ muted }} {{ background }};
}
}

/* Layout, not colour: the tab strip stays collapsed in both modes -- Sideberry
 * puts the tab list in the sidebar, so the top strip was a second tab UI.
 * `visibility: collapse` (rather than `display: none`) keeps the window
 * controls where the window manager expects them. */
#TabsToolbar {
  visibility: collapse !important;
}
