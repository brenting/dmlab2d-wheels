FROM centos:7 AS build-stage

# Set versions
ARG pythonversion=3.10.13
ARG opensslversion=1.1.1w
ARG bazelversion=6.3.2

# Install dependencies
RUN yum -y update && yum -y clean all
RUN yum -y install git wget centos-release-scl java-11-openjdk java-11-openjdk-devel zip unzip zlib-devel bzip2-devel libffi-devel
RUN yum groupinstall -y "Development Tools"
RUN yum -y install devtoolset-10
RUN echo "source /opt/rh/devtoolset-10/enable" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Download source for unavailable packages in yum
WORKDIR /usr/local/src
RUN wget https://www.python.org/ftp/python/$pythonversion/Python-$pythonversion.tar.xz
RUN wget https://www.openssl.org/source/openssl-$opensslversion.tar.gz
RUN wget https://github.com/bazelbuild/bazel/releases/download/$bazelversion/bazel-$bazelversion-dist.zip
RUN tar xvf Python-$pythonversion.tar.xz
RUN tar xvf openssl-$opensslversion.tar.gz
RUN unzip -d bazel-$bazelversion bazel-$bazelversion-dist.zip

# Install openssl from source
WORKDIR /usr/local/src/openssl-$opensslversion
RUN ./config --prefix=/usr --openssldir=/usr
RUN make
RUN make install

# Install python from source
WORKDIR /usr/local/src/Python-$pythonversion
RUN ./configure --prefix=/usr \
  --enable-shared \
  LDFLAGS="-Wl,--rpath=/usr/lib"
RUN make install

# Install bazel from source
ENV LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
WORKDIR /usr/local/src/bazel-$bazelversion
RUN env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
RUN mv /usr/local/src/bazel-$bazelversion/output/bazel /usr/local/bin/bazel

# Setup work directory
WORKDIR /home
RUN python3 -m venv .venv
ENV PATH=/home/.venv/bin:$PATH
RUN pip install --upgrade pip && pip install --upgrade setuptools wheel

# Download and run install-dmlab2d script to obtain dmlab2d wheel
RUN wget https://raw.githubusercontent.com/google-deepmind/meltingpot/v2.1.1/install-dmlab2d.sh
RUN chmod +x install-dmlab2d.sh
RUN ./install-dmlab2d.sh

# Copy wheel to empty image for export
FROM scratch AS export-stage
COPY --from=build-stage /home/lab2d/bazel-bin/dmlab2d/*.whl /
