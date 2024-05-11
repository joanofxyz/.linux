# dotfiles

## Installing from the script:

### Inside the installation environment:

```bash
loadkeys pt-latin1 # the '-' is the apostrophe key in pt keyboards
pacman-key --init && pacman-key --populate archlinux && pacman -Sy && pacman -S archinstall
archinstall --config https://raw.githubusercontent.com/joanofstuff/linux/main/.config/archinstall/user_configuration.json --disk_layouts https://raw.githubusercontent.com/joanofstuff/linux/main/.config/archinstall/user_disk_layout.json
# You only need to configure the root password and the user credentials
```

### After rebooting and logging in with the user account:

```bash
curl -O https://raw.githubusercontent.com/joanofstuff/linux/main/.config/archinstall/install.sh && chmod +x install.sh && ./install.sh
```
