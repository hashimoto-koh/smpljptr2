# Private use

############################
# base-notebook
############################

# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 20.04 (focal)
# https://hub.docker.com/_/ubuntu/?tab=tags&name=focal
# OS/ARCH: linux/amd64

ARG ROOT_CONTAINER=ubuntu:focal-20210723@sha256:1e48201ccc2ab83afc435394b3bf70af0fa0055215c1e26a5da9b50a1ae367c9

ARG BASE_CONTAINER=$ROOT_CONTAINER
FROM $BASE_CONTAINER

LABEL maintainer="Koh Hashimoto <koh.hashimoto@gmail.com>"

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

############################################
# install various debs
############################################

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -q update \
 && apt-get install -yq --no-install-recommends \
    wget \
    git \
    vim \
    mg \
    lv \
    zip \
    unzip \
    screen \
    tmux \
    nodejs \
    npm \
    emacs \
    curl \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
    build-essential \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    liblzma-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libopencv-dev \
    tk-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen

############################################
# Configure environment
############################################

ENV SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV HOME=/home/$NB_USER

# Copy a script that we will use to correct permissions after running certain commands
COPY files/fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME

############################################
# jovyan
############################################

USER $NB_UID
ARG PYTHON_VERSION=default

USER $NB_UID
RUN mkdir $HOME/{mnt,tmp,.ipython,.jupyter} \
 && fix-permissions $HOME

############################################
# install juliamono font
############################################

USER $NB_UID
RUN mkdir -p $HOME/.local/share/fonts \
 && cd $HOME/.local/share/fonts \
 && wget https://github.com/cormullion/juliamono/archive/refs/heads/master.zip \
 && unzip master.zip \
 && mv juliamono-master/*ttf ./ \
 && rm -r juliamono-master master.zip \
 && fc-cache -fv

############################################
# pyenv, Jupyalab & Jupyterlab extensions
############################################

USER $NB_UID
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$HOME/.pyenv/bin:/usr/local/bin:$PATH

RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
 && echo 'export PYENV_ROOT=$HOME/.pyenv' >> ~/.profile \
 && echo 'export PATH=$PYENV_ROOT/bin:$PATH' >> ~/.profile \
 && echo 'eval "$(pyenv init -)"' >> ~/.profile \
 && echo 'eval "$(pyenv init --path)"' >> ~/.profile \
 && git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv \
 && echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.profile \
 && git clone git://github.com/yyuu/pyenv-update.git ~/.pyenv/plugins/pyenv-update

RUN eval "$(pyenv init -)" \
 && eval "$(pyenv init --path)" \
 && pyenv update \
 && pyenv install 3.8.12 \
 && eval "$(pyenv virtualenv-init -)" \
 && pyenv virtualenv 3.8.12 382py \
 && pyenv global 382py

RUN eval "$(pyenv init -)" \
 && eval "$(pyenv init --path)" \
 && eval "$(pyenv virtualenv-init -)" \
 && pyenv activate 382py \
 && pip install -U pip setuptools \
 && pip install wheel \
 && pip install jupyterlab==2.2.9 \
 && pip install dill ipykernel matplotlib numpy scipy tqdm \
 && jupyter labextension install @jupyterlab/toc --no-build \
 && jupyter labextension install @aquirdturtle/collapsible_headings --no-build \
 && jupyter labextension install @lckr/jupyterlab_variableinspector --no-build \
 && jupyter labextension install @techrah/text-shortcuts --no-build \
 && jupyter labextension install @wallneradam/trailing_space_remover --no-build \
 && jupyter labextension install jupyterlab-cell-flash --no-build \
 && jupyter labextension install jupyterlab-emacskeys --no-build \
 && jupyter labextension install jupyterlab-execute-time --no-build \
 && jupyter lab build

#######################
# mg config files
#######################

USER $NB_UID
RUN echo "make-backup-files no" >> $HOME/.mg

#######################
# screen tmux config files
#######################

USER $NB_UID
COPY files/screenrc $HOME/.screenrc
RUN echo "alias s=screen" >> $HOME/.bashrc \
 && echo "alias sx='screen -x'" >> $HOME/.bashrc

USER root
RUN fix-permissions $HOME/.screenrc

############################################
# start
############################################

USER $NB_UID
WORKDIR $HOME
