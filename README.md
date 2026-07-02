# MediaPipe AutoFlip Docker

Run Google MediaPipe AutoFlip in Docker to reframe videos for a target aspect ratio, such as turning landscape video into `9:16` vertical output.

This repo builds MediaPipe AutoFlip from source, packages the binary into a smaller runtime image, and mounts `./videos` as the working directory.

## Requirements

- Docker
- Docker Compose (optional)
- Enough disk space and time for a MediaPipe/Bazel build

## Build

Using Docker directly:

```sh
docker build -t autoflip .
```

Or with Docker Compose:

```sh
docker compose build
```

The first build downloads Bazel and MediaPipe, then compiles AutoFlip. It can take a while.

## Usage

Put videos in `./videos`, then run:

Using Docker directly:

```sh
docker run --rm -v "$PWD/videos:/work" autoflip input.mp4 output_9x16.mp4 9:16
```

Or with Docker Compose:

```sh
docker compose run --rm autoflip input.mp4 output_9x16.mp4 9:16
```

Arguments:

```text
input video path   default: /work/input.mp4
output video path  default: /work/output.mp4
aspect ratio       default: 9:16
```

Because `./videos` is mounted to `/work`, use filenames relative to the `videos` directory:

```sh
docker compose run --rm autoflip vid1.mp4 vid1_9x16.mp4 9:16
docker compose run --rm autoflip vid3.webm vid3_16x9.mp4 16:9
```

## What It Does

AutoFlip analyzes the video, detects important visual content, and crops/reframes frames to fit the requested aspect ratio.

Useful for:

- Converting landscape videos to vertical clips
- Preparing videos for Shorts, Reels, TikTok, or mobile feeds
- Batch-testing MediaPipe AutoFlip without installing Bazel locally

## Notes

- The image uses MediaPipe `v0.8.11` and Bazel `5.2.0`.
- The Dockerfile uses Debian Buster archive repositories because the build depends on older packages.
- Output quality depends on AutoFlip detection. Always review the result before publishing.
