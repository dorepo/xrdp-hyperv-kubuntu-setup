# xrdp-hyperv-kubuntu-setup

This script automates the installation and configuration of **xrdp** on **Kubuntu** virtual machines running in **Hyper-V**, with full support for Enhanced Session Mode. It includes performance optimizations such as **x264 codec acceleration** and **PipeWire-based audio** redirection. Additionally, it configures polkit rules to enable seamless access to system features like power management, Flatpak updates, and network control during remote desktop sessions.

---

# 🚀 Features

- Builds **xrdp** and **xorgxrdp** from source (v0.10.4)
- Enables **x264**, **OpenH264**
- Configures **VSOCK transport** for **Hyper-V** enhanced sessions
- Adds **polkit rules** for Flatpak, power control, Colord, PackageKit, and NetworkManager
- Enables **PipeWire audio** redirection

---

# 📦 Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/dorepo/xrdp-hyperv-kubuntu-setup.git
   cd xrdp-hyperv-kubuntu-setup 
2. **Run the script (without root):**

   ```bash
   chmod +x install-xrdp.sh
   ./install-xrdp.sh

3. **Enable enhanced session on the host (Hyper-V):** <br>
Open PowerShell as Administrator and run:
   ```powershell
   Set-VM -VMName "YourVMName" -EnhancedSessionTransportType HvSocket

4. **Enable guest service on the host (Hyper-V):** <br>
Open PowerShell as Administrator and run:
   ```powershell
   Enable-VMIntegrationService -VMName "YourVMName" -Name "Guest Service Interface"
5. **Reboot your Kubuntu VM to apply changes.**


# 📄 License
MIT License. See LICENSE for details.

# 🤝 Contributing
Pull requests are welcome! If you find bugs or want to suggest improvements, feel free to open an issue.
