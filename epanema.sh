#!/bin/bash

# EPANEMA.SH

# This Bash script allows you to easily and safely download, install or update Enlightenment 0.23
# (aka E23) on Ubuntu Eoan Ermine; or helps you perform a clean uninstall of E23.

# To execute the script:

# First time.
# 1. Open Terminal and uncheck "Limit scrollback to" in Preferences > Profile Name > Scrolling
# 2. Change (cd) to the download folder
# 3. Make this script executable with chmod +x
# 4. Then type ./epanema.sh

# Subsequent runs.
# Open Terminal and simply type epanema.sh

# Heads up!
# Enlightenment programs installed from .deb packages or tarballs will inevitably conflict with
# E23 programs compiled from Git repositories——do not mix source code with pre-built binaries!
# Please remove thoroughly any previous installation of EFL/Enlightenment/E-Apps (track down
# and delete any leftover files) before running EPANEMA.SH.

# Once installed, you can update your shiny new Enlightenment desktop whenever you want to.
# However, because software gains entropy over time (performance regression, unexpected
# behavior... this is especially true when dealing with source code), I highly recommend
# doing a complete uninstall and reinstall of E23 every two weeks or so for an optimal
# user experience.

# NOTE that you need to uninstall all E23 programs *before* upgrading your current system
# to a newer version of Ubuntu.

# EPANEMA.SH is written by similar@orange.fr, feel free to use this script as you see fit.
# Before reporting an issue, make sure you are using the latest version.

# Please consider sending me a tip via https://www.paypal.me/PJGuillaumie
# or starring the repository to show your support.
# Cheers!

# Repositories and gists: https://github.com/batden
# Eyecandy for your Enlightenment desktop: https://extra.enlightenment.org/

# LOCAL VARIABLES
# ---------------

BLD="\e[1m"    # Bold text.
ITA="\e[3m"    # Italic text.
BDR="\e[1;31m" # Bold red text.
BDG="\e[1;32m" # Bold green text.
BDY="\e[1;33m" # Bold yellow text.
OFF="\e[0m"    # Turn off ANSI colors and formatting.

PREFIX=/usr/local
DLDIR=$(xdg-user-dir DOWNLOAD)
DOCDIR=$(xdg-user-dir DOCUMENTS)
ICNV=libiconv-1.16
SCRFLR=$HOME/.epanema
CONFG="./configure --prefix=$PREFIX"
SNIN="sudo ninja -C build install"
RELEASE=$(lsb_release -sc)

# Build dependencies, recommended(2) and script-related(3) packages.
DEPS="aspell automake build-essential ccache check cmake cowsay doxygen \
faenza-icon-theme git gstreamer1.0-libav gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly imagemagick \
libasound2-dev libavahi-client-dev libblkid-dev libbluetooth-dev \
libbullet-dev libcogl-gles2-dev libexif-dev libfontconfig1-dev \
libfreetype6-dev libfribidi-dev libgeoclue-2-dev libgif-dev \
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libharfbuzz-dev \
libibus-1.0-dev libinput-dev libjpeg-dev libluajit-5.1-dev liblz4-dev \
libmount-dev libopenjp2-7-dev libosmesa6-dev libpam0g-dev \
libpoppler-cpp-dev libpoppler-dev libpoppler-private-dev \
libpulse-dev libraw-dev librsvg2-dev libscim-dev libsndfile1-dev \
libspectre-dev libssl-dev libsystemd-dev libtiff5-dev libtool \
libudev-dev libudisks2-dev libunibreak-dev libunwind-dev \
libuv1-dev libvlc-dev libwebp-dev libxcb-keysyms1-dev libxcursor-dev \
libxine2-dev libxinerama-dev libxkbcommon-x11-dev libxkbfile-dev \
libxrandr-dev libxss-dev libxtst-dev linux-tools-common lolcat \
manpages-dev meson ninja-build texlive-base valgrind wayland-protocols \
wmctrl xserver-xephyr xwayland zenity"

# (2) aspell, cmake, faenza-icon-theme, gstreamer1.0-libav,
# gstreamer1.0-plugins-bad, gstreamer1.0-plugins-good,
# gstreamer1.0-plugins-ugly, imagemagick, libexif-dev,
# libgeoclue-2-dev, libscim-dev, libosmesa6-dev,
# linux-tools-common, libvlc-dev, libxine2-dev,
# manpages-dev, texlive-base, valgrind, xserver-xephyr.
# (3) ccache, cowsay, git, lolcat, wmctrl, zenity.

