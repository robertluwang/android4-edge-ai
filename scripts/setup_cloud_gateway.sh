#!/usr/bin/env bash

# Android 4.0.4 Edge AI Node - Cloud LiteLLM Gateway Setup Script
# This script runs on your Cloud VM (GCP/OCI) to securely host LiteLLM,
# proxying requests to Google Vertex AI or other model providers.

set -euo pipefail

echo "====================================================================="
echo "        Android 4.0.4 Edge AI - Cloud Gateway Setup (LiteLLM)"
echo "====================================================================="
echo

# 1. Configuration files setup
LITELLM_DIR="${HOME}/litellm-gateway"
mkdir -p "$LITELLM_DIR"

echo "Creating LiteLLM config at ${LITELLM_DIR}/config.yaml..."

cat << 'EOF' > "$LITELLM_DIR/config.yaml"
model_list:
  - model_name: google/gemini-1.5-flash
    litellm_params:
      model: vertex_ai/gemini-1.5-flash
      # Note: Ensure google application credentials are set or GCP Service Account has access
      # vertex_project: "your-gcp-project-id"
      # vertex_location: "us-central1"

router_settings:
  routing_strategy: latency-based-routing

general_settings:
  master_key: sk-your-litellm-master-key-here # Match config.json api_key
EOF

# 2. Systemd Service creation
echo "Creating systemd unit file template..."
cat << EOF > "$LITELLM_DIR/litellm.service"
[Unit]
Description=LiteLLM Gateway for Android Edge AI Node
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${LITELLM_DIR}
# Bind to localhost (127.0.0.1:4000) for security.
# This ensures it's only accessible via secure SSH tunnel from the phone.
ExecStart=$(which pipx 2>/dev/null || which pip 2>/dev/null || echo "pip") run litellm --config config.yaml --host 127.0.0.1 --port 4000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "---------------------------------------------------------------------"
echo "🛠️  How to Install & Start LiteLLM on the Cloud VM:"
echo "---------------------------------------------------------------------"
echo "1. Install pipx & litellm:"
echo "   sudo apt-get update && sudo apt-get install -y pipx"
echo "   pipx ensurepath"
echo "   pipx install litellm"
echo
echo "2. Install Google Vertex AI Dependencies:"
echo "   pipx inject litellm google-cloud-aiplatform"
echo
echo "3. Copy and enable the systemd service:"
echo "   sudo cp ${LITELLM_DIR}/litellm.service /etc/systemd/system/litellm.service"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable litellm"
echo "   sudo systemctl start litellm"
echo
echo "4. Authenticate GCP Service Account:"
echo "   Make sure your GCP VM has access to Vertex AI (via IAM Service Account),"
echo "   or set the GOOGLE_APPLICATION_CREDENTIALS env variable in the service file."
echo
echo "---------------------------------------------------------------------"
echo "🔒 How to Connect Android Node safely to this VM (No firewall ports open!):"
echo "---------------------------------------------------------------------"
echo "You do not need to open port 4000 to the world."
echo "On your Android 4.0.4 device using ConnectBot:"
echo "  - Connect to: ubuntu@<YOUR_VM_PUBLIC_IP>:22"
echo "  - Open 'Port Forwards' from the connection options."
echo "  - Add 'Local' Port Forward:"
echo "      Source Port:      8080"
echo "      Destination:      127.0.0.1:4000"
echo
echo "Your PicoClaw binary on the phone will now securely route requests to:"
echo "  http://127.0.0.1:8080/v1"
echo "And ConnectBot will safely tunnel them to your GCP LiteLLM Gateway!"
echo "====================================================================="
