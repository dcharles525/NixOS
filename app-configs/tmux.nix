{ ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g status-position bottom
      
      set -g status-left-length 30
      set -g status-right-length 60
      set -g status-right "#(free -h | awk '/Mem:/ {print $3\"/\"$2}') | #(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf \"%.0f%%\", usage}') | %H:%M %d-%b "

      set -g status on
      set -g status-left 'Session: #S | Window: #I | '

      set-hook -g session-created 'split-window -h ; select-pane -L ; split-window -v ; select-pane -R'
    '';
  };
}
