# ============================================
# MoreDoc 基础开发环境镜像
# 包含：Go、Protoc、文档转换工具、中文字体等
# 不包含：项目代码
# ============================================
FROM ubuntu:22.04

# 构建参数
ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION=1.21.0
ARG PROTOC_VERSION=21.12
ARG USE_ALIYUN_MIRROR=false
ARG TARGETARCH

LABEL maintainer="MoreDoc Team" \
      description="MoreDoc 基础开发环境" \
      go.version="${GO_VERSION}" \
      protoc.version="${PROTOC_VERSION}"

# 替换镜像源（可选）
RUN if [ "${USE_ALIYUN_MIRROR}" = "true" ]; then \
      sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
      sed -i 's/ports.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
      sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    fi

# 第一步：安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    make \
    unzip \
    ca-certificates \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 第二步：安装文档转换工具（分开安装，避免依赖冲突）
RUN apt-get update && apt-get install -y --no-install-recommends \
    calibre \
    mupdf \
    mupdf-tools \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 第三步：安装 LibreOffice
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 第四步：安装 ImageMagick
RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 第五步：安装 Inkscape（从官方源，避免 PPA 问题）
RUN apt-get update && apt-get install -y --no-install-recommends \
    inkscape \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 安装 Go 语言环境（根据架构选择）
RUN ARCH="${TARGETARCH:-amd64}" && \
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && rm -f go${GO_VERSION}.linux-${ARCH}.tar.gz

# 安装 Protobuf 编译器（根据架构选择）
RUN ARCH="${TARGETARCH:-amd64}" && \
    if [ "$ARCH" = "amd64" ]; then \
      PROTOC_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
      PROTOC_ARCH="aarch_64"; \
    else \
      PROTOC_ARCH="x86_64"; \
    fi && \
    wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip \
    && unzip -q protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip -d /usr/local \
    && chmod +x /usr/local/bin/protoc \
    && rm -f protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip

# 安装中文语言包和字体
RUN apt-get update && apt-get install -y --no-install-recommends \
    language-pack-zh-hans \
    libreoffice-l10n-zh-cn \
    libreoffice-help-zh-cn \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 设置环境变量
ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/go \
    GO111MODULE=on \
    GOPROXY=https://goproxy.cn,direct \
    TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建 Go 工作目录
RUN mkdir -p /go/bin /go/pkg /go/src

# 预安装常用的 Go 工具（可选，加速后续构建）
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@latest && \
    go install github.com/gogo/protobuf/protoc-gen-gogofaster@latest && \
    rm -rf /go/pkg/mod/cache

# 验证安装
RUN go version && protoc --version && \
    echo "=== 已安装的工具版本 ===" && \
    libreoffice --version && \
    convert --version | head -n 1 && \
    inkscape --version

# 设置工作目录
WORKDIR /workspace

# 默认命令
CMD ["/bin/bash"]
