# Android 4.0.4 Edge AI Node

Repurposing legacy, obsolete 32-bit Android hardware into a lightweight Edge AI worker node. This project enables local edge execution utilizing a 32-bit client binary (**PicoClaw**) and securely routes LLM inference to a remote Cloud VM running a [LiteLLM Gateway](https://github.com/robertluwang/litellm-gateway).

---

## 🏗️ Architecture Overview

To keep the edge device lightweight, computationally heavy inference is offloaded over a secure, encrypted SSH tunnel rather than exposing the cloud endpoints directly to the public internet:

```
[Android 4.0.4 Node]                                       [Cloud VM (GCP/OCI)]
====================                                       ====================
   PicoClaw Client                                           LiteLLM Gateway
         │                                                          ▲
         ▼ (local request)                                          │ (internal proxy)
  localhost:8080                                                    │
         │                                                          │
   [ConnectBot] <==== Encrypted SSH Port-Forwarding ====> localhost:4000
                                                                    │
                                                                    ▼
                                                             Google Vertex AI
```

---

## 📁 Repository Structure

*   `design.md`: The complete technical master guide detailing setup phases, rooting, and background execution.
*   `scripts/`
    *   `setup_pc_server.sh`: Hosts a quick local Python server on your PC to sideload legacy APKs and binaries onto your phone.
    *   `deploy_to_phone.sh`: Simplifies deploying the compiled 32-bit `picoclaw` binary to the phone via SCP.
*   `apks/`: Local cache directory for legacy apps (SSHDroid, ConnectBot, Framaroot, etc.). *[Ignored by Git]*
*   `bin/`: Local cache directory for compiled 32-bit ARM binaries. *[Ignored by Git]*

---

## 🚀 Setup & Usage Guide

### Phase 1: Environment Preparation

1.  Enable **Unknown Sources** on the Android device:
    *   Go to **Settings** > **Security**.
    *   Check the box for **Unknown Sources**.

### Phase 2: Sideloading Apps (PC Side)

1.  Place your legacy `.apk` files inside the `apks/` folder.
2.  Place the compiled `picoclaw` 32-bit ARM binary in `bin/picoclaw`.
3.  On your PC, run the file-sharing server script:
    ```bash
    ./scripts/setup_pc_server.sh
    ```
4.  Open the web browser on your Android 4.0.4 device and navigate to the displayed URL (e.g., `http://<YOUR_PC_IP>:8000`) to download and install:
    *   **SSHDroid**: To run an SSH server on your device.
    *   **ConnectBot**: To establish an outbound SSH connection and tunnel.

### Phase 3: Deploying PicoClaw to the Phone

Once SSHDroid is running on the phone, execute the automated deployment script on your PC:

```bash
./scripts/deploy_to_phone.sh
```

Choose your setup mode:
*   **Non-Rooted**: Deploys the binary into the sandboxed SSHDroid directory (`/data/data/berserker.android.apps.sshdroid/home/`) using port `2222`.
*   **Rooted**: Mounts the system partition as read-write, copies `picoclaw` globally to `/system/xbin/`, and sets the executable permissions.

---

## 🔒 Cloud Integration & Tunnel Setup

1.  Ensure your **LiteLLM Gateway** is running on your cloud server (e.g., listening on port `4000` via `127.0.0.1` inside your [litellm-gateway](https://github.com/robertluwang/litellm-gateway) repository).
2.  On the Android device, open **ConnectBot** and connect to your Cloud VM:
    *   Target: `ubuntu@<YOUR_VM_PUBLIC_IP>:22`
3.  Tap the menu and select **Port Forwards**. Add a new local port forward:
    *   **Source Port**: `8080`
    *   **Destination**: `127.0.0.1:4000`
4.  Keep ConnectBot running in the background. Your PicoClaw client can now issue requests directly to `http://127.0.0.1:8080/v1` and have them securely tunneled.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
