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
ARG USE_ALIYUN_MIRROR=true

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

# 安装基础工具和文档转换软件（合并为一层）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    curl \
    wget \
    git \
    build-essential \
    make \
    unzip \
    ca-certificates \
    software-properties-common \
    # 文档转换工具
    calibre \
    mupdf mupdf-tools \
    libreoffice \
    imagemagick \
    && add-apt-repository -y ppa:inkscape.dev/stable \
    && apt-get update \
    && apt-get install -y --no-install-recommends inkscape \
    # 清理缓存
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 安装 Go 语言环境
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm -f go${GO_VERSION}.linux-amd64.tar.gz

# 安装 Protobuf 编译器
RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip \
    && unzip -q protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /usr/local \
    && chmod +x /usr/local/bin/protoc \
    && rm -f protoc-${PROTOC_VERSION}-linux-x86_64.zip

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
    TZ=Asia/Shanghai

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 预安装常用的 Go 工具（可选，加速后续构建）
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@latest && \
    go install github.com/gogo/protobuf/protoc-gen-gogofaster@latest && \
    rm -rf /go/pkg/mod/cache

# 验证安装
RUN go version && protoc --version

# 设置工作目录
WORKDIR /workspace

# 默认命令
CMD ["/bin/bash"]
