FROM ghcr.io/swiftwasm/swift:5.3-focal

LABEL maintainer="SwiftWasm Maintainers <hello@swiftwasm.org>"
LABEL Description="Carton is a watcher, bundler, and test runner for your SwiftWasm apps"
LABEL org.opencontainers.image.source https://github.com/swiftwasm/carton

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    libsqlite3-0 \
    libsqlite3-dev \
    curl unzip \
  && export WASMER_DIR=/usr/local && curl https://get.wasmer.io -sSfL | sh && \
  rm -r /var/lib/apt/lists/*

ENV CARTON_ROOT=/root/.carton
ENV CARTON_DEFAULT_TOOLCHAIN=wasm-5.3.1-RELEASE

RUN mkdir -p $CARTON_ROOT/sdk && \
  mkdir -p $CARTON_ROOT/sdk/$CARTON_DEFAULT_TOOLCHAIN && \
  ln -s /usr $CARTON_ROOT/sdk/$CARTON_DEFAULT_TOOLCHAIN/usr

COPY . carton/

RUN cd carton && \
  ./install_ubuntu_deps.sh && \
  swift build -c release && \
  cd TestApp && ../.build/release/carton test && cd .. && \
  mv .build/release/carton /usr/bin && \
  cd .. && \
  rm -rf carton /tmp/wasmer*

# Set the default command to run
CMD ["carton --help"]
