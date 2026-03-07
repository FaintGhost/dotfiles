# Task Plan

## Goal

- 提升 `chezmoi` 模板验证的可信度，避免“看起来通过、实际未校验”的情况
- 提升安装脚本失败时的可见性和可诊断性，避免失败后继续输出成功信息
- 降低配置对单一发行版、单一主机路径和单一用户环境的耦合

## Batch 1 - 验证链路加固（P0）

- [x] 重写 `run_before_validate-templates.sh.tmpl` 的验证逻辑
  - 对模板文件执行真实渲染校验，而不是仅判断是否包含模板标记
  - 对渲染后的 shell 脚本追加 `bash -n` 语法校验
  - 删除对不存在文件 `.chezmoiexternal.toml.tmpl` 的伪校验
  - 验证：`chezmoi execute-template` 校验通过，校验脚本在模板损坏时能非零退出

- [x] 明确校验脚本覆盖范围
  - 盘点当前需要验证的模板、脚本和配置文件
  - 保证新增模板后只需在一处维护校验清单
  - 验证：新增或删除受管模板时，校验脚本不会出现永久性“跳过”误导

## Batch 2 - 安装脚本失败即停（P0）

- [ ] 统一 `run_onchange` 脚本的失败策略
  - 为 `.chezmoiscripts/run_onchange_100-system-packages.sh.tmpl`、`.chezmoiscripts/run_onchange_200-mise.sh.tmpl`、`.chezmoiscripts/run_onchange_300-font-cache.sh.tmpl` 增加严格模式
  - 关键步骤改为失败即退出，不再在局部失败后继续输出整体完成
  - 验证：人为制造失败场景时脚本返回非零，并保留足够的错误信息

- [ ] 优化 `.chezmoitemplates/script-utils.sh` 的错误输出策略
  - 保留成功场景下的简洁输出
  - 在失败场景下输出关键 stderr 或日志路径，便于定位问题
  - 验证：APT、curl、unzip 任一失败时，终端可见明确失败原因

## Batch 3 - 跨发行版与声明式安装优化（P1）

- [ ] 重构 `.chezmoidata/packages.yaml` 的结构
  - 从“所有 Linux 都走 APT”调整为“按 `osid` 或包管理器分层”
  - 为后续 Debian/Ubuntu 之外的环境预留扩展位
  - 验证：模板渲染时可根据 `.chezmoi.os` / `.data.osid` 选择正确安装命令

- [ ] 调整系统包安装脚本的分发逻辑
  - 让 `.chezmoiscripts/run_onchange_100-system-packages.sh.tmpl` 根据数据层决定包管理器和包列表
  - 保持 Debian 系列当前行为不回归
  - 验证：在当前环境渲染结果与现状兼容；切换模拟 `osid` 时能得到预期命令

## Batch 4 - 工具链版本与幂等性（P1）

- [ ] 明确 `mise` 的安装与更新语义
  - 决定它应是“一次性安装脚本”还是“声明式版本受控脚本”
  - 若保留更新能力，需把版本或渠道声明进 data，确保变更能触发重跑
  - 补上 `mise install` 的执行时机，避免只声明工具但不安装
  - 验证：新主机首装可装齐工具；版本或渠道变化后可触发预期更新

- [ ] 为字体安装引入版本意识
  - 把 Nerd Fonts 版本放入数据层，不再依赖 GitHub `latest`
  - 本地落版本标记，避免“目录存在即认为已安装”的误判
  - 验证：版本不变时幂等；版本提升时能重新下载并刷新缓存

## Batch 5 - 可移植性与开发体验（P2）

- [ ] 清理 `dot_bashrc.tmpl` 中的主机耦合项
  - 修正 `alias p=alias p='...'` 的可读性问题
  - 将代理地址、`TERM` 策略等改为按主机或环境数据渲染
  - 为 `cz apply` 增加“不会拉远端更新”的显式提示，或新增 `czu`/`cz sync` 包装
  - 验证：新 shell 启动无报错；跨主机不会错误复用固定代理和终端设置

- [ ] 清理 `dot_gitconfig.tmpl` 与 `dot_config/mise/config.toml` 的路径/用户耦合
  - 将 `gh` 凭据助手从硬编码 `/usr/bin/gh` 改为依赖 `PATH`
  - 将 `GOPATH` 改为基于 `{{ .chezmoi.homeDir }}` 渲染，而不是固定 `/root/...`
  - 评估 Git 用户信息是否应迁移到 data 层按主机渲染
  - 验证：非 root 用户、不同发行版与不同 `gh` 安装路径下均能正常工作

## Out Of Scope

- 暂不改动 `nvim` 相关配置与插件管理逻辑
- 暂不引入新的外部安装器或大规模重构目录结构
- 暂不处理纯审美类提示符主题调整

## Recommended Order

- [x] 先执行 Batch 1
- [ ] 再执行 Batch 2
- [ ] 确认当前 Debian/Linux 路径稳定后推进 Batch 3 和 Batch 4
- [ ] 最后收尾 Batch 5 的可移植性细节

## Review

- 已将校验逻辑收敛到 `run_before_validate-templates.sh.tmpl` 的两组集中清单，避免重复散落在多处调用中
- 已用 `chezmoi execute-template --file` 对 8 个关键模板做真实渲染校验
- 已对 5 个 shell 模板在渲染后追加 `bash -n` 校验
- 已移除对不存在 `.chezmoiexternal.toml.tmpl` 的伪校验
- 已验证成功路径：渲染后的 `validate-templates.sh` 在当前仓库通过并返回 0
- 已验证失败路径：临时破坏 `dot_gitconfig.tmpl` 后，校验脚本能显示模板错误并返回非零