# Programs from GIT repositories (latest source code).
CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
CLONE23="git clone https://git.enlightenment.org/core/enlightenment.git"
PROG_MN="efl enlightenment terminology"

# FUNCTIONS
# ---------

zen_warn() {
  zenity --no-wrap --info --text "
  This installation will take up about 1.5 GB of space.\n
  Keep in mind that running other applications\n\
  during the build process will affect\n\
  compilation time.\n"
}

beep_attention() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
}

beep_question() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
}

beep_exit() {
  paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
}

beep_ok() {
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

sel_menu() {
  if [ $INPUT -lt 1 ]; then
    echo
    printf "1. $BDG%s $OFF%s\n\n" " Install Enlightenment 23 from the master branch"
    printf "2. $BDG%s $OFF%s\n\n" " Update and rebuild Enlightenment 23"
    printf "3. $BDY%s $OFF%s\n\n" " Update and rebuild E23 with Wayland support"
    printf "4. $BDR%s $OFF%s\n\n" " Uninstall all Enlightenment 23 programs"

    # Hints.
    # 1/2: A feature-rich, decently optimized build; however, occasionally technical glitches do happen...
    # 3: Running Enlightenment as a Wayland compositor is still considered experimental.
    # 4: Nuke 'Em All!

    sleep 1 && printf "$ITA%s $OFF%s\n\n" "Or press Ctrl+C to quit."
    read INPUT
  fi
}

bin_deps() {
  sudo apt update && sudo apt full-upgrade

  # Backup list of currently installed packages (with a few exceptions).
  if [ ! -f $DOCDIR/installed_pkgs.txt ]; then
    apt-cache dumpavail >/tmp/apt-avail
    sudo dpkg --merge-avail /tmp/apt-avail
    rm /tmp/apt-avail
    dpkg --get-selections >$DOCDIR/installed_pkgs.txt
    sed -i '/linux-generic*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-headers*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-image*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-modules*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-image*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-signed*/d' $DOCDIR/installed_pkgs.txt
    sed -i '/linux-tools*/d' $DOCDIR/installed_pkgs.txt
  fi

  # Backup list of currently installed repositories.
  if [ ! -f $DOCDIR/installed_repos.txt ]; then
    grep -Erh ^deb /etc/apt/sources.list* >$DOCDIR/installed_repos.txt
  fi

  sudo apt install $DEPS
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .DEB PACKAGES"
    printf "$BDR%s %s\n" "OR DPKG DATABASE IS LOCKED."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi
}

ls_dir() {
  COUNT=$(ls -d */ | wc -l)
  if [ $COUNT == 3 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
  elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s %s\n" "WARNING: ONLY $COUNT OF 3 PROGRAMS HAVE BEEN DOWNLOADED!"
    printf "\n$BDY%s $OFF%s\n\n" "WAIT 12 SECONDS OR HIT CTRL+C TO QUIT."
    sleep 12
  fi
}

mng_err() {
  printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
  beep_exit
  exit 1
}

chk_path() {
  if ! echo $PATH | grep -q $HOME/.local/bin; then
    echo -e '    export PATH=$HOME/.local/bin:$PATH' >>$HOME/.bash_aliases
    source $HOME/.bash_aliases
  fi
}

elap_start() {
  START=$(date +%s)
}

elap_stop() {
  DELTA=$(($(date +%s) - $START))
  printf "\n%s" "Compilation time: "
  printf ""%dh:%dm:%ds"\n\n" $(($DELTA / 3600)) $(($DELTA % 3600 / 60)) $(($DELTA % 60))
}

e_bkp() {
  # Timestamp: See man date to convert epoch to human readable date.
  TSTAMP=$(date +%s)
  mkdir -p $DOCDIR/ebackups

  mkdir $DOCDIR/ebackups/E_$TSTAMP
  cp -aR $HOME/.elementary $DOCDIR/ebackups/E_$TSTAMP && cp -aR $HOME/.e $DOCDIR/ebackups/E_$TSTAMP

  if [ -d $HOME/.config/terminology ]; then
    cp -aR $HOME/.config/terminology $DOCDIR/ebackups/Eterm_$TSTAMP
  fi

  sleep 2
}

e_tokens() {
  echo $(date +%s) >>$HOME/.cache/ebuilds/etokens

  TOKEN=$(wc -l <$HOME/.cache/ebuilds/etokens)
  if [ "$TOKEN" -gt 3 ]; then
    echo
    # Questions: Enter either y or n, or press Enter to accept the default values.
    beep_question
    read -t 12 -p "Do you want to back up your E23 settings now? [y/N] " answer
    case $answer in
      [yY])
        e_bkp
        ;;
      [nN])
        printf "\n%s\n\n" "(do not back up my user settings and themes folders... OK)"
        ;;
      *)
        printf "\n%s\n\n" "(do not back up my user settings and themes folders... OK)"
        ;;
    esac
  fi
}

