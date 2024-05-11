#!/bin/bash
TITLE="Package setup"
DIALOG_OUTPUT="/tmp/dialog_output.txt"
trap 'rm $DIALOG_OUTPUT; exit' SIGHUP SIGINT SIGTERM

IS_DEBIAN=$([[ $(cat /etc/issue) == "Debian"* ]])
IS_ARCH=$([[ $(cat /etc/issue) == "Arch"* ]])
IS_DARWIN=$([[ $(sw_vers) == *"macOS"* ]])

PROG_LANGUAGES=(go lua python rust)
GO_VERSION=go1.21.linux-amd64

PIP_GLOBAL_PKGS=(iwlib pipenv pipx pyenv)
PIP_USER_PKGS=(ranger)

if $IS_DEBIAN; then
  ESSENTIAL_PKGS=(docker fzf git neovim ripgrep rsync vim zsh)
  TERMINAL_PKGS=(bat htop nethogs tmux)
  DEV_PKGS=(gcc gdb lazygit mysql-client nmap parallel redis)
  OTHER_PKGS=(ntfy proxychains-ng tor)
  [[ $(command -v dialog) ]] || sudo apt-get --yes install dialog
elif $IS_ARCH; then
  DESKTOP_PKGS=(alacritty feh firefox notification-daemon picom qtile rofi)
  ESSENTIAL_PKGS=(docker fzf git neovim nerd-fonts-fira-mono ripgrep rsync vim wireless_tools zsh)
  TERMINAL_PKGS=(bat htop nethogs lf tmux)
  DEV_PKGS=(gcc gdb jq lazygit mysql nmap parallel redis)
  OTHER_PKGS=(ntfysh-bin proxychains-ng tor)
  AUR_PKGS=(nerd-fonts-fira-mono ntfysh-bin lazygit lf)
  [[ $(command -v dialog) ]] || sudo pacman -S --noconfirm dialog
elif $IS_DARWIN; then
  DESKTOP_PKGS=(firefox)
  ESSENTIAL_PKGS=(docker font-fira-mono-nerd-font fzf git neovim ripgrep)
  TERMINAL_PKGS=(bat htop nethogs tmux)
  DEV_PKGS=(gcc gdb jq lazygit mysql-client nmap parallel redis)
  OTHER_PKGS=(ntfy)
  [[ $(command -v brew) ]] || NONINTERACTIVE=1 sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ $(command -v dialog) ]] || brew install dialog
else
  echo "Invalid OS detected"
  exit 1
fi

declare -A selected_packages
selected_packages["essential"]=${ESSENTIAL_PKGS[*]}
selected_packages["terminal"]=${TERMINAL_PKGS[*]}

prompt_packages() {
  category=$1
  shift
  for p in "$@"; do
    pkgs+="($p $([[ ${selected_packages[$category]} == *"$p"* ]] && echo "on" || echo "off"))"
  done
  dialog --no-items --no-lines --title "$TITLE" --no-cancel --checklist "Select packages:" 0 0 0 ${pkgs[@]} 2>$DIALOG_OUTPUT
}


MENU=(
  1 "Essential"
  2 "Terminal"
  3 "Programming"
  4 "Other"
)
if $IS_ARCH || $IS_DARWIN; then MENU=(${MENU[@]} 5 "Desktop packages"); fi

