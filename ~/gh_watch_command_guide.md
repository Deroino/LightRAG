# “监控最新 GitHub Actions 工作流”命令说明

## 命令

```bash
gh run watch $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --exit-status
```

## 功能

此命令用于在终端中实时监控项目最新触发的一次 GitHub Actions 工作流的运行过程和结果。

## 命令分解

1.  `gh run list --limit 1 --json databaseId -q '.[0].databaseId'`
    *   这部分负责 **获取最新工作流的 ID**。
    *   `gh run list --limit 1`: 列出最近的 1 次工作流。
    *   `--json databaseId -q '.[0].databaseId'`: 以 JSON 格式输出该工作流的 ID，并提取出纯净的 ID 值。

2.  `gh run watch <ID>`
    *   这是核心的 **监控命令**，它接收一个工作流 ID，并在终端实时显示其运行状态。

3.  `--exit-status`
    *   这是一个非常有用的标志，它使 `watch` 命令在工作流结束后，以 **与工作流相同的状态码退出** (成功为 0，失败为非 0)。这对于自动化脚本判断执行结果至关重要。

4.  `$(...)`
    *   这是 Shell 的 **命令替换** 语法，它将第一部分的命令输出（即获取到的 ID）作为 `gh run watch` 命令的输入参数。