build_optim() {
  chk_path

  sudo ln -sf /usr/lib/x86_64-linux-gnu/preloadable_libintl.so /usr/lib/libgnuintl.so.8
  sudo ln -sf /usr/lib/x86_64-linux-gnu/preloadable_libintl.so /usr/lib/libintl.so
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/enlightenment23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    case $I in
      efl)
        meson . build
        meson configure -Dnative-arch-optimization=true -Dharfbuzz=true -Dbindings=luajit,cxx -Dbuild-tests=false \
          -Dbuild-examples=false -Devas-loaders-disabler= -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      enlightenment)
        meson . build
        meson configure -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      *)
        meson . build
        meson configure -Dbuildtype=release build
        ninja -C build || true
        ;;
    esac

    beep_attention
    $SNIN || true
    sudo ldconfig
  done
}

rebuild_optim() {
  e_tokens
  elap_start

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  git pull
  sudo chown $USER build/.ninja*
  meson configure -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  elap_stop

  for I in $PROG_MN; do
    elap_start

    cd $ESRC/enlightenment23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
      efl)
        sudo chown $USER build/.ninja*
        meson configure -Dnative-arch-optimization=true -Dharfbuzz=true -Dbindings=luajit,cxx -Dbuild-tests=false \
          -Dbuild-examples=false -Devas-loaders-disabler= -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      enlightenment)
        sudo chown $USER build/.ninja*
        meson configure -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      *)
        sudo chown $USER build/.ninja*
        meson configure -Dbuildtype=release build
        ninja -C build || true
        ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

rebuild_wld() {
  e_tokens
  elap_start

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  git pull
  sudo chown $USER build/.ninja*
  meson configure -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  elap_stop

  for I in $PROG_MN; do
    elap_start

    cd $ESRC/enlightenment23/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
      efl)
        sudo chown $USER build/.ninja*
        meson configure -Dnative-arch-optimization=true -Dharfbuzz=true -Dbindings=luajit,cxx -Ddrm=true -Dwl=true \
          -Dopengl=es-egl -Dbuild-tests=false -Dbuild-examples=false -Devas-loaders-disabler= -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      enlightenment)
        sudo chown $USER build/.ninja*
        meson configure -Dwl=true -Dbuildtype=release build
        ninja -C build || mng_err
        ;;
      *)
        sudo chown $USER build/.ninja*
        meson configure -Dbuildtype=release build
        ninja -C build || true
        ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

