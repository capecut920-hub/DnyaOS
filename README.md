# DnyaOS

DnyaOS is a lightweight Debian Live customization with XFCE, a dark blue/cyan desktop theme, red accents, ladybug branding, a dock, media controls, useful desktop apps, and a birthday greeting app.

**This repository contains the build source, not a prebuilt ISO.** A real ISO will be available only after the GitHub Actions build succeeds.

## Build the ISO on GitHub
1. Open the **Actions** tab.
2. Select **Build DnyaOS ISO**.
3. Click **Run workflow** and run it on the `main` branch.
4. When the run finishes successfully, open the run and download the `DnyaOS-live-amd64` artifact. It contains the ISO and its SHA-256 checksum.
5. Test the ISO in a virtual machine before writing it to a USB.

The workflow builds a Debian 13 (Trixie) live image with XFCE. It does not write to or format any USB or internal disk.

## Desktop experience
- XFCE with a dark DnyaOS theme and custom ladybug wallpaper/branding.
- Plank dock for a cleaner, centered app launcher.
- Picom compositor for window shadows and supported transparency effects.
- VLC and Playerctl for local music playback and media-key/control integration where supported.
- Firefox ESR launchers for WhatsApp Web and Snapchat Web.

The concept artwork is a design target; exact widget placement and visual effects depend on the installed desktop components and hardware. The build must be tested before claiming every effect works on the target PC.

## Birthday app
- Click **DnyaOS Birthday Edition** in the application menu or desktop.
- Use `dnyaos-birthday --preview` to preview it at any time.
- The greeting is date-locked to 26 October when launched without `--preview`.

## Local build
On Debian 13 or a compatible Debian-family system with internet access and at least 25–35 GB free space:
```bash
sudo bash ./build-dnyaos.sh
```
The output is placed in `out/`.
