FROM ubuntu:20.04

ENV USER="root"
ENV JAVA_VERSION="8"
ENV ANDROID_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip"
ENV ANDROID_VERSION="29"
ENV ANDROID_BUILD_TOOLS_VERSION="29.0.3"
ENV ANDROID_SDK_ROOT="/home/$USER/android"
ENV ANDROID_ARCHITECTURE="x86_64"

ENV ANDROID_NDK_REV="r22"
ENV ANDROID_NDK_URL="https://dl.google.com/android/repository/android-ndk-$ANDROID_NDK_REV-linux-x86_64.zip"
ENV ANDROID_NDK_HOME="/home/$USER/android-ndk"

ENV FLUTTER_CHANNEL="stable"
ENV FLUTTER_VERSION="1.22.6"
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra/releases/$FLUTTER_CHANNEL/linux/flutter_linux_$FLUTTER_VERSION-$FLUTTER_CHANNEL.tar.xz"
ENV FLUTTER_SDK_HOME="/home/$USER/flutter"
ENV PATH="$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/platforms:$FLUTTER_SDK_HOME/bin:$HOME/.cargo/bin:$ANDROID_NDK_HOME:$PATH"

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install --yes --no-install-recommends openjdk-$JAVA_VERSION-jdk curl unzip sed git bash xz-utils libglvnd0 ssh xauth x11-xserver-utils libpulse0 libxcomposite1 libgl1-mesa-glx build-essential pkg-config libudev-dev libclang-dev libc6-dev-i386 wget \
  && rm -rf /var/lib/{apt,dpkg,cache,log}

# android sdk
RUN mkdir -p $ANDROID_SDK_ROOT \
  && mkdir -p /home/$USER/.android \
  && touch /home/$USER/.android/repositories.cfg \
  && curl -o android_tools.zip $ANDROID_TOOLS_URL \
  && unzip -qq -d "$ANDROID_SDK_ROOT" android_tools.zip \
  && rm android_tools.zip \
  && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
  && mv $ANDROID_SDK_ROOT/tools $ANDROID_SDK_ROOT/cmdline-tools/tools \
  && yes "y" | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION" \
  && yes "y" | sdkmanager "platforms;android-$ANDROID_VERSION" \
  && yes "y" | sdkmanager "platform-tools"

# Android NDK
RUN curl -o ndk.zip $ANDROID_NDK_URL \
  && mkdir -p $ANDROID_NDK_HOME \
  && unzip ndk.zip -d /tmp/ndk/ \
  && mv /tmp/ndk/*/* $ANDROID_NDK_HOME/ \
  && rm ndk.zip

# flutter
RUN curl -o flutter.tar.xz $FLUTTER_URL \
  && mkdir -p $FLUTTER_SDK_HOME \
  && tar xf flutter.tar.xz -C /home/$USER \
  && rm flutter.tar.xz \
  && flutter config --no-analytics \
  && flutter precache \
  && yes "y" | flutter doctor --android-licenses \
  && flutter doctor \
  && flutter update-packages

# Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain stable

RUN $HOME/.cargo/bin/cargo install cargo-ndk
RUN $HOME/.cargo/bin/rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

RUN rm -rf /tmp/*

RUN apt-get clean

CMD /bin/bash
