# factorio-headless-server
A repository with steps and files needed to set up a headless Factorio server

## Dependencies
- Factorio save file
- Some Debian based linux
- tree (not needed but its nice)

## Setting up the headless server

### Download and Create needed user/directories
1. Create a dedicated 'factorio' user
```shell
sudo useradd factorio
```

2. Create a base folder for the Factorio server files to sit at and 'cd' into it
```shell
sudo mkdir /opt/factorio
cd /opt/factorio
```

3. Change ownership of the folder to the 'factorio' user
```shell
sudo chown -R factorio:factorio /opt/factorio
```

4. Download the Factorio headless executable from https://www.factorio.com/download 

5. Extract the file
```shell
cd /opt
sudo tar -xf factorio.tar.xz
sudo mv factorio /opt/factorio
```

6. Change ownership to Factorio user
```shell
sudo chown -R factorio:factorio /opt/factorio
```

7. Create required directories
```shell
sudo mkdir -p /opt/factorio/saves /opt/factorio/config
sudo chown -R factorio:factorio /opt/factorio/saves /opt/factorio/config
sudo chmod 755 /opt/factorio/saves
```

8. Verify structure
```shell
tree -L 1 /opt/factorio

# expected:
├── bin
├── config
├── data
├── mods
├── saves
└── temp
```

### Create Config File
1. Create the config.ini
```shell
sudo -u factorio nano /opt/factorio/config/config.ini
```

2. Paste in the contents from the config.ini file, the rules are pretty self-explanatory except for auto pause, which pauses the game if no players are actively connected
```ini
[game]
auto_pause_if_empty=true
autosave_interval=10
autosave_slots=5
```

### Create Initial Save File (only need to do this once)
1. I just launched the game normally, created a game with the settings I want then immediately closed the game, on linux specifically it is stored in your user home directory, copy to the saves file in the headless server
```shell
sudo cp ~/.factorio/saves/yoursavefile.zip /opt/factorio/saves/
```

2. ensure the save file is writable
```shell
sudo chown factorio:factorio /opt/factorio/saves/yoursavefile.zip

sudo chmod 664 /opt/factorio/saves/yoursavefile.zip
```

3. Verify permissions
```shell
ls -l /opt/factorio/saves/yoursavefile.zip

# expected:
-rw-rw-r-- factorio factorio yoursavefile.zip
```

### Creating the systemd service
1. Create the service file
```shell
sudo nano /etc/systemd/system/factorio.service
```
2. Paste in the contents of the factorio.service file in this repo, AND change the name of the savefile to your savefile name

3. Enable and start the service
```shell
sudo systemctl daemon-reload
sudo systemctl enable factorio
sudo systemctl start factorio
```
4. Check the status of the Factorio service
```shell
sudo systemctl status factorio
# expected to say "running"

# look at logs
journalctl -u factorio -f
# shouldn't see any errors
```

### Networking
If you are like me and want your friends to join you likely need to allow the Factorio port, and set up port forwarding

1. Set up firewall (if needed)
```shell
sudo ufw allow 34197/udp
sudo ufw enable
```

2. Set up port forwarding with your ISP, typically:
    - select your PC from list of devices
    - Forward port `34197`
    - Protocol can be UDP/TCP but Factorio uses UDP specifically, for me using UDP/TCP didn't affect anything

3. Find your public IP - make note of this for later
```shell
curl -4 ifconfig.me
```

### Setting up Main Save Sync 
This is because it will setup autosaves, Factorio always writes autosaves as _autosaveX.zip; but the main save file is only updated on clean shutdown. so we have the cron job just in case

1. Create the script to update the main save
```shell
sudo nano /opt/factorio/update-main-save.sh
```

2. Paste in the contents from update-main-save.sh in this repo

3. Change the name of the main save file just replace all savefile with the name of yours

4. Give executable perms to the script
```shell
sudo chmod +x /opt/factorio/update-main-save.sh

sudo chown factorio:factorio /opt/factorio/update-main-save.sh
```

5. Create the cron job
```shell
sudo crontab -u factorio -e
```

6. Add:
```cron
*/15 * * * * /opt/factorio/update-main-save.sh >> /opt/factorio/saves/update.log 2>&1
```

7. Verify the cron job
```shell
sudo crontab -u factorio -l
```

### Verifying everything works
1. Check for autosave files and for the main save file to be updated
```shell
ls -lt /opt/factorio/saves
```

2. Check if port 34197 is open
```shell
ss -lunp | grep 34197
```

3. Have your friends try and join, get your public IP and a friend to connect to your server via Factorio, they will enter in something like this:
```shell
x.x.x.x:34197
```

## Troubleshooting

### Crashes every few minutes
This might be a file permission issue where the game is trying to write to the saves file but doesn't have the correct permissions... and it just kind of breaks.

You can see if this is a thing via checking if there is autosave files or by looking at the logs

Double check folder/file permissions, ensure the user 'factorio' owns the folder and has read/write permissions 
