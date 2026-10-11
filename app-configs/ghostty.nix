{ ... }:
let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ./mgx.nix).dark;
in
{
  programs.ghostty.enable = true;
  programs.ghostty = {
    settings = {
      background = mgx.bg;
      foreground = mgx.ink;
      cursor-color = mgx.ink;
      cursor-text = mgx.bg;
      selection-background = mgx.ink;
      selection-foreground = mgx.bg;
      # 0-7 normal, 8-15 bright. One ink, so bright repeats the hue.
      palette = [
        "0=#${mgx.bgRaised}"
        "1=#${mgx.alert}"
        "2=#${mgx.ok}"
        "3=#${mgx.warn}"
        "4=#${mgx.info}"
        "5=#${mgx.cat3}"
        "6=#${mgx.cat2}"
        "7=#${mgx.inkDim}"
        "8=#${mgx.inkFaint}"
        "9=#${mgx.alert}"
        "10=#${mgx.ok}"
        "11=#${mgx.warn}"
        "12=#${mgx.info}"
        "13=#${mgx.cat3}"
        "14=#${mgx.cat2}"
        "15=#${mgx.ink}"
      ];
      background-opacity = "0.95";
    };
  };
}
