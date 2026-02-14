# RetroVault (macOS)

**RetroVault** is a macOS application for accessing and maintaining legacy disk image formats. It enables users to mount, inspect, 
and repair classic floppy disk images within a modern macOS environment.

> **Status:** Beta  
> Feedback and bug reports are welcome via the GitHub project page.  
> Before mounting disk images, ensure that you have created backups. Data corruption may occur during testing.

---

## Overview

RetroVault provides tools for working with historical disk image formats on macOS.  
Currently supported formats include:

- **Amiga** – ADF (Amiga Disk File)
- **Commodore 64** – D64 (1541 disk images)

---

## Features

### Mount

RetroVault integrates with **macFUSE** to mount supported disk images as native file systems on macOS. 
Once mounted, images can be accessed through Finder or standard command-line tools.

If macFUSE is not installed, mounting functionality is unavailable; however, all other features of RetroVault 
remain fully operational.

---

### Explore

A built-in block viewer allows low-level inspection of disk images. Users can:

- Examine raw block data  
- Edit individual bytes  
- Write modifications directly back to the image file  

This functionality is intended for advanced users who require precise control over file system structures.

---

### Repair

RetroVault analyzes internal file system structures, including:

- Block chains  
- Allocation maps  
- Structural consistency  

Detected inconsistencies are reported clearly. Where possible, errors can be repaired to restore file system integrity.

---

## Notes

RetroVault is under active development. Behavior and features may change between releases.  
Users are strongly encouraged to maintain backups of all disk images prior to modification.
