FROM debian:10 AS builder

ARG MEDIAPIPE_VERSION=v0.8.11
ARG BAZEL_VERSION=5.2.0
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON_BIN_PATH=/usr/bin/python3

RUN printf '%s\n' \
    'deb http://archive.debian.org/debian buster main' \
    'deb http://archive.debian.org/debian-security buster/updates main' \
    > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    libopencv-calib3d-dev \
    libopencv-core-dev \
    libopencv-features2d-dev \
    libopencv-highgui-dev \
    libopencv-imgcodecs-dev \
    libopencv-imgproc-dev \
    libopencv-video-dev \
    libopencv-videoio-dev \
    pkg-config \
    python3 \
    python3-dev \
    python3-numpy \
    python3-pip \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN curl -L -o /tmp/bazel-installer.sh \
    "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" \
    && chmod +x /tmp/bazel-installer.sh \
    && /tmp/bazel-installer.sh \
    && rm /tmp/bazel-installer.sh

WORKDIR /opt
RUN git clone --branch "${MEDIAPIPE_VERSION}" --depth 1 https://github.com/google/mediapipe.git

WORKDIR /opt/mediapipe
RUN sed -i '/face_detection_full_range_sparse.tflite/a\
        "//mediapipe/models:ssdlite_object_detection.tflite",\
        "//mediapipe/models:ssdlite_object_detection_labelmap.txt",' \
    mediapipe/examples/desktop/autoflip/BUILD

RUN bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 \
    mediapipe/examples/desktop/autoflip:run_autoflip

RUN mkdir -p /opt/autoflip \
    && cp -a bazel-bin/mediapipe/examples/desktop/autoflip/run_autoflip /opt/autoflip/ \
    && cp -aL bazel-bin/mediapipe/examples/desktop/autoflip/run_autoflip.runfiles /opt/autoflip/ \
    && mkdir -p /opt/autoflip/run_autoflip.runfiles/mediapipe/mediapipe/examples/desktop/autoflip \
    && cp -a mediapipe/examples/desktop/autoflip/autoflip_graph.pbtxt \
        /opt/autoflip/run_autoflip.runfiles/mediapipe/mediapipe/examples/desktop/autoflip/

FROM debian:10-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN printf '%s\n' \
    'deb http://archive.debian.org/debian buster main' \
    'deb http://archive.debian.org/debian-security buster/updates main' \
    > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libopencv-calib3d3.2 \
    libopencv-core3.2 \
    libopencv-features2d3.2 \
    libopencv-highgui3.2 \
    libopencv-imgcodecs3.2 \
    libopencv-imgproc3.2 \
    libopencv-video3.2 \
    libopencv-videoio3.2 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/autoflip /opt/autoflip

RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'INPUT="${1:-/work/input.mp4}"' \
    'OUTPUT="${2:-/work/output.mp4}"' \
    'ASPECT_RATIO="${3:-9:16}"' \
    'cd /opt/autoflip/run_autoflip.runfiles/mediapipe' \
    'GLOG_logtostderr=1 /opt/autoflip/run_autoflip \' \
    '  --calculator_graph_config_file=mediapipe/examples/desktop/autoflip/autoflip_graph.pbtxt \' \
    '  --input_side_packets=input_video_path="${INPUT}",output_video_path="${OUTPUT}",aspect_ratio="${ASPECT_RATIO}"' \
    > /usr/local/bin/run_autoflip.sh \
    && chmod +x /usr/local/bin/run_autoflip.sh /opt/autoflip/run_autoflip

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/run_autoflip.sh"]
