# .zshrc Features Reference

## History Autocompletion

| Feature | How to Use |
|---------|------------|
| Up/Down arrow history search | Type partial command, press ↑/↓ to cycle matches |
| Reverse search | `Ctrl+R` |
| Forward search | `Ctrl+S` |
| Shared history | Commands sync across all terminal sessions |
| 10,000 command history | Increased from 1,000 |
| Duplicate removal | Auto-removes duplicate entries |

---

## Aliases - Navigation

| Alias | Command |
|-------|---------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `.....` | `cd ../../../..` |
| `~` | `cd ~` |
| `-` | `cd -` (previous directory) |

---

## Aliases - Listing

| Alias | Command |
|-------|---------|
| `ll` | `ls -lh` |
| `la` | `ls -A` |
| `l` | `ls -CF` |
| `lal` | `ls -alh` |
| `lt` | `ls -lth` (sort by time) |
| `lS` | `ls -lSh` (sort by size) |

---

## Aliases - File Operations (Safe Defaults)

| Alias | Command |
|-------|---------|
| `cp` | `cp -iv` (interactive, verbose) |
| `mv` | `mv -iv` |
| `rm` | `rm -Iv` |
| `mkdir` | `mkdir -pv` |
| `ln` | `ln -iv` |

---

## Aliases - Search & Find

| Alias | Command |
|-------|---------|
| `ff` | `find . -name` |
| `fd` | `find . -type d -name` |
| `h` | `history \| grep` |

---

## Aliases - System Info

| Alias | Command |
|-------|---------|
| `df` | `df -h` |
| `du` | `du -h` |
| `free` | `free -h` |
| `psg` | `ps aux \| grep` |
| `ports` | `netstat -tulanp` |
| `myip` | Shows public IP |
| `localip` | Shows local IP |

---

## Aliases - Git

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gc` | `git commit -m` |
| `gca` | `git commit -a -m` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gb` | `git branch` |
| `gba` | `git branch -a` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git log --oneline --graph -10` |
| `glog` | `git log --oneline --graph --all` |
| `gst` | `git stash` |
| `gstp` | `git stash pop` |
| `grh` | `git reset --hard` |
| `grs` | `git reset --soft` |

---

## Aliases - Docker

| Alias | Command |
|-------|---------|
| `d` | `docker` |
| `dc` | `docker compose` |
| `dps` | `docker ps` |
| `dpsa` | `docker ps -a` |
| `di` | `docker images` |
| `dex` | `docker exec -it` |
| `dlog` | `docker logs -f` |
| `drm` | `docker rm` |
| `drmi` | `docker rmi` |
| `dprune` | `docker system prune -af` |

---

## Aliases - Python

| Alias | Command |
|-------|---------|
| `py` | `python3` |
| `pip` | `pip3` |
| `venv` | `python3 -m venv` |
| `activate` | `source venv/bin/activate` |

---

## Aliases - Misc Shortcuts

| Alias | Command |
|-------|---------|
| `c` | `clear` |
| `e` | `$EDITOR` |
| `v` | `vim` |
| `sv` | `sudo vim` |
| `path` | Print PATH (one per line) |
| `now` | Current date/time |
| `week` | Current week number |
| `reload` | `source ~/.zshrc` |
| `zshrc` | Edit ~/.zshrc |
| `ping` | `ping -c 5` |
| `wget` | `wget -c` (resume) |
| `sha` | `shasum -a 256` |

---

## Functions

| Function | Description |
|----------|-------------|
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Extract any archive (tar, zip, gz, 7z, rar, etc.) |
| `backup <file>` | Create timestamped backup (`file.bak.20250120_143022`) |
| `killp <name>` | Kill process by name |
| `serve [port]` | Start Python HTTP server (default port 8000) |

---

## Commented Kali/Security Aliases (Uncomment to Enable)

| Alias | Command |
|-------|---------|
| `nse` | Search nmap scripts |
| `msfconsole` | `msfconsole -q` (quiet mode) |
| `serve` | `python3 -m http.server 8080` |
| `listen` | `nc -lvnp` |
