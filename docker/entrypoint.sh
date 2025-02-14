#!/bin/bash
set -e

# Generate SSH host keys if they don't exist
ssh-keygen -A

# Start the SSH daemon with more permissive options
/usr/sbin/sshd -D -e -o "HostKeyAlgorithms=+ssh-rsa" -o "PubkeyAcceptedKeyTypes=+ssh-rsa" &
SSHD_PID=$!

# Create a flag file to indicate service is ready
touch /tmp/healthy

# Keep container running
exec tail -f /dev/null