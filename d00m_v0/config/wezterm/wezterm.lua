local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.unix_domains = { { name = 'unix' } }
config.default_gui_startup_args = { 'connect', 'unix' }

local is_wayland = os.getenv('WAYLAND_DISPLAY') ~= nil or
                   os.getenv('XDG_SESSION_TYPE') == 'wayland'
config.enable_wayland = is_wayland
config.front_end = 'OpenGL'
config.webgpu_power_preference = 'HighPerformance'
config.prefer_egl = true

config.automatically_reload_config = true

local colors_file = wezterm.home_dir .. '/.config/matugen/generated/wezterm-colors.lua'
local ok, matugen_colors = pcall(dofile, colors_file)
if ok and type(matugen_colors) == 'table' then
    config.colors = matugen_colors
else
    config.color_scheme = 'Tomorrow Night (Gogh)'
end

config.max_fps = 240
config.animation_fps = 240

config.font = wezterm.font_with_fallback { 'CaskaydiaCove NF SemiBold', 'JetBrains Mono NL SemiBold' }
config.font_size = 17
config.line_height = 1.1

config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.85
config.window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0
}

config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true

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
    { key = 'y', mods = 'LEADER', action = act.EmitEvent("copy-prompt-input") },
    { key = 'd', mods = 'LEADER', action = act.SendString('\x05\x15') },
    { key = 'q', mods = 'ALT', action = act.CloseCurrentPane{confirm=false} },
    { key = '\\', mods = 'ALT', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    { key = '-', mods = 'ALT', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
    { key = 'LeftArrow', mods = 'ALT', action = act.AdjustPaneSize{ 'Left', 5 } },
    { key = 'DownArrow', mods = 'ALT', action = act.AdjustPaneSize{ 'Down', 5 } },
    { key = 'UpArrow', mods = 'ALT', action = act.AdjustPaneSize{ 'Up', 5 } },
    { key = 'RightArrow', mods = 'ALT', action = act.AdjustPaneSize{ 'Right', 5 } },
}

config.key_tables = {
  copy_mode = {
      { key = 'Tab', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'Tab', mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'MoveToStartOfNextLine' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'Space', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = '$', mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
      { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
      { key = 'F', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 'F', mods = 'SHIFT', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'G', mods = 'SHIFT', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'H', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
      { key = 'L', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportBottom' },
      { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'M', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      { key = 'O', mods = 'SHIFT', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = 'T', mods = 'SHIFT', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = 'V', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Line' } },
      { key = 'V', mods = 'SHIFT', action = act.CopyMode{ SetSelectionMode =  'Line' } },
      { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = '^', mods = 'SHIFT', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'b', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
      { key = 'c', mods = 'CTRL', action = act.CopyMode 'Close' },
      { key = 'd', mods = 'CTRL', action = act.CopyMode{ MoveByPage = (0.5) } },
      { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },
      { key = 'f', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = false } } },
      { key = 'f', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
      { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
      { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
      { key = 'g', mods = 'CTRL', action = act.CopyMode 'Close' },
      { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'm', mods = 'ALT', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
      { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 't', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = true } } },
      { key = 'u', mods = 'CTRL', action = act.CopyMode{ MoveByPage = (-0.5) } },
      { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = 'v', mods = 'CTRL', action = act.CopyMode{ SetSelectionMode =  'Block' } },
      { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'y', mods = 'NONE', action = act.Multiple{ { CopyTo =  'ClipboardAndPrimarySelection' }, { CopyMode =  'Close' } } },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
      { key = 'End', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = 'Home', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'RightArrow', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      {
        key = 'Space',
        mods = 'CTRL|SHIFT',
        action = act.Multiple {
          -- Go back to the previous Output zone start
          act.CopyMode { MoveBackwardZoneOfType = "Output" },
          -- Select that whole Output zone
          act.CopyMode { SetSelectionMode = "SemanticZone" },
        },
      },
    },

    search_mode = {
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
      { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
      { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
      { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
    },
}

wezterm.on('copy-prompt-input', function(window, pane)
    window:perform_action(
        act.Multiple {
            act.ActivateCopyMode,
            act.CopyMode 'MoveToScrollbackBottom',
            act.CopyMode { SetSelectionMode = 'SemanticZone' },
            act.Multiple {
                { CopyTo = 'ClipboardAndPrimarySelection' },
                { CopyMode = 'Close' },
            },
        },
        pane
    )
end)

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
