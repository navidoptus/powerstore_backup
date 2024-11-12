# PowerStore NAS Backup Automation to Data Domain

![PowerStore NAS Backup](docs/images/banner.png)

A PowerShell-based automation solution for backing up PowerStore NAS servers to a Data Domain appliance. Choose from two backup options: **NAS server cloning** or **file system snapshotting**, both configured to automate NDMP access and apply a 35-day retention policy.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Backup Options](#backup-options)
- [Quick Start](#quick-start)
- [Setup Instructions](#setup-instructions)
- [Use Cases](#use-cases)
- [File Structure](#file-structure)
- [Example Commands](#example-commands)
- [Scheduling the Backup](#scheduling-the-backup)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This solution provides two approaches for PowerStore NAS backups:

1. **NAS Server Cloning**: Creates a writable, point-in-time copy of the NAS server on the DR site for backup.
2. **File System Snapshotting**: Creates read-only snapshots of individual file systems on the NAS server, which is more space-efficient.

Each backup method supports NDMP configuration and includes an automated 35-day retention policy to manage storage efficiently.

---

## Features

- 🚀 **Automated Daily NAS Cloning or Snapshotting**: Choose between creating a full NAS clone or snapshots of individual file systems.
- 🔐 **Configurable NDMP Backup Integration**: Easily set up NDMP access for Data Domain backups.
- 🕒 **Retention Management**: Automatically deletes clones or snapshots older than 35 days to maintain storage efficiency.

---

## Backup Options

### Option 1: NAS Server Cloning
With this approach, the script creates a **writable clone** of the DR NAS server for backup.
- **Ideal For**: Situations requiring full, independent copies of NAS servers.
- **Script**: [Clone Backup Script](scripts/Clone_Backup_Script.ps1)

### Option 2: File System Snapshotting
This method creates **read-only snapshots** of individual file systems, suitable for lightweight, point-in-time backups.
- **Ideal For**: Scenarios where only specific file systems need to be backed up with minimal storage use.
- **Script**: [Snapshot Backup Script](scripts/Snapshot_Backup_Script.ps1)

---

## Quick Start

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/navidoptus/powerstore_backup.git
   cd powerstore_backup
   ```

2. **Edit Configuration**:
   * Update PowerStore API credentials, NAS server IDs, and other configuration details in the script files in the `scripts/` folder.

3. **Run the Script**:
   * Test the desired script manually before scheduling:
   ```powershell
   # Run the clone script
   powershell.exe -File "scripts/Clone_Backup_Script.ps1"
   
   # Or run the snapshot script
   powershell.exe -File "scripts/Snapshot_Backup_Script.ps1"
   ```

4. **Automate**:
   * Set up a daily job using Task Scheduler (Windows) or cron (Linux) as described in the installation guide.

## Setup Instructions

### Prerequisites

1. **PowerShell Environment**:
   * PowerShell should be installed on the server running the script.

2. **Network Access**:
   * The server running the script must have network access to PowerStore and Data Domain.

3. **PowerStore API Credentials**:
   * Ensure you have API access credentials with sufficient permissions.

4. **Data Domain Configuration**:
   * NDMP should be configured on Data Domain to receive backups.

5. **Valid IP Address for Clone** (if using clone option):
   * Ensure an IP from the correct VLAN is available if needed for clone access.

### Installation Guide

For full setup and installation instructions, refer to the installation guide, which includes step-by-step instructions for both **Windows Task Scheduler** and **Linux cron**.

## Use Cases

Choose the right backup method based on your environment:

* **NAS Server Cloning**:
   * Provides full, writable copies of the NAS server, which can be beneficial for environments where data needs to be fully accessible or recoverable in an independent state.

* **File System Snapshotting**:
   * Offers a lightweight, read-only backup option for individual file systems. Ideal for environments with storage constraints or that only require specific file systems to be backed up.

## File Structure

```plaintext
powerstore_backup/
├── scripts/
│   ├── Clone_Backup_Script.ps1    # Script for NAS cloning option
│   ├── Snapshot_Backup_Script.ps1 # Script for file system snapshots option
├── README.md                      # Main project documentation
├── docs/
│   ├── images/                    # Folder for screenshots or images
│   └── installation.md           # Detailed setup guide
```

## Example Commands

Run the clone backup script manually:
```powershell
# Clone Backup Script
powershell.exe -File "scripts/Clone_Backup_Script.ps1"
```

Run the snapshot backup script manually:
```powershell
# Snapshot Backup Script
powershell.exe -File "scripts/Snapshot_Backup_Script.ps1"
```

## Scheduling the Backup

You can schedule the script to run daily using Task Scheduler (Windows) or cron (Linux). Detailed instructions for scheduling are available in the installation guide.

## Troubleshooting

* **Authentication Error**:
   * Ensure that PowerStore API credentials are correct and have sufficient permissions.

* **Network Timeout**:
   * Verify network connectivity between the server and PowerStore/Data Domain devices.

* **Script Execution Error**:
   * Ensure PowerShell has the necessary execution policy enabled (e.g., `Set-ExecutionPolicy RemoteSigned`).

## Future Enhancements

* **Email Notifications**: Set up notifications for backup completion or failure.
* **Error Logging**: Improve logging for easier troubleshooting.
* **GUI**: Develop a GUI to streamline configuration and execution.

## Contributing

Contributions are welcome! If you'd like to improve the project, please submit a pull request or open an issue to discuss.

## License

This project is licensed under the MIT License - see the LICENSE file for details.