## Important Guidelines

- 未得到用户允许，不允许私自撰写文档
- 未得到用户允许，不允许自行推送代码

## Project Notes

- @webui_build.sh @lightrag_webui/ 前端项目路径为上述路径，当前端进行修改时，使用该脚本进行重新构建以确保生效

## Workflow Procedures

- 使用 ./auto-test-fix.sh 重启项目时的工作流程：
  - 执行 ./auto-test-fix.sh 脚本
  - 等待10秒钟
  - 查看日志检查项目是否成功启动
  - 等待用户反馈
  - 如果用户报告问题：
    - 首先检查 auto-test-fix.log 是否有错误
    - 如有错误，进行深入分析原因
    - 提供思考结果和修改方案给用户
    - 等待用户反馈
  - 修改完毕后，重新执行 ./auto-test-fix.sh