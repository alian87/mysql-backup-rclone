# Rclone Setup Guide

This guide will help you configure Rclone to work with Google Drive for your MySQL backups.

## Prerequisites

- Docker installed
- Google account with Drive access
- Basic command line knowledge

## Step 1: Create Rclone Volume

```bash
# Create a Docker volume for rclone configuration
docker volume create rclone_config
```

## Step 2: Configure Rclone

```bash
# Run rclone config in a temporary container using the backup image
docker run --rm -it --entrypoint bash -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest

# Inside the container, run:
# rclone config
```

## Step 3: Follow the Configuration Wizard

When prompted, follow these steps:

1. **Create a new remote**: Type `n` and press Enter
2. **Name**: Type `gdrive` and press Enter
3. **Storage type**: Type `drive` and press Enter
4. **Client ID**: Press Enter (leave blank for default)
5. **Client Secret**: Press Enter (leave blank for default)
6. **Scope**: Press Enter (use default)
7. **Service Account File**: Press Enter (leave blank)
8. **Advanced config**: Type `n` and press Enter
9. **Use auto config**: Type `y` and press Enter

## Step 4: Authenticate with Google

⚠️ **Important**: Since you're inside a container, you need to use a local machine with rclone installed and a web browser available.

### 4.1. Rclone will show something like this:

```
Option config_token.
For this to work, you will need rclone available on a machine that has
a web browser available.
For more help and alternate methods see: https://rclone.org/remote_setup/
Execute the following on the machine with the web browser (same rclone
version recommended):
        rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
Then paste the result.
Enter a value.
config_token>
```

⚠️ **IMPORTANT**: The code `"eyJzY29wZSI6ImRyaXZlIn0"` above is just an **example**. Each configuration generates a unique code. **Use the EXACT code shown in your terminal!**

### 4.2. Install rclone on your local machine (if not already installed):

**Windows:**
```powershell
# Using chocolatey
choco install rclone

# OR download manually from: https://rclone.org/downloads/
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install rclone

# OR
curl https://rclone.org/install.sh | sudo bash
```

**macOS:**
```bash
brew install rclone
```

### 4.3. Run the authorization command:

1. **Copy the COMPLETE command** shown in the container (something like: `rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"`)
   - ⚠️ **Don't use the example above!** Copy the exact command from your terminal
2. **Execute on your local machine** (outside the container) the command you copied
3. A **browser window will open automatically**
4. **Log in** to your Google account
5. **Authorize** access to Google Drive
6. The terminal will display a **token** (a long JSON code)

### 4.4. Paste the token back into the container:

1. **Copy the entire token** displayed on your local machine (starts with `{` and ends with `}`)
2. **Paste into the container terminal** where it's waiting for `config_token>`
3. Press Enter

## Step 5: Complete Configuration

1. **Configure as a team drive**: Type `n` and press Enter
2. **Shared drive (Team Drive) ID**: Press Enter (leave blank)
3. **Configuration complete**: Type `y` and press Enter

## Step 6: Test Configuration

```bash
# Test the configuration
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest lsd gdrive:
```

You should see your Google Drive folders listed.

## Step 7: Create Backup Directory (Optional)

```bash
# Create a backups directory in Google Drive
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest mkdir gdrive:backups
```

## Alternative: Manual Configuration

If you prefer to configure rclone manually, you can create the configuration file directly:

```bash
# Create the configuration directory
docker run --rm -v rclone_config:/root/.config/rclone alpine mkdir -p /root/.config/rclone

# Create the configuration file (replace with your actual config)
docker run --rm -v rclone_config:/root/.config/rclone alpine sh -c 'cat > /root/.config/rclone/rclone.conf << EOF
[gdrive]
type = drive
client_id = 
client_secret = 
scope = drive
root_folder_id = 
service_account_file = 
EOF'
```

## Troubleshooting

### Common Issues

1. **Authentication failed**: Make sure you're using the correct Google account
2. **Permission denied**: Check that you have write access to Google Drive
3. **Network issues**: Ensure your container can access the internet

### Useful Commands

```bash
# List remotes
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest listremotes

# Test connection
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest about gdrive:

# List files
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest ls gdrive:

# Create directory
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest mkdir gdrive:backups

# Delete directory (be careful!)
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest rmdir gdrive:backups
```

## Security Notes

- Never commit your `rclone.conf` file to version control
- Use Docker secrets in production for sensitive configuration
- Regularly rotate your Google Drive API credentials
- Consider using service accounts for production environments

## Next Steps

Once Rclone is configured, you can proceed with deploying your MySQL backup container using the provided Docker Compose or Docker Swarm configurations.
