FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG JDK_VERSION=11

RUN apt update && apt install -y curl git unzip xz-utils zip libglu1-mesa openjdk-${JDK_VERSION}-jdk wget tzdata

RUN ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
RUN echo "Asia/Jakarta" > /etc/timezone

RUN dpkg-reconfigure --frontend noninteractive tzdata

# Setup user
ARG USERNAME=ipan97
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME

ENV HOME /home/${USERNAME}
WORKDIR ${HOME}

# Setup android home
ENV ANDROID_HOME $HOME/Android/sdk
ENV ANDROID_SDK_ROOT $ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator
RUN mkdir -p ${ANDROID_SDK_ROOT}
ENV PATH "$PATH:${ANDROID_SDK_ROOT}"
RUN mkdir -p ${HOME}/.android && touch ${HOME}/.android/repositories.cfg

# Setup android command line tools
RUN wget -O sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip
RUN unzip -q sdk-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && rm sdk-tools.zip
RUN mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest
ENV PATH "$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin"

ENV ANDROID_PLATFORM_VERSION 30
ENV ANDROID_BUILD_TOOLS_VERSION 30.0.2

RUN sdkmanager --licenses
RUN yes | sdkmanager \
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
ENV PATH "$PATH:${ANDROID_SDK_ROOT}/platform-tools"

# Setup flutter sdk
ENV FLUTTER_HOME ${HOME}/flutter
ENV FLUTTER_VERSION 2.2.3
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}
ENV PATH "${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin"
RUN yes | flutter doctor --android-licenses \
    && flutter doctor -v

# Build flutter
COPY . ${HOME}/app
RUN sudo chown -R ${USERNAME} ${HOME}/app

WORKDIR ${HOME}/app

RUN flutter clean && \
    flutter pub get
RUN flutter build apk --split-per-abi --debug --flavor develop