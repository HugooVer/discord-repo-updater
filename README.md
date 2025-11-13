# Discord-repo-updater

Keep Discord (.deb) up to date like any other APT package — no PPAs, no manual downloads.

* A tiny Docker job refreshes a local APT repo with the latest official Discord `.deb`.
* Your system then treats Discord as a **regular package** (`apt update && apt upgrade`).
* Runs **'daily'** via `apt-daily`, plus **on-demand** when you ask.



## Why

* Discord sometimes **requires** the latest version to run. This project makes those upgrades appear in your usual APT updates.
* Avoids unofficial PPAs — you self host a local repo. The `.deb` comes directly from **`discord.com`**.


## Requirements

* Linux system using `APT` and `systemd` (Debian/Ubuntu or derivatives)
* `Docker` (`docker --version`)
* `sudo` access.



## Setup / Install

1. **Create your local directory** :

```bash
sudo mkdir -p /var/local/discord-repo
sudo chown root:root /var/local/discord-repo
```

2. **Build the Docker image**:

```bash
cd discord-repo-updater
docker build -t discord-repo-updater .
```

3. **Install the systemd service** :

```bash
sudo tee /etc/systemd/system/discord-repo-update.service >/dev/null <<'EOF'
[Unit]
Description=Update local Discord APT repo via Docker
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --rm -v /var/local/discord-repo:/repo discord-repo-updater
EOF

sudo systemctl daemon-reload
```
4. **Prime the repo once** :
```bash
sudo systemctl start discord-repo-update.service
```
5. **Register the local APT source** :

```bash
echo "deb [trusted=yes] file:/var/local/discord-repo ./" | sudo tee /etc/apt/sources.list.d/discord-local.list
sudo apt update
```

6. **Hook a drop-in into apt-daily.service** :

```bash
sudo mkdir -p /etc/systemd/system/apt-daily.service.d

sudo tee /etc/systemd/system/apt-daily.service.d/discord-repo-update.conf >/dev/null <<'EOF'
[Service]
ExecStartPost=/usr/bin/systemctl start discord-repo-update.service
EOF

sudo systemctl daemon-reload
systemctl status apt-daily.timer    # check that apt-daily.timer is active
# If disabled: sudo systemctl enable --now apt-daily.timer
```


## Everyday Use

### Install or Upgrade Discord

Use your normal APT flow:

```bash
sudo apt update
sudo apt install discord
# or
sudo apt upgrade
```

### Force a refresh (on-demand)

If you want the very latest *before* the apt-daily job runs, start the updater once:

```bash
sudo systemctl start discord-repo-update.service
```

Optional convenience alias :

```bash
echo "alias discord-update='sudo systemctl start discord-repo-update.service'" >> ~/.bashrc && source ~/.bashrc
# zsh:
echo "alias discord-update='sudo systemctl start discord-repo-update.service'" >> ~/.zshrc && source ~/.zshrc
```
```bash
discord-update && sudo apt update && sudo apt upgrade
```

## Uninstall

Remove the local APT source and systemd drop-in. Your OS behaves as before.

```bash
sudo rm /etc/apt/sources.list.d/discord-local.list
sudo rm -r /etc/systemd/system/apt-daily.service.d
sudo rm /etc/systemd/system/discord-repo-update.service
sudo rm -r /var/local/discord-repo
docker rmi discord-repo-updater || true
sudo systemctl daemon-reload
sudo apt update
```

## License

MIT. Contributions welcome.
