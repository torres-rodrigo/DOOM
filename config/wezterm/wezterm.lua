local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.max_fps = 240
config.animation_fps = 240

config.font = wezterm.font_with_fallback { 'CaskaydiaCove NF SemiBold', 'JetBrains Mono NL SemiBold' }
config.font_size = 15.5

config.window_decorations = 'RESIZE'

config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true

local tab_style = 'square'
local leader_prefix = '💀'

local colors = {

}

config.leader = { key = ',', mods = 'ALT', timeout_miliseconds = 1500 }


return config
