![Last Commit](https://img.shields.io/github/last-commit/navidoptus/powerstore_backup)

# PowerStore NAS Backup Automation to Data Domain

This repository contains a PowerShell-based automation solution for backing up PowerStore NAS servers to a Data Domain appliance. 

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Backup Options](#backup-options)
- [Setup Instructions](#setup-instructions)
- [Running the Script](#running-the-script)
- [Scheduling the Backup](#scheduling-the-backup)
- [File Structure](#file-structure)
- [Contributing](#contributing)
- [License](#license)

## Overview
This repository provides two PowerStore NAS backup options: NAS cloning and file system snapshots.

## Features
- **Automated Daily NAS Cloning or Snapshotting**
- **Configurable NDMP Backup**
- **Retention Management**

## Backup Options
### Clone Option
Creates a writable clone of the NAS server. [Script here](scripts/Clone_Backup_Script.ps1)

### Snapshot Option
Creates read-only snapshots of file systems. [Script here](scripts/Snapshot_Backup_Script.ps1)

## Setup Instructions
Detailed setup and scheduling instructions are available in our [installation guide](docs/installation.md).

## File Structure
```plaintext
powerstore_backup/
├── scripts/
│   ├── Clone_Backup_Script.ps1
│   ├── Snapshot_Backup_Script.ps1
├── README.md
├── docs/
│   ├── images/
│   └── installation.md