while : ; do
  dialog --no-lines --title "$TITLE" --menu "Categories" 0 0 0 "${MENU[@]}" 9 "Proceed to installation" 2>$DIALOG_OUTPUT
  if $?; then clear;break; fi
  case $(<$DIALOG_OUTPUT) in
    1)
      prompt_packages "essential" ${ESSENTIAL_PKGS[@]}
      selected_packages["essential"]=$(<$DIALOG_OUTPUT)
      shift ;;
    2)
      prompt_packages "terminal" ${TERMINAL_PKGS[@]}
      selected_packages["terminal"]=$(<$DIALOG_OUTPUT)
      shift ;;
    3)
      while : ; do
        dialog --no-lines --title "$TITLE" --cancel-label "Back" --menu "Categories" 0 0 0 1 "Packages" 2 "Languages" 2>$DIALOG_OUTPUT
        if $?; then break; fi
        case $(<$DIALOG_OUTPUT) in
          1)
            prompt_packages "dev" ${DEV_PKGS[@]}
            selected_packages["dev"]=$(<$DIALOG_OUTPUT)
            shift ;;
          2)
            prompt_packages "languages" ${PROG_LANGUAGES[@]}
            selected_packages["languages"]=$(<$DIALOG_OUTPUT)
            shift ;;
        esac
      done
      shift ;;
    4)
      prompt_packages "other" ${OTHER_PKGS[@]}
      selected_packages["other"]=$(<$DIALOG_OUTPUT)
      shift ;;
    5)
      prompt_packages "desktop" ${DESKTOP_PKGS[@]}
      selected_packages["desktop"]=$(<$DIALOG_OUTPUT)
      shift ;;
    9)
      clear

      for arg in ${selected_packages["languages"]}; do
        case $arg in
          go)
            [[ $(command -v go) ]] || {
              curl -O https://dl.google.com/go/$GO_VERSION.tar.gz
              rm -rf /usr/local/share/go && tar -C /usr/local/share -xzf $GO_VERSION.tar.gz
            }
            shift ;;
          lua)
            curl -L -R -O https://www.lua.org/ftp/lua-5.4.6.tar.gz && tar zxf lua-5.4.6.tar.gz && cd lua-5.4.6 && make all test
            shift ;;
          python)
            [[ $(command -v python3) ]] || sudo apt-get --yes install python3
            [[ $(command -v pip3) ]] || sudo apt-get --yes install python3-pip
            prompt_packages "pip_global" ${PIP_GLOBAL_PKGS[@]}
            selected_packages["pip_global"]=$(<$DIALOG_OUTPUT)
            prompt_packages "pip_user" ${PIP_USER_PKGS[@]}
            selected_packages["pip_user"]=$(<$DIALOG_OUTPUT)
            clear
            (( ${#selected_packages["pip_global"]} )) && pip3 install ${selected_packages["pip_global"]}
            (( ${#selected_packages["pip_user"]} )) && pip3 install --user ${selected_packages["pip_user"]}
            shift ;;
          rust)
            [[ $(command -v rustup) ]] || (curl https://sh.rustup.rs -sSf | sh && rustup toolchain install stable --profile=default && rustup default stable)
            shift ;;
        esac
      done

      unset "selected_packages['languages']"
      unset "selected_packages['pip_global']"
      unset "selected_packages['pip_user']"

      if $IS_DEBIAN; then
        mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts && curl -fLo "Ubuntu Mono Nerd Font Complete.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/UbuntuMono/Regular/complete/Ubuntu%20Mono%20Nerd%20Font%20Complete.ttf ;cd
        (( ${#selected_packages[@]} )) && sudo apt-get --yes install ${selected_packages[@]}
      elif $IS_ARCH; then
        for p in ${selected_packages[@]}; do
          [[ ${AUR_PKGS[*]} == *"$p"* ]] && aur+=($p) || pac+=($p)
        done

        (( ${#pac[@]} )) && sudo pacman -S --noconfirm ${pac[@]}

        dialog --no-lines --title "$TITLE" --yesno "Install yay?" 0 0
        use_aur=$?; clear
        if $use_aur; then
          if ! [[ ${selected_packages[*]} == *"git"* ]] && ! [[ $(command -v git) ]]; then
            dialog --no-lines --title "$TITLE" --yesno "Yay needs 'git' to be installed but it couldn't be found in your packages. Install git?" 0 0
            $? || selected_packages["essential"]+=" git"
            clear
          fi
        fi

        $use_aur && {
          [[ $(command -v fakeroot) ]] || sudo pacman -S --noconfirm base-devel #wsl distrod distros don't have base-devel installed
          git clone https://aur.archlinux.org/yay-git.git && cd yay-git && makepkg -si --noconfirm && cd && sudo rm -r yay-git && yay -Y --gendb && yay -Syu --devel
          (( ${#aur[@]} )) && yay -S --noconfirm ${aur[@]}
        }
      elif $IS_DARWIN; then
        (( ${#selected_packages[@]} )) && sudo brew install ${selected_packages[@]}
      fi
      break
      shift ;;
  esac
done
rm $DIALOG_OUTPUT

if [[ $(command -v zsh) ]]; then
  dialog --no-lines --title "$TITLE" --yesno "Change default shell and install dotfiles?" 0 0

  ! $? && {
    clear
    chsh -s /usr/bin/zsh
    export DOTBARE_DIR=$HOME/.config/.dotbare
    export DOTBARE_TREE=$HOME
    export ZDOTDIR=$HOME/.config/zsh
    git clone https://github.com/kazhala/dotbare.git ~/.dotbare && .dotbare/dotbare finit -u https://github.com/joanofstuff/dotfiles.git && sudo rm -r .dotbare
    rm .bash* install.sh
  }

  clear
  echo -e "\e[1;32minstallation completed :)\033[0m"
fi