do_tests() {
  if [ -x /usr/bin/wmctrl ]; then
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi
  fi

  printf "\n\n$BLD%s $OFF%s\n" "System check..."

  if systemd-detect-virt -q --container; then
    printf "\n$BDR%s %s\n" "EPANEMA.SH IS NOT INTENDED FOR USE INSIDE CONTAINERS."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi

  if [ $RELEASE == eoan ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Ubuntu ${RELEASE^}... OK"
    sleep 2
  else
    printf "\n$BDR%s $OFF%s\n\n" "UNSUPPORTED OPERATING SYSTEM [ $(lsb_release -d | cut -f2) ]."
    beep_exit
    exit 1
  fi

  # Users of VirtualBox: Comment out the following lines if you get unexpected network errors.
  git ls-remote https://git.enlightenment.org/core/efl.git HEAD &>/dev/null
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" "OR CHECK YOUR INTERNET CONNECTION."
    beep_exit
    exit 1
  fi

  if [ ! -d $SCRFLR ]; then
    printf "\n$BDR%s $OFF%s\n\n" "EPANEMA FOLDER NOT FOUND!"
    beep_exit
    exit 1
  fi

  if [ ! -d $HOME/.local/bin ]; then
    mkdir -p $HOME/.local/bin
  fi

  if [ ! -d $HOME/.cache/ebuilds ]; then
    mkdir -p $HOME/.cache/ebuilds
  fi
}

do_bsh_alias() {
  if [ ! -f $HOME/.bash_aliases ]; then
    touch $HOME/.bash_aliases

    cat >$HOME/.bash_aliases <<EOF

    # GLOBAL VARIABLES
    # ----------------

    # Compiler and linker flags.
    export CC="ccache gcc"
    export CXX="ccache g++"
    export USE_CCACHE=1
    export CPPFLAGS=-I/usr/local/include
    export LDFLAGS=-L/usr/local/lib
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

    # This script adds the ~/.local/bin directory to your PATH environment variable if required.
EOF

    source $HOME/.bash_aliases
  fi
}

set_p_src() {
  echo
  beep_attention
  # Do not append a trailing slash (/) to the end of the path prefix.
  read -p "Enter a path to the Enlightenment source folders (e.g. /home/lucas or /home/lucas/testing): " mypath
  mkdir -p "$mypath"/sources
  ESRC="$mypath"/sources
  echo $ESRC >$HOME/.cache/ebuilds/storepath
  printf "\n%s\n\n" "You have chosen: $ESRC"
  sleep 1
}

get_preq() {
  cd $DLDIR
  printf "\n\n$BLD%s $OFF%s\n\n" "Installing prerequisites..."
  wget -c https://ftp.gnu.org/pub/gnu/libiconv/$ICNV.tar.gz
  tar xzvf $ICNV.tar.gz -C $ESRC
  cd $ESRC/$ICNV
  $CONFG
  make
  sudo make install
  sudo ldconfig
  rm -rf $DLDIR/$ICNV.tar.gz
  echo

  cd $ESRC
  git clone https://github.com/Samsung/rlottie.git
  cd $ESRC/rlottie
  meson . build
  meson configure -Dexample=false -Dbuildtype=release build
  ninja -C build || mng_err
  $SNIN || mng_err
  sudo ldconfig
  echo
}

install_now() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* INSTALLING ENLIGHTENMENT DESKTOP: RELEASE BUILD *"
  beep_attention
  zen_warn 2>/dev/null
  do_bsh_alias
  bin_deps
  set_p_src
  get_preq

  cd $HOME
  mkdir -p $ESRC/enlightenment23
  cd $ESRC/enlightenment23

  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching source code from the Enlightened git repositories..."
  $CLONEFL
  echo
  $CLONETY
  echo
  $CLONE23
  echo

  ls_dir

  build_optim

  printf "\n%s\n\n" "Almost done..."

  mkdir -p $HOME/.elementary/themes

  sudo mv -f /usr/local/etc/enlightenment/sysactions.conf /etc

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  printf "\n\n$BDY%s %s" "Initial setup wizard tips:"
  printf "\n$BDY%s %s" "'Update checking' —— you can disable this feature because it serves no useful purpose."
  printf "\n$BDY%s $OFF%s\n\n\n" "'Network management support' —— Connman is not needed."
  # Enlightenment adds three shortcut icons (namely home.desktop, root.desktop and tmp.desktop)
  # to your Ubuntu Desktop, you can safely delete them.

  echo
  cowsay "Now reboot your computer then select Enlightenment on the login screen... \
  That's All Folks!" | lolcat -a
  echo
  # If you cannot login to Enlightenment using gdm3 (nothing happens when you click on it), try this workaround:
  # edit /etc/gdm3/custom.conf and uncomment the line "#WaylandEnable=false"
  # Then reboot your system.

  cp -f $DLDIR/epanema.sh $HOME/.local/bin
}

