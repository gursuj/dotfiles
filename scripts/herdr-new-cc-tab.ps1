# Opens a new herdr tab in the current workspace and runs `cc -n` in it.
# Bound to prefix+n in herdr config.toml (see [[keys.command]]).
# herdr's CLI has no "create tab and run command" action in one step, so this
# does it in four calls: find the focused pane's workspace, create a tab in
# it, explicitly focus that tab (tab create's own --focus flag sets the
# model's focus field but doesn't switch the live client's view - tab focus
# does), then send the command to the new tab's root pane.

$paneList = herdr pane list | ConvertFrom-Json
$focused = $paneList.result.panes | Where-Object { $_.focused }
if (-not $focused) {
    Write-Warning "herdr-new-cc-tab: no focused pane found."
    exit 1
}

$tab = herdr tab create --workspace $focused.workspace_id --label "cc" | ConvertFrom-Json
$tabId = $tab.result.tab.tab_id
$rootPaneId = $tab.result.root_pane.pane_id

herdr tab focus $tabId
herdr pane run $rootPaneId "cc -n"
