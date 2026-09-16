FROM debian:12 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV XMAKE_ROOT=y

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        pkg-config \
        git \
        ca-certificates \
        unzip \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://xmake.io/shget.text | bash

WORKDIR /src
COPY . /src
RUN source /root/.xmake/profile \
    && xmake config -y -m release \
    && xmake -y -j 1 \
    && xmake install -y -o /src/package

FROM debian:12-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=container
ENV HOME=/home/container

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libstdc++6 \
        libgcc-s1 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -d /home/container -s /bin/bash container

COPY --from=builder --chown=container:container \
    /src/package/lib/libSTServer.so \
    /src/package/bin/crashpad_handler \
    /src/package/bin/SkyrimTogetherServer \
    /opt/skyrim-together/

RUN chmod +x \
    /opt/skyrim-together/SkyrimTogetherServer \
    /opt/skyrim-together/crashpad_handler

USER        container
ENV         USER=container HOME=/home/container
ENV         PATH="/opt/skyrim-together:${PATH}"
ENV         LD_LIBRARY_PATH="/opt/skyrim-together"
WORKDIR     /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/opt/skyrim-together/SkyrimTogetherServer"]