update_go() {
  clear
  if [ ! -d $ESRC/enlightenment23 ]; then
    printf "\n$BDR%s %s\n" "NOTHING TO UPDATE!"
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDG%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: RELEASE BUILD *"
  fi

  cp -f $SCRFLR/epanema.sh $HOME/.local/bin
  chmod +x $HOME/.local/bin/epanema.sh
  sleep 1

  printf "\n$BLD%s $OFF%s\n\n" "Satisfying dependencies under Ubuntu ${RELEASE^}..."
  bin_deps

  rebuild_optim

  sudo mv -f /usr/local/etc/enlightenment/sysactions.conf /etc

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok
  echo
  cowsay -f www "That's All Folks!"
  echo
}

wld_go() {
  clear
  if [ ! -d $ESRC/enlightenment23 ]; then
    printf "\n$BDR%s %s\n" "NOTHING TO UPDATE!"
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: WAYLAND BUILD *"
  fi

  cp -f $SCRFLR/epanema.sh $HOME/.local/bin
  chmod +x $HOME/.local/bin/epanema.sh
  sleep 1

  printf "\n$BLD%s $OFF%s\n\n" "Satisfying dependencies under Ubuntu ${RELEASE^}..."
  bin_deps

  rebuild_wld

  sudo mv -f /usr/local/etc/enlightenment/sysactions.conf /etc

  cd /usr/share && sudo rm -rf xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  if [ "$XDG_SESSION_TYPE" == "x11" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo
    cowsay -f www "Now log out of your existing session and press Ctrl+Alt+F3 to switch to tty3, \
        then enter your credentials and type: enlightenment_start" | lolcat -a
    echo
    # Wait a few seconds for the Wayland session to start.
    # When you're done, type exit
    # Pressing Ctrl+Alt+F1 will bring you back to the login screen.
  else
    echo
    cowsay -f www "That's it. Now type: enlightenment_start"
    echo
  fi
}

remov_eprog_mn() {
  for I in $PROG_MN; do
    sudo ninja -C build uninstall
    rm -rf build &>/dev/null
  done
}

remov_preq() {
  if [ -d $ESRC/$ICNV ]; then
    echo
    beep_question
    read -t 12 -p "Remove libiconv and rlottie? [Y/n] " answer
    case $answer in
      [yY])
        echo
        cd $ESRC/$ICNV
        sudo make uninstall
        make maintainer-clean
        cd .. && rm -rf $ESRC/$ICNV
        sudo rm -rf /usr/local/bin/iconv
        echo

        cd $ESRC/rlottie
        sudo ninja -C build uninstall
        cd .. && rm -rf rlottie
        echo
        ;;
      [nN])
        printf "\n%s\n\n" "(do not remove prerequisites... OK)"
        ;;
      *)
        echo
        cd $ESRC/$ICNV
        sudo make uninstall
        make maintainer-clean
        cd .. && rm -rf $ESRC/$ICNV
        sudo rm -rf /usr/local/bin/iconv
        echo

        cd $ESRC/rlottie
        sudo ninja -C build uninstall
        cd .. && rm -rf rlottie
        echo
        ;;
    esac
  fi
}

# Think twice before proceeding with the removal of these packages!
# If in doubt, take a screenshot for later reference, or better yet,
# keep the currently installed set of development packages.
remov_bin_deps() {
  echo
  beep_question
  read -t 12 -p "Remove binary dependencies (development packages)? [y/N] " answer
  case $answer in
    [yY])
      printf "\n%s\n\n" "Please read the APT report carefully before pressing y to continue with the uninstall."
      sleep 4
      sudo apt autoremove $DEPS
      echo
      ;;
    [nN])
      printf "\n%s\n\n" "(keep the currently installed set of dev packages... OK)"
      ;;
    *)
      printf "\n%s\n\n" "(keep the currently installed set of dev packages... OK)"
      ;;
  esac
}

