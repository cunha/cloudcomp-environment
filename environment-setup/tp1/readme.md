# TP1 Setup Guide

This guide provides detailed instructions to set up the environment necessary for TP1 using Ansible. The repository is organized into three main directories, each with a specific function.

## Repository Structure

- **students**: This folder is responsible for creating users and setting their passwords as the MD5 hash of each user's public key.
- **hadoop_spark**: This folder handles the installation of Hadoop and Spark, and configures each user's directory in HDFS.
- **jupyter**: Provides the Jupyter platform online at the address `localhost:8000` to enable work development.

## Prerequisites

Before starting, ensure that Ansible is installed on your machine. If it's not, follow the Ansible installation instructions in its official documentation.

## Installation Instructions

Follow the steps below to set up TP1:

1. **Install Ansible**:
   - Check if Ansible is installed by running `ansible --version` in the terminal. If not, install it using your preferred package manager.

2. **Configure the `students.yml` File**:
   - Navigate to the `students` folder and edit the `students.yml` file.
   - Enter the username and corresponding public key for each student.

3. **Run the User Playbook**:
   - Execute the following command in the terminal to run the playbook responsible for user creation:
     ```bash
     ansible-playbook playbook-tp1-users.yml
     ```

4. **Run the Hadoop and Spark Playbook**:
   - Navigate to the `hadoop_spark` folder and execute the command:
     ```bash
     ansible-playbook playbook_hadoop_and_spark.yml
     ```

5. **Run the JupyterHub Playbook**:
   - In the `jupyterhub` folder, execute the following command:
     ```bash
     ansible-playbook playbook_jupyterhub.yml
     ```

## Installation Test

To test if the setup was successful, follow the steps below:

1. **SSH Connection with Tunneling**:
   - Establish an SSH connection with tunneling to port 8000. Use the command below, replacing `<username>` and `<IP address>` with the correct information:
     ```bash
     ssh <username>@<IP address> -L 8000:localhost:8000
     ```

2. **Access Jupyter**:
   - Open your browser and go to `localhost:8000`.
   - Use the configured username and the corresponding password, which is the MD5 hash of the student's public key.
