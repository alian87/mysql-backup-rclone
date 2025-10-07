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
# Run rclone config in a temporary container
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
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

1. A browser window will open (or you'll get a URL to visit)
2. Sign in to your Google account
3. Grant permissions to Rclone
4. Copy the authorization code back to the terminal

## Step 5: Complete Configuration

1. **Configure as a team drive**: Type `n` and press Enter
2. **Shared drive (Team Drive) ID**: Press Enter (leave blank)
3. **Configuration complete**: Type `y` and press Enter

## Step 6: Test Configuration

```bash
# Test the configuration
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest lsd gdrive:
```

You should see your Google Drive folders listed.

## Step 7: Create Backup Directory (Optional)

```bash
# Create a backups directory in Google Drive
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest mkdir gdrive:backups
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
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest listremotes

# Test connection
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest about gdrive:

# List files
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest ls gdrive:

# Create directory
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest mkdir gdrive:backups

# Delete directory (be careful!)
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest rmdir gdrive:backups
```

## Security Notes

- Never commit your `rclone.conf` file to version control
- Use Docker secrets in production for sensitive configuration
- Regularly rotate your Google Drive API credentials
- Consider using service accounts for production environments

## Next Steps

Once Rclone is configured, you can proceed with deploying your MySQL backup container using the provided Docker Compose or Docker Swarm configurations.