uninstall_e23() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)

  clear
  printf "\n\n$BDR%s %s\n\n" "* UNINSTALLING ENLIGHTENMENT DESKTOP *"

  cd $HOME

  for I in $PROG_MN; do
    cd $ESRC/enlightenment23/$I && remov_eprog_mn
  done

  cd /etc
  sudo rm -rf sysactions.conf

  cd /usr/local
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf efl*
  sudo rm -rf eio*
  sudo rm -rf eldbus*
  sudo rm -rf elementary*
  sudo rm -rf eo*
  sudo rm -rf evas*

  cd /usr/local/bin
  sudo rm -rf eina*
  sudo rm -rf efl*
  sudo rm -rf elua*
  sudo rm -rf eolian*
  sudo rm -rf emotion*
  sudo rm -rf evas*

  cd /usr/local/etc
  sudo rm -rf enlightenment

  cd /usr/local/include
  sudo rm -rf *-1
  sudo rm -rf enlightenment

  cd /usr/local/lib
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf x86*
  sudo rm -rf libecore*
  sudo rm -rf libector*
  sudo rm -rf libedje*
  sudo rm -rf libeet*
  sudo rm -rf libeeze*
  sudo rm -rf libefl*
  sudo rm -rf libefreet*
  sudo rm -rf libeina*
  sudo rm -rf libeio*
  sudo rm -rf libeldbus*
  sudo rm -rf libelementary*
  sudo rm -rf libelocation*
  sudo rm -rf libelput*
  sudo rm -rf libelua*
  sudo rm -rf libembryo*
  sudo rm -rf libemile*
  sudo rm -rf libemotion*
  sudo rm -rf libeo*
  sudo rm -rf libeolian*
  sudo rm -rf libephysics*
  sudo rm -rf libethumb*
  sudo rm -rf libevas*

  cd /usr/local/share
  sudo rm -rf dbus*
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf elua*
  sudo rm -rf embryo*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf terminology*
  sudo rm -rf wayland-sessions*

  cd /usr/local/share/applications
  sudo sed -i '/enlightenment_filemanager/d' mimeinfo.cache

  cd /usr/local/share/icons
  sudo rm -rf Enlightenment-X
  sudo rm -rf elementary*
  sudo rm -rf terminology*

  cd /usr/share
  sudo rm -rf xsessions/enlightenment.desktop &>/dev/null
  cd /usr/share/dbus-1/services
  sudo rm -rf org.enlightenment.Ethumb.service

  cd $HOME
  rm -rf $ESRC/enlightenment23
  rm -rf $SCRFLR
  rm -rf .e
  rm -rf .elementary
  rm -rf .cache/efreet
  rm -rf .cache/evas_gl_common_caches
  rm -rf .config/terminology

  find /usr/local/share/locale/*/LC_MESSAGES 2>/dev/null | while read -r I; do
    echo "$I" | xargs sudo rm -rf $(grep -E 'efl|enlightenment|terminology')
  done

  if [ -d $HOME/.ccache ]; then
    echo
    beep_question
    read -t 12 -p "Remove the hidden ccache folder (compiler cache)? [y/N] " answer
    case $answer in
      [yY])
        rm -rf $HOME/.ccache
        ;;
      [nN])
        printf "\n%s\n\n" "(do not delete the ccache folder... OK)"
        ;;
      *)
        printf "\n%s\n\n" "(do not delete the ccache folder... OK)"
        ;;
    esac
  fi

  if [ -f $HOME/.bash_aliases ]; then
    echo
    beep_question
    read -t 12 -p "Remove the hidden bash_aliases file? [Y/n] " answer
    case $answer in
      [yY])
        rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
        ;;
      [nN])
        printf "\n%s\n\n" "(do not delete bash_aliases... OK)"
        ;;
      *)
        rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
        ;;
    esac
  fi

  remov_preq
  remov_bin_deps

  rm -rf $HOME/.cache/ebuilds
  mv $DOCDIR/installed_pkgs.txt $DOCDIR/inst_pkgs_bak.txt
  mv $DOCDIR/installed_repos.txt $DOCDIR/inst_repos_bak.txt

  sudo rm -rf /usr/lib/libgnuintl.so.8
  sudo rm -rf /usr/lib/libintl.so
  sudo ldconfig
  sudo updatedb
  echo
}

main() {
  trap '{ printf "\n$BDR%s $OFF%s\n\n" "KEYBOARD INTERRUPT."; exit 130; }' INT

  INPUT=0
  printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"
  sel_menu

  if [ $INPUT == 1 ]; then
    do_tests
    install_now
  elif [ $INPUT == 2 ]; then
    do_tests
    update_go
  elif [ $INPUT == 3 ]; then
    do_tests
    wld_go
  elif [ $INPUT == 4 ]; then
    uninstall_e23
  else
    beep_exit
    exit 1
  fi
}

main
