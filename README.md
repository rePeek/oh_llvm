# OpenHarmony LLVM Development Workspace

这是一个用于拉取、准备、构建和测试 OpenHarmony LLVM 工具链的开发工作区。仓库本身只跟踪工作区脚手架；OpenHarmony 源码、预编译依赖和构建产物通过 `repo`、辅助脚本和构建命令生成。

## 仓库内容

- `flake.nix`：Nix 开发环境，提供源码同步、prebuilts 准备、Docker 构建入口和常用开发工具。
- `.envrc`：direnv 入口，自动加载 `nix develop` 环境。
- `justfile`：常用构建、安装和测试命令。
- `docker-compose.yml`：Ubuntu 22.04 容器化构建环境。
- `docker/Dockerfile.ubuntu22`：构建镜像定义。
- `scripts/`：源码同步、环境准备和清理脚本。

`base/`、`build/`、`prebuilts/`、`third_party/`、`toolchain/`、`out/` 等目录由 OpenHarmony `repo sync` 或构建流程生成，不作为本仓库源码提交。

## 环境要求

通用要求：

- Nix flakes
- direnv，可选
- Git LFS

如果当前机器还没有安装 Nix，可以使用 Determinate Systems 安装器：

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

进入本地开发环境：

```bash
nix develop
```

如果启用了 direnv：

```bash
direnv allow
```

开发环境会提供以下工具和辅助命令：

- `ohos-fetch-source [branch]`
- `ohos-env-prepare`
- `ohos-clean-out --force`
- `ohos-clean-all --force`
- `just`
- `clangd`、`clang-format`、`clang-tidy`
- `lldb`

Docker 构建还需要：

- Docker
- Docker Compose

## 快速开始

先准备源码和 prebuilts，然后在 Docker 中构建。

1. 进入开发环境：

```bash
nix develop
```

2. 拉取 OpenHarmony LLVM 源码，默认分支为 `master`：

```bash
ohos-fetch-source
```

指定分支：

```bash
ohos-fetch-source OpenHarmony-6.0-Release
```

该命令会执行：

- `repo init -u https://gitcode.com/OpenHarmony/manifest.git -m llvm-toolchain.xml`
- `repo sync -c`
- `repo forall -c 'git lfs pull'`
- 在缺少核心 prebuilts 时运行 `toolchain/llvm-project/llvm-build/env_prepare.sh`

### Docker 构建

Docker 构建也从 `nix develop` shell 中发起。Nix 环境负责提供 `just` 和工作区辅助命令；实际编译会进入 `docker/Dockerfile.ubuntu22` 创建的 Ubuntu 22.04 容器，并把当前仓库挂载到容器的 `/workspace`。

先构建 Docker 镜像：

```bash
just build-image
```

构建 Linux x86_64 LLVM 工具链：

```bash
just build-x86
```

默认构建模式为 `strip`。调试模式：

```bash
just build-x86 debug
```

构建 OHOS aarch64 工具链：

```bash
just build-ohos
```

运行 LLDB 测试：

```bash
just lldb-ut
```

## 常用命令

查看全部 `just` 命令：

```bash
just --list
```

| 命令 | 用途 |
| --- | --- |
| `just build-image` | 构建 Ubuntu 22.04 Docker 构建镜像 |
| <code>just build-x86 [strip&#124;debug]</code> | 在 Docker 中构建 Linux x86_64 工具链 |
| `just build-x86-lldb-debug` | 在 Docker 中构建 Debug 版 LLDB |
| `just build-ohos` | 在 Docker 中构建 OHOS aarch64 工具链 |
| `just lldb-ut` | 在 Docker 中运行 LLDB Unit、Shell 和 API 测试 |
| `just ninja-install-linux [targets...]` | 在 `out/llvm_make` 中执行 install 或指定 Ninja target |
| `just ninja-install-windows [targets...]` | 在 `out/windows-x86_64` 中执行 install 或指定 Ninja target |
| `just ninja-install-ohos [targets...]` | 在 `out/ohos-aarch64` 中执行 install 或指定 Ninja target |
| `just ninja-install-static-lldb` | 安装静态 LLDB server 相关 target |

## 构建产物和日志

- 构建产物默认写入 `out/`。
- 构建和测试日志写入 `log/`，文件名带时间戳。
- Docker 构建容器将仓库挂载到 `/workspace`，并以当前用户的 `UID:GID` 运行。

## 本地源码布局

默认 LLVM 项目路径为：

```bash
toolchain/llvm-project
```

如果使用了不同源码布局，可以通过环境变量覆盖：

```bash
LLVM_PROJECT=/path/to/llvm-project just build-x86
```

相关脚本和命令都会优先读取 `LLVM_PROJECT`，未设置时使用默认路径。

## 清理

只清理构建产物：

```bash
ohos-clean-out --force
```

清理通过 `repo` 同步出来的源码树、prebuilts 和构建产物：

```bash
ohos-clean-all --force
```

`ohos-clean-all --force` 会删除 `.repo`、`toolchain/`、`prebuilts/`、`third_party/`、`out/` 等目录。执行前确认本地源码改动已经备份或提交。

## 注意事项

- `ohos-fetch-source` 会写入 Git 用户名和邮箱配置，并执行 Git LFS 拉取。
- Nix dev shell 首次进入时会下载 `repo` 命令到 `.nix-dev/bin/repo`。
- Nix dev shell 不再提供完整宿主机编译依赖；默认编译路径是 Docker。`just *-local` 命令仍保留在 `justfile` 中，但需要自行准备对应编译工具链和依赖。
- Dockerfile 使用清华 Ubuntu 镜像源，适合国内网络环境。
- `out/`、源码树和 prebuilts 体积较大，已通过 `.gitignore` 排除。
