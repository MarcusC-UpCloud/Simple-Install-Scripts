#!/bin/bash

# === AMP (CubeCoders) Auto-Installation Init Script ===
# This script automatically installs AMP during server initialization

# Enable logging
LOG_FILE="/var/log/amp-install.log"
DETAILED_LOG="/var/log/amp-install-detailed.log"

# Start logging
{
    echo "===== AMP Installation Started ====="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
} | tee -a $LOG_FILE $DETAILED_LOG

# Create initial "Installing" MOTD
create_installing_motd() {
    cat > /etc/update-motd.d/91-amp-installing << 'EOF'
#!/bin/bash
echo "----------------------------------------"
echo -e "\033[0;33m📦 AMP installation in progress...\033[0m"
echo "----------------------------------------"
echo ""
echo "The automated installation of AMP is currently running."
echo "This typically takes 5-10 minutes depending on your server specs."
echo ""
echo "To check installation progress:"
echo "  cat /var/log/amp-install.log"
echo ""
echo "To view detailed logs:"
echo "  cat /var/log/amp-install-detailed.log"
echo "----------------------------------------"
EOF
    chmod +x /etc/update-motd.d/91-amp-installing
}

# Create initial "Installing" MOTD right away
create_installing_motd

# Create a function to handle errors
handle_error() {
    {
        echo "[ERROR] An error occurred during installation at step: $1"
        echo "Please check $DETAILED_LOG for more details"
        echo ""
    } | tee -a $LOG_FILE $DETAILED_LOG
    
    # Create a failure notice in MOTD
    cat > /etc/update-motd.d/99-amp-install-failed << 'EOF'
#!/bin/bash
echo "----------------------------------------"
echo -e "\033[0;31mAMP installation failed\033[0m"
echo "Please check the installation logs for details:"
echo "- /var/log/amp-install.log (summary)"
echo "- /var/log/amp-install-detailed.log (detailed)"
echo "----------------------------------------"
EOF
    chmod +x /etc/update-motd.d/99-amp-install-failed
    
    exit 1
}

# Function to get the server's IP addresses
get_server_ip() {
    # Try to get the public IP first
    PUBLIC_IP=$(curl -s -4 https://ifconfig.io || curl -s -4 https://api.ipify.org || curl -s -4 https://icanhazip.com)
    
    # Get the private IP as backup
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    
    # If public IP is available, use it; otherwise use private IP
    if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "127.0.0.1" ]]; then
        echo "$PUBLIC_IP"
    else
        echo "$PRIVATE_IP"
    fi
}

# Step 1: Install AMP
{
    echo "[STEP 1] Installing AMP using the official CubeCoders installer script..."
    echo "This may take several minutes. Please be patient."
    echo ""
} | tee -a $LOG_FILE $DETAILED_LOG

# Run the AMP installer and redirect output to logs
# The installer requires a non-interactive flag to prevent it from prompting for input.
if ! bash <(curl -fsSL getamp.sh) install-noninteractive >> $DETAILED_LOG 2>&1; then
    handle_error "AMP installation script"
fi

{
    echo "[STEP 1] AMP installation completed successfully."
    echo ""
} | tee -a $LOG_FILE $DETAILED_LOG

# Step 2: Check if AMP is running
{
    echo "[STEP 2] Verifying AMP service is running..."
} | tee -a $LOG_FILE $DETAILED_LOG

# Wait for services to fully start
sleep 20

# Check if the ampinstmgr service is active
if systemctl is-active --quiet ampinstmgr; then
    {
        echo "[STEP 2] Verified the 'ampinstmgr' service is active."
        echo ""
    } | tee -a $LOG_FILE $DETAILED_LOG
else
    {
        echo "[ERROR] The 'ampinstmgr' service was not found or is not active."
        echo "This might indicate an issue with the installation process."
        echo ""
    } | tee -a