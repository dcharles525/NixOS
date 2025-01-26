{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override {  }).customize{
      name = "vim";
      # Install plugins for example for syntax highlighting of nix files
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-lastplace vim-airline gruvbox ale ];
        opt = [];
      };
      vimrcConfig.customRC = ''
        syntax on
        filetype plugin indent on
        inoremap <Esc> <Esc>:w<CR>
        set tabstop=2 shiftwidth=2 expandtab
        set autoindent 
        set smartindent
        set t_Co=256
        colorscheme gruvbox
        set number
        set colorcolumn=80
        set background=dark
        set noundofile
        set swapfile
        set dir=~/.vim/tmp//
        silent autocmd CursorHold * :call gitblame#echo()
        set cmdheight=2

        let g:ale_linters = {
          \'javascript': ['eslint'],
        \}

        packloadall
        silent! helptags ALL
      '';
    }
  )];
}
