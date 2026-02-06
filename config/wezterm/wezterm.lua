local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.automatically_reload_config = true

config.max_fps = 240
config.animation_fps = 240

config.font = wezterm.font_with_fallback { 'CaskaydiaCove NF SemiBold', 'JetBrains Mono NL SemiBold' }
config.font_size = 17
config.line_height = 1.2

config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'RESIZE'
config.window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0
}

config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true

local colors = {

}

local act = wezterm.action

config.disable_default_key_bindings = true
config.leader = { key = ',', mods = 'ALT', timeout_miliseconds = 1500 }
config.keys = {
    { key = '`', mods = 'CTRL', action = act.ActivateLastTab },
    { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab{confirm=false} },
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = '+', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
    { key = '_', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
    { key = ')', mods = 'SHIFT|CTRL', action = act.ResetFontSize },
    { key = 'T', mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'C', mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },
    { key = 'V', mods = 'SHIFT|CTRL', action = act.PasteFrom 'Clipboard' },
    { key = 'X', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    { key = 'P', mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
    { key = '0', mods = 'CTRL', action = act.ActivateTab(0) },
    { key = '1', mods = 'CTRL', action = act.ActivateTab(1) },
    { key = '2', mods = 'CTRL', action = act.ActivateTab(2) },
    { key = '3', mods = 'CTRL', action = act.ActivateTab(3) },
    { key = '4', mods = 'CTRL', action = act.ActivateTab(4) },
    { key = '5', mods = 'CTRL', action = act.ActivateTab(5) },
    { key = '6', mods = 'CTRL', action = act.ActivateTab(6) },
    { key = '7', mods = 'CTRL', action = act.ActivateTab(7) },
    { key = '8', mods = 'CTRL', action = act.ActivateTab(8) },
    { key = '9', mods = 'CTRL', action = act.ActivateTab(9) },
    { key = 't', mods = 'LEADER', action = act.EmitEvent("toggle-tabbar") },
}

wezterm.on('toggle-tabbar', function(window, pane)
  local overrides = window:get_config_overrides() or {}

  local tabs_enabled = overrides.show_tabs_in_tab_bar ~= false

  if tabs_enabled then
    -- Disable tab bar completely
    overrides.show_tabs_in_tab_bar = false
    overrides.show_new_tab_button_in_tab_bar = false
    overrides.hide_tab_bar_if_only_one_tab = true
  else
    -- Restore tab bar
    overrides.show_tabs_in_tab_bar = true
    overrides.show_new_tab_button_in_tab_bar = true
    overrides.hide_tab_bar_if_only_one_tab = false
  end

  window:set_config_overrides(overrides)
end)

wezterm.on("update-status", function(window, _)
    local prefix = ""
    local leader_prefix = '💀 '

    if window:leader_is_active() then
        prefix = " " .. leader_prefix
    end

    window:set_left_status(wezterm.format {
        { Text = prefix }
    })
end)

return config
