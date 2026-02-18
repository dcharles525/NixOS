{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override {  }).customize{
      name = "vim";
      # Install plugins for example for syntax highlighting of nix files
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ nerdtree vim-go vim-nix vim-lastplace vim-airline gruvbox ale editorconfig-vim
          vim-indent-guides copilot-vim
          (pkgs.vimUtils.buildVimPlugin {
            name = "vim-ai";
            src = pkgs.fetchFromGitHub {
              owner = "madox2";
              repo = "vim-ai";
              rev = "master";
              #nix-prefetch url https://github.com/madox2/vim-ai/archive/master.tar.gz
              sha256 = "sha256-V8aoxXpSInemyaITKw4kySwd2Ke+BSIbCpSewev3ox8";

            };
          })
        ];
        opt = [];
      };
      vimrcConfig.customRC = ''
        syntax on
        let g:indent_guides_enable_on_vim_startup = 1
        filetype plugin indent on
        inoremap <Esc> <Esc>:w<CR>
        set backspace=indent,eol,start
        set tabstop=2 shiftwidth=2 expandtab
        set autoindent
        set smartindent
        set t_Co=256
        colorscheme gruvbox
        set number
        set cursorline
        set colorcolumn=80
        set background=dark
        set noundofile
        set swapfile
        set cursorline
        set clipboard+=unnamedplus
        set dir=~/.vim/tmp//

        let g:ale_linters = {
          \'javascript': ['eslint'],
          \'python': ['flake8', 'pylint'],
          \'typescript': ['eslint'],
        \}

        packloadall
        silent! helptags ALL
        au filetype go inoremap <buffer> . .<C-x><C-o>
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

