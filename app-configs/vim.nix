{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override {  }).customize{
      name = "vim";
      # Install plugins for example for syntax highlighting of nix files
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ YouCompleteMe vim-nix vim-lastplace vim-airline gruvbox ale
          (pkgs.vimUtils.buildVimPlugin {
            name = "vim-ai";
            src = pkgs.fetchFromGitHub {
              owner = "madox2";
              repo = "vim-ai";
              rev = "master";
              #nix-prefetch url https://github.com/madox2/vim-ai/archive/master.tar.gz
              sha256 = "sha256-ywnBM2YBysrs5EF0lpxKH0cYXJZvFgL+F9f+kCuiFJ8=";

            };
          })
        ];
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
        set cmdheight=2

        let g:ale_linters = {
          \'javascript': ['eslint'],
        \}

        packloadall
        silent! helptags ALL
        let g:vim_ai_token_file_path = '~/.config/openai.token'

        let g:vim_ai_chat = {
          \  "options": {
          \    "model": "gpt-3.5-turbo",
          \    "stream": 0,
          \    "temperature": 1,
          \    "max_completion_tokens": 2048,
          \    "initial_prompt": "Hello, as my AI assistant I would like you to be like Jarvis from ironman. Whitty, smart, and concise. I am a programmer so most things I ask will be centered around that but I also like philosphy, consumer tech, and food." 
          \  },
        \}
      '';
    }
  )];
}
