#!/bin/bash -v

# Download NVIDIA Driver
apt install build-essential -y
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/525.85.05/NVIDIA-Linux-x86_64-525.85.05.run
chmod +x NVIDIA-Linux-x86_64-525.85.05.run
./NVIDIA-Linux-x86_64-525.85.05.run --silent

# Download NVIDIA Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
&& \
    sudo apt-get update
apt-get install -y nvidia-container-toolkit
systemctl restart docker
docker run --rm --gpus all ubuntu nvidia-smi

# Download IsaacGym Image from S3 Presigned URL and Install the image
curl -o isaac-sim-2023.1.1 $S3IMAGEURL
docker load --input isaac-sim-2023.1.1
