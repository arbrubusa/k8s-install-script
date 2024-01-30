# k8s-install-script

This is a basic script to setup a one node kubernetes solution in an Ubuntu 22.04 VM running in UTM on a Mac with Apple Silicon M1.

# Some Information

The script does the main setup for a one-node kubernetes service on a Ubuntu 22.04 VM (https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso). The script was created specifically for my use with a MacBook running Apple M1 Silicon, so it might need a few adaptations to run on other architectures.

It uses Kubernetes version 1.29.0-1.1 (as of 01/30/2024). I tried my best explain each part of it, so if you´re new to Kubernetes (or k8s) or to Linux, you will have an idea of what it´s doing. If you notice any inconsistencies, please let me know.

Clone this script on the HOME directory of the user you created on Ubuntu. Make it an executable running the command "sudo chmod +x <filename.sh>". After that, is just run "./<filename.sh>" and the script will execute itself. As you need sudo rights, it will as for your password at the beginning.

# The script

## Bash Executable
The first line says where bash executable is and can vary depending the Linux flavor or particular implementation. To know where your version is, you can run the command "which bash" in the command line (CLI) and it will show you the current path. In my case, /usr/bin/bash.

