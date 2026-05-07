# waybar-modules
A repository of C programs I use for custom waybar modules.

The font used for icons is `ttf-material-design-icons` from the AUR. You can easily patch the source files if you have a different font/icon you wish to use.

## Installation

### Arch Linux
AUR releases are signed so you'll need to import my GPG key:

`<srht@krathalan.net> B46B 3262 73E4 A1D2 1AAA 3F6F 529A C100 50BD 24EF`

Then install the modules with my PKGBUILD:

```
$ git clone https://git.sr.ht/~krathalan/pkgbuilds
$ cd pkgbuilds/krathalans-waybar-modules/
$ nano --view PKGBUILD # Always inspect PKGBUILDS before running makepkg!
$ makepkg -i
```

### Other distros
You can simply build with `make release` in the module directory of your choosing. AppArmor profiles are provided in the `apparmor-profiles/` folder.

## battery
![example battery module](https://i.imgur.com/jovIrkU.jpg)

A battery module that displays the current power draw in watts. Displays an additional charging icon when charging. Does not display current power draw in watts when charging.

The program will return, as json data to Waybar, the percentage of the battery. This allows changing the icon based on the battery percentage in your Waybar config.

The program will also return the current state of the battery (charging/discharging), in lowercase. This allows changing the theme based on battery states in your waybar.css.

Here's two example outputs from the program:

```
{"text": "4W ", "class": "discharging", "percentage": 86}
{"text": "", "class": "charging", "percentage": 86}
```

Here's an example module in my Waybar config:

```
  "custom/battery": {
    "interval": 8,
    "tooltip": false,
    "format": "{percentage}% {}{icon}",
    "format-icons": ["", "", "", "", "", "", ""],
    "return-type": "json",
    "exec": "$HOME/path/to/binary/battery"
  },
```

Here's some example Waybar css for this battery module:

```
#custom-battery {
    padding: 0 5px;
    margin: 0 4px;
    background-color: transparent;
    border-bottom: 2px solid #bff874;
    color: #ffffff;
}

#custom-battery.charging {
  border-bottom: 2px solid #00ff96;
}
```

## vpn
![example vpn module](https://i.imgur.com/Zb1Jw1a.jpg)

This program takes the name of a VPN interface, like "mullvad-us3", and returns json data containing information on the state of the VPN connection. This information can be used to change the theme based on the state of your VPN connection in your waybar.css.

Here's an example module in my Waybar config:

```
"custom/vpn": {
  "interval": 5,
  "tooltip": false,
  "format": "{}",
  "return-type": "json",
  "exec": "$HOME/path/to/binary/vpn mullvad-us5"
},
```

Here's some example Waybar css for this VPN module:

```
#custom-vpn {
    padding: 0 5px;
    margin: 0 4px;
    background-color: transparent;
    border-bottom: 2px solid #00ff96;
    color: #ffffff;
}

#custom-vpn.down {
  border-bottom: 2px solid #dd2241;
}
```

