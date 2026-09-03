{ specialArgs, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = pkgs.hyprland.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./hyprland-session-lock-null-guard.patch ];
    });
    # Raw Lua config. home-manager passes extraConfig through verbatim to
    # ~/.config/hypr/hyprland.lua when configType = "lua" — see the source at
    # modules/services/window-managers/hyprland/lib.nix (renderSection
    # "extraConfig" ...). All variables ($mainMod, $terminal, ...) are Lua
    # locals; hyprlang sections become nested tables passed to hl.config().
    #
    # Translation notes for future edits:
    #   - bind        → hl.bind("MOD + KEY", dispatcher, opts?)
    #   - bindl       → { locked = true }
    #   - bindel      → { locked = true, repeating = true }
    #   - bindm       → { mouse = true }
    #   - workspace N → hl.dsp.focus({ workspace = tostring(N) })
    #   - movetoworkspace N → hl.dsp.window.move({ workspace = tostring(N) })
    #   - movefocus DIR     → hl.dsp.focus({ direction = "left"|"right"|"up"|"down" })
    #   - killactive        → hl.dsp.window.close()
    #   - togglefloating    → hl.dsp.window.float({ action = "toggle" })
    #   - pseudo            → hl.dsp.window.pseudo()
    #   - exit              → hl.dsp.exit()
    #   - exec              → hl.dsp.exec_cmd("...")
    #   - moveactive X Y    → no direct dispatcher exposed in hl.dsp yet;
    #                         fallback via hyprctl subprocess (slight latency).
    #   - workspace pin     → hl.workspace_rule({ workspace, monitor, default? })
    #   - exec-once         → hl.on("hyprland.start", function() hl.exec_cmd(...) end)
    extraConfig = ''
      -- MONITORS
      ${if specialArgs.host == "desktop" then ''
        hl.monitor({ output = "DP-1",    mode = "2560x1440@60", position = "0x0",    scale = 1 })
        hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "2560x0", scale = 1, transform = 3 })
      '' else if specialArgs.host == "ktop" then ''
        hl.monitor({ output = "eDP-1",    mode = "preferred",     position = "0x0",      scale = 1 })
        hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "-2560x0",  scale = 1 })
        hl.monitor({ output = "DP-1",     mode = "3840x2160@144", position = "-4720x0",  scale = 1, transform = 1 })
        hl.monitor({ output = "",         mode = "preferred",     position = "auto",     scale = 1 })

        -- Only eDP-1 is guaranteed to exist; pinning default = true to a
        -- monitor that may be absent at resume has triggered Hyprland
        -- std::system_error aborts on suspend/resume topology changes.
        hl.workspace_rule({ workspace = "1", monitor = "eDP-1",   default = true })
        hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
        hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
        hl.workspace_rule({ workspace = "4", monitor = "eDP-1" })
        hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })
        hl.workspace_rule({ workspace = "6", monitor = "DP-1" })
        hl.workspace_rule({ workspace = "7", monitor = "eDP-1" })
        hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1" })
        hl.workspace_rule({ workspace = "9", monitor = "DP-1" })
      '' else ''
        hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
      ''}

      -- PROGRAMS
      local terminal    = "ghostty"
      local fileManager = "dolphin"
      local menu        = "wofi --show drun"

      -- AUTOSTART
      hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
      end)

      -- ENVIRONMENT
      hl.env("XCURSOR_THEME", "Whiteglass")
      hl.env("XCURSOR_SIZE",  "24")

      -- LOOK AND FEEL
      hl.config({
        cursor = {
          enable_hyprcursor = false,
        },
        general = {
          gaps_in     = 5,
          gaps_out    = 10,
          border_size = 2,
          col = {
            active_border   = "rgba(FFD865ee)",
            inactive_border = "rgba(595959aa)",
          },
          resize_on_border = false,
          allow_tearing    = false,
          layout           = "dwindle",
        },
        decoration = {
          rounding         = 5,
          active_opacity   = 1.0,
          inactive_opacity = 1.0,
          shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
          },
          blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
          },
        },
        animations = {
          enabled = true,
        },
        dwindle = {
          preserve_split = true,
        },
        master = {
          new_status = "master",
        },
        misc = {
          force_default_wallpaper = -1,
          disable_hyprland_logo   = true,
        },
        input = {
          kb_layout  = "us",
          kb_variant = "",
          kb_model   = "",
          kb_options = "",
          kb_rules   = "",
          follow_mouse = 1,
          sensitivity  = 0,
          touchpad = {
            natural_scroll = true,
          },
        },
      })

      -- ANIMATION CURVES
      hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
      hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
      hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
      hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
      hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

      -- ANIMATIONS
      hl.animation({ leaf = "global",        enabled = true, speed = 10,    bezier = "default" })
      hl.animation({ leaf = "border",        enabled = true, speed = 5.39,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "windows",       enabled = true, speed = 4.79,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,   bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49,  bezier = "linear",       style = "popin 87%" })
      hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73,  bezier = "almostLinear" })
      hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46,  bezier = "almostLinear" })
      hl.animation({ leaf = "fade",          enabled = true, speed = 3.03,  bezier = "quick" })
      hl.animation({ leaf = "layers",        enabled = true, speed = 3.81,  bezier = "easeOutQuint" })
      hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,     bezier = "easeOutQuint", style = "fade" })
      hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,   bezier = "linear",       style = "fade" })
      hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79,  bezier = "almostLinear" })
      hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39,  bezier = "almostLinear" })
      hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94,  bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21,  bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94,  bezier = "almostLinear", style = "fade" })

      -- DEVICE
      hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

      -- KEYBINDS
      local mainMod = "SUPER"

      -- Screenshots (hyprshot)
      hl.bind(mainMod .. " + PRINT",         hl.dsp.exec_cmd("hyprshot -m window"))
      hl.bind("PRINT",                       hl.dsp.exec_cmd("hyprshot -m output"))
      hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

      -- Core actions
      hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + C", hl.dsp.window.close())
      hl.bind(mainMod .. " + M", hl.dsp.exit())
      hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
      hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
      hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("systemctl --user start hyprlock"))
      hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("iwmenu -l rofi"))

      -- Move focus
      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Workspace switch / move (0 → workspace 10)
      for i = 1, 10 do
        local key = tostring(i % 10)
        hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = tostring(i) }))
        hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = tostring(i) }))
      end

      -- Move active window by pixels — hyprctl fallback (no direct dispatcher yet)
      hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprctl dispatch moveactive 30 0"))
      hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("hyprctl dispatch moveactive -30 0"))
      hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl dispatch moveactive 0 -30"))
      hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd("hyprctl dispatch moveactive 0 30"))

      -- Rofi + special workspace
      hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd("rofi -show drun -show-icons"))
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      -- Workspace scroll
      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

      -- Mouse drag / resize
      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Media / volume / brightness (locked + repeating)
      hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
      hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
      hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

      hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
      hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

      -- WINDOW RULES
      hl.window_rule({
        name           = "suppress-maximize-events",
        match          = { class = ".*" },
        suppress_event = "maximize",
      })

      hl.window_rule({
        name  = "no-focus-empty-xwayland",
        match = { class = "^$", title = "^$", xwayland = true, fullscreen = false },
        no_focus = true,
      })
    '';
  };
}
