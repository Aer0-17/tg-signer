FROM python:3.12-slim AS builder

# 使用正确的 Debian 源配置方式
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 先更新并安装基础依赖，再安装构建工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    pkg-config \
    && apt-get clean

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple && \
    mkdir -p build && \
    pip wheel -w build tgcrypto

FROM python:3.12-slim
COPY --from=builder /build/*.whl /tmp/

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple && \
    pip install /tmp/*.whl && \
    pip install -U "tg-signer[tgcrypto]" && \
    rm -rf /tmp/*.whl

WORKDIR /opt/tg-signer
