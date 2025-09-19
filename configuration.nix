{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
    efi.canTouchEfiVariables = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 20d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "NixOS_PC";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Tomsk";

  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  services.xserver.xkb = {
    layout = "ru";
    variant = "";
  };

  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "astronaut-theme";
  };
  services.displayManager.defaultSession = "hyprland";
  programs.hyprland.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    wireplumber.extraConfig."50-bluez-config" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-msbc" = true;
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.codecs" = [ "sbc" "aac" "ldac" ];
        "bluez5.ldac-quality" = "high";
      };
    };
  };

  hardware.graphics.enable = true;
  
  # Это пример настроек пользователя | this is example for user settigns:
  # users.users.<юзер | username> = {
  #   isNormalUser = true;
  #   description = "<ник | nikname>";
  #   extraGroups = [ "networkmanager" "wheel" ];
  #   packages = with pkgs; [];
  # };

  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    iosevka-bin
    nerd-fonts._3270
    nerd-fonts.mononoki
  ];
  fonts.fontconfig.enable = true;

  services.dbus.enable = true;
  services.tumbler.enable = true;
  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  services.gvfs.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;

  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ dconf gnome2.GConf gcr libnotify glib gtk3 ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyACM*", ATTRS{idVendor}=="346e", ACTION=="add", MODE="0666", TAG+="uaccess"
    SUBSYSTEM=="misc", KERNEL=="uinput", OPTIONS+="static_node=uinput", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="346e", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="input", ATTRS{idVendor}=="346e", MODE="0666", GROUP="input"
  '';

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    # GUI
    anilibria-winmaclinux
    anydesk
    avalonia-ilspy
    blueman
    bottles
    boxflat
    eww
    evince
    file-roller
    gnome-calculator
    hyprland
    hyprlock
    hyprpaper
    inkscape
    kitty
    krita
    kdePackages.kdenlive
    libreoffice-qt6-fresh
    mpv
    mpvpaper
    jetbrains.pycharm-community-src
    obs-studio
    pavucontrol
    prismlauncher
    pdfarranger
    rofi-wayland
    rose-pine-hyprcursor
    shotwell
    solaar
    steam
    swaybg
    telegram-desktop
    (sddm-astronaut.override { embeddedTheme = "pixel_sakura"; })
    vscodium

    # Console
    btop
    browsh
    cava
    cliphist
    coreutils-full
    dbus
    fastfetch
    fish
    ffmpeg
    git
    glib
    glibc
    gobject-introspection
    grim
    helix
    jq
    kew
    ldacbt
    libnotify
    lsd
    micro
    neofetch
    pamixer
    p7zip
    playerctl
    (python312.withPackages (ps: with ps; [
      dbus-python
      pygobject3
      jedi-language-server
    ]))
    ranger
    slurp
    unzip
    vlc
    wget
    wireguard-tools
    wl-clipboard
    yazi
    zip
    zoom-us

    # AMD Card (Drivers)
    amdvlk
    libdrm
    libGL
    libpulseaudio
    libva
    libvdpau
    mesa
    mesa-demos
    vulkan-loader
    vulkan-validation-layers
    virtualgl
    virtualglLib
    wayland

    # Thunar
    ffmpegthumbnailer
    libgsf
    poppler
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.tumbler

    # GTK
    gnome-themes-extra
    gtk3
    (papirus-icon-theme.override { color = "yaru"; })
    gruvbox-gtk-theme
    kanagawa-gtk-theme
    rose-pine-cursor

    # Unity3D
    unityhub
    libsecret
    seahorse
  ];

  environment.sessionVariables = {
    GTK_THEME = "Kanagawa-B";
    ICON_THEME = "Papirus-Dark";
    QT_STYLE_OVERRIDE = "gtk4";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
  };
    
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    glibc
    gobject-introspection
    (python312.withPackages (ps: with ps; [
      dbus-python
      pygobject3
      jedi-language-server
    ]))
    dbus
  ];

  programs.hyprland = {
    xwayland.enable = true;
  };

  programs.steam.enable = true;
  programs.steam.package = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [ libdrm wayland ];
  };

  system.stateVersion = "25.05";
}
