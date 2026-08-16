{ ... }:
{
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    PS1='\n\[\e[1;32m\][\W]\$\[\e[0m\] '
  '';
}
