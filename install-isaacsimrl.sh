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
apt-get install -y nvidia-container-toolkit nfs-common
systemctl restart docker
docker run --rm --gpus all ubuntu nvidia-smi

# Download IsaacSim Image from NVCR repository
docker login --username=\$oauthtoken --password="${NGCPASSWORD}" nvcr.io
docker pull public.ecr.aws/nvidia/isaac-sim:2023.1.1
docker tag public.ecr.aws/nvidia/isaac-sim:2023.1.1 nvcr.io/nvidia/isaac-sim:2023.1.1

# Download OIGE Repository
cd /home/ubuntu/environment
git clone https://github.com/NVIDIA-Omniverse/OmniIsaacGymEnvs.git

# Download Distributed Utility and Docker file
wget https://raw.githubusercontent.com/asriaws/robotics-boilerplate/main/distributed_run.bash
wget https://raw.githubusercontent.com/asriaws/robotics-boilerplate/main/isaacsimrl-dockerfile
mv distributed_run.bash /home/ubuntu/environment/OmniIsaacGymEnvs/docker/
mv isaacsimrl-dockerfile /home/ubuntu/environment/OmniIsaacGymEnvs/Dockerfile

#Build the Image and Push to ECR
cd /home/ubuntu/environment/OmniIsaacGymEnvs
docker build -t isaacgym-batch:latest .
aws ecr create-repository --repository-name isaacgym-batch --region ${AWS::Region}
aws ecr get-login-password --region ${AWS::Region} | docker login --username AWS --password-stdin ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com
docker tag isaacgym-batch:latest ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/isaacgym-batch:latest
docker push ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/isaacgym-batch:latest