{ ... }:
{
  programs.ghostty.enable = true;
  programs.ghostty = {
    settings = {
      theme = "GruvboxDark";
      background-opacity = "0.95";
    };
  };
}
