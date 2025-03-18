# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Latest stable.
FROM --platform=linux/amd64 debian:12

# Install packages required for building AAOSP targets.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    apt-transport-https ca-certificates \
    git git-core gnupg flex bison build-essential zip unzip zlib1g-dev \
    libc6-dev libxml2-utils xsltproc unzip fontconfig gcc-multilib \
    g++-multilib libncurses5 libssl-dev python3 python3-setuptools python3-pip \
    python3-requests python3-venv python3-virtualenv procps \
    meson bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build \
    pkg-config rsync less curl sudo vim ssh findutils gawk jq htop && \
    apt-get update -y && apt install -y npm nodejs && \
    rm -rf /var/lib/apt/lists/*

# The following installs gcloud sdk including gsutil required for uploading
# artifacts to Google Cloud Storage. Remove if using alternative storage.
# https://cloud.google.com/storage/docs/gsutil_install
# GCS:START
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update -y && apt-get install -y google-cloud-cli kubectl && \
    apt-get -y clean
# GCS:END

# Install Google repo command tool
RUN export REPO=$(mktemp /tmp/repo.XXXXXXXXX) && \
    curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo && \
    gpg --recv-key 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65 && \
    curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | \
    gpg --verify - ${REPO} && install -m 755 ${REPO} /usr/bin/repo

# Add USER and provide sudo access.
ARG USER=builder
RUN useradd -u 1000 -ms /bin/bash ${USER} && \
    passwd -d ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers

# Switch to user
USER ${USER}
WORKDIR /home/${USER}

# Configure git config (fake details) for Google repo.
RUN git config --global user.email "aaosp.jenkins@dummy.com" && \
    git config --global user.name "AAOSP Jenkins" && \
    git config --global color.ui false

# Create virtualenv ready for RPi builds (include-system-site-packages=true)
# Install the required packages.
RUN virtualenv --system-site-packages venv && \
    . ${HOME}/venv/bin/activate && pip3 install --user meson==1.1.0 mako \
    jinja2 ply pyyaml dataclasses && deactivate
