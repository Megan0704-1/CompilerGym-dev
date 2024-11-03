FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
	tmux \
	vim \
	git \
	wget \
	build-essential \
	curl \
	make \
	cmake \
	tar \
	bzip2 \
	ninja-build

RUN apt-get update && apt-get install -y \
	clang \
	clang-format \
	golang \
	libjpeg-dev \
	libtinfo5 \
	m4 \
	patch \
	zlib1g-dev \
	libtool \
	autoconf \
	ccache \
	lld \
	python3-pip \
	gcc \
	llvm \
	llvm-dev

ENV CC=clang
ENV CXX=clang++

# bazelisk & hadolint
RUN mkdir -p /usr/local/bin && \
	wget https://github.com/bazelbuild/bazelisk/releases/download/v1.7.5/bazelisk-linux-amd64 -O /usr/local/bin/bazel && \
	wget https://github.com/hadolint/hadolint/releases/download/v1.19.0/hadolint-Linux-x86_64 -O /usr/local/bin/hadolint && \
	chmod +x /usr/local/bin/bazel /usr/local/bin/hadolint

# Install Go
RUN wget https://golang.org/dl/go1.16.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.16.7.linux-amd64.tar.gz && \
    rm go1.16.7.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

# builderfier & prototool
RUN go install github.com/bazelbuild/buildtools/buildifier@latest && \
    GO111MODULE=on go install github.com/uber/prototool/cmd/prototool@dev

# miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
	    /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
	    rm /tmp/miniconda.sh && \
	    /opt/conda/bin/conda clean -all

ENV PATH=/opt/conda/bin:$PATH

RUN conda create -y -n compiler_gym python=3.8 cmake doxygen pandoc patchelf -c conda-forge
RUN /opt/conda/bin/conda run -n compiler_gym pip install --upgrade pip \
	'setuptools<58.0.0' \
	'pip==20.3.4' \
	'wheel==0.36.2'

# copmilergym
RUN git clone https://github.com/facebookresearch/CompilerGym.git /CompilerGym

WORKDIR /CompilerGym
RUN /opt/conda/bin/conda run -n compiler_gym bash -c "make dev-init"
RUN /opt/conda/bin/conda run -n compiler_gym bash -c "make install"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
