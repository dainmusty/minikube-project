#!/bin/bash
sudo dnf install -y docker
sudo systemctl enable docker --now
sudo usermod -aG docker ec2-user
