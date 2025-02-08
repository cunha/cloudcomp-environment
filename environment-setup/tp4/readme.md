# TP4 Setup Guide

This document outlines the steps required to configure the environment for TP4 using Ansible. The repository consists of three primary directories, each serving a specific purpose.

## Repository Structure

- **users**: Manages user creation and assigns passwords, which are stored as the MD5 hash of each user's public key.
- **frameworks**: Oversees the installation of Spark and Delta.
- **jupyterhub**: Hosts Jupyter on `localhost:8000`, enabling an interactive workspace for development.
- **data**: Download Spotify data into the VM.

## Prerequisites

Ensure that Ansible is installed before proceeding. If it's not available on your system, refer to the official documentation for installation guidelines.

## Setup Instructions

Follow these steps to configure TP4:

1. **Install Ansible**:
   - Verify the installation by running `ansible --version` in the terminal. If it's not installed, use your preferred package manager to install it.

2. **Edit the `pub-keys.yaml` File**:
   - Go to the `users` directory and modify the `pub-keys.yaml` file.
   - Add each user's username along with their corresponding public key.

3. **Execute the User Playbook**:
   - Run the following command in the terminal to create user accounts:
     ```bash
     ansible-playbook playbook-passwords.yaml
     ```

4. **Execute the Spark and Delta Playbook**:
   - Change to the `frameworks` directory and execute:
     ```bash
     ansible-playbook playbook-spark-delta.yaml
     ```

5. **Execute the JupyterHub Playbook**:
   - Within the `jupyterhub` directory, run:
     ```bash
     ansible-playbook playbook-jupyterhub.yaml
     ```

6. **Execute the Data Playbook**:
   - Change to the `data` directory and execute:
     ```bash
     ansible-playbook playbook-data.yaml
     ```

## Verification

To confirm that the setup is working correctly, perform the following steps:

1. **Establish an SSH Tunnel**:
   - Open an SSH session with port forwarding to 8000 using the command below, replacing `<username>` and `<IP address>` with the appropriate values:
     ```bash
     ssh <username>@<IP address> -L 8000:localhost:8000
     ```

2. **Access Jupyter**:
   - Open a web browser and navigate to `localhost:8000`.
   - Log in using the assigned username and the corresponding password, which is derived from the MD5 hash of the student's public key.