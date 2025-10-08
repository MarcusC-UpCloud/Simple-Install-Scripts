#!/bin/bash

# === AMP (CubeCoders) Auto-Installation Init Script ===

# --- Script Configuration ---
LOG_FILE="/var/log/amp-install.log"
DETAILED_LOG="/var/log/amp-install-detailed.log"
# !!! IMPORTANT !!! Set your desired AMP username and password here
AMP_USER="YourAdminUsername"
AMP_PASS="YourVerySecurePassword123"

# --- Start Logging ---
{
    echo "===== AMP Installation Started ====="
    echo "Date: $(date)"
} | tee -a $LOG_FILE $DETAILED_LOG

# --- Function to handle errors ---
handle_error() {
    echo "[ERROR] An error occurred during step: $1" | tee -a $LOG_FILE
    echo "Please check $DETAILED_LOG for more details." | tee -a $LOG_FILE
    exit 1
}

# --- STEP 1: Install the AMP Core Tools ---
{
    echo ""
    echo "[STEP 1] Installing AMP core tools using the official installer..."
    echo "This step installs the 'ampinstmgr' utility."
} | tee -a $LOG_FILE $DETAILED_LOG

# Run the installer. It should not ask for input with this method.
if ! curl -fsSL getamp.sh | sudo DEBIAN_FRONTEND=noninteractive bash >> $DETAILED_LOG 2>&1; then
    handle_error "Core Tools Installation (getamp.sh)"
fi

echo "[STEP 1] Core tools installed successfully." | tee -a $LOG_FILE $DETAILED_LOG

# --- STEP 2: Create and Configure the AMP Instance ---
{
    echo ""
    echo "[STEP 2] Creating the 'ADS01' AMP instance..."
    echo "This step creates the instance and the admin user."
} | tee -a $LOG_FILE $DETAILED_LOG

# Use the ampinstmgr tool to create the instance non-interactively
# This command is run as the 'amp' user, which was created in Step 1.
if ! sudo -u amp ampinstmgr CreateInstance +Core.Login.Username "$AMP_USER" +Core.Login.Password "$AMP_PASS" +Core.AMP.AgreedToTOS True ADS01 0.0.0.0 8080 LicenceKeyHere >> $DETAILED_LOG 2>&1; then
    handle_error "Instance Creation (ampinstmgr)"
fi

echo "[STEP 2] Instance 'ADS01' created and configured successfully." | tee -a $LOG_FILE $DETAILED_LOG

# --- Final Summary ---
SERVER_IP=$(curl -s -4 https://ifconfig.io)
{
    echo ""
    echo "==============================="
    echo "✅ AMP Installation Complete!"
    echo "Access your AMP panel at: http://$SERVER_IP:8080"
    echo "Username: $AMP_USER"
    echo "==============================="
} | tee -a $LOG_FILE $DETAILED_LOG