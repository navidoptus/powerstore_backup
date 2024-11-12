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
