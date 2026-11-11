/**
 * Statusline — 增强版状态栏
 *
 * 一行显示：工作目录 + git 工作树/branch · token 统计 · 上下文进度条 · 模型 · 思考档位
 *
 * 数据来源：
 *   footerData.getGitBranch()      git branch（含 worktree，Pi 自己向上找 .git）
 *   footerData.onBranchChange()    branch 变更时重绘
 *   ctx.getContextUsage()          上下文 token / 窗口 / 百分比
 *   ctx.sessionManager.getBranch() token 与成本累计
 *   ctx.model                     模型 id / provider / reasoning / contextWindow
 *
 * 用法：/statusline 切换开/关（默认关闭，保持 Pi 原生 footer）
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

/** 紧凑 token 数字 */
function fmt(n: number): string {
	if (n < 1000) return String(n);
	if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1000000) return `${Math.round(n / 1000)}k`;
	if (n < 10000000) return `${(n / 1000000).toFixed(1)}M`;
	return `${Math.round(n / 1000000)}M`;
}

/** 把 home 缩成 ~ */
function shortPath(p: string): string {
	const home = process.env.HOME || process.env.USERPROFILE;
	if (home && p.startsWith(home)) return "~" + p.slice(home.length);
	return p;
}

/** 上下文进度条 */
function bar(percent: number, width: number): string {
	const filled = Math.max(0, Math.min(width, Math.round((percent / 100) * width)));
	return "█".repeat(filled) + "░".repeat(width - filled);
}

/** 思考档位简写 */
const THINK_LABEL: Record<string, string> = {
	off: "–",
	minimal: "min",
	low: "low",
	medium: "med",
	high: "high",
	xhigh: "xhi",
	max: "max",
};

export default function (pi: ExtensionAPI) {
	let enabled = true;

	const install = (ctx: any) => {
		ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
			// branch 变化时重绘
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const model = ctx.model;
					const usage = ctx.getContextUsage();

					// ---- 累计 token / 成本 ----
					let input = 0,
						output = 0,
						cacheRead = 0,
						cacheWrite = 0,
						cost = 0;
					try {
						for (const e of ctx.sessionManager.getBranch()) {
							if (e.type === "message" && e.message.role === "assistant") {
								const m = e.message as AssistantMessage;
								const u: any = m.usage;
								if (!u) continue;
								input += u.input ?? 0;
								output += u.output ?? 0;
								cacheRead += u.cacheRead ?? 0;
								cacheWrite += u.cacheWrite ?? 0;
								cost += u.cost?.total ?? 0;
							}
						}
					} catch {
						/* session 还没就绪 */
					}

					// ---- 左：工作目录 + 工作树/branch ----
					let left = theme.fg("dim", shortPath(ctx.cwd));
					const branch = footerData.getGitBranch();
					if (branch) {
						left += theme.fg("muted", " ") + theme.fg("accent", `⎇ ${branch}`);
					}

					// ---- 中：token 统计 ----
					const parts: string[] = [];
					if (input) parts.push(theme.fg("muted", `↑${fmt(input)}`));
					if (output) parts.push(theme.fg("muted", `↓${fmt(output)}`));
					if (cacheRead) parts.push(theme.fg("dim", `R${fmt(cacheRead)}`));
					if (cost) parts.push(theme.fg("muted", `$${cost.toFixed(3)}`));

					// ---- 上下文进度条 ----
					const win = usage?.contextWindow ?? model?.contextWindow ?? 0;
					const pct = usage?.percent;
					if (win > 0) {
						if (pct == null) {
							parts.push(theme.fg("dim", `[${bar(0, 8)}] ?/${fmt(win)}`));
						} else {
							const tone = pct > 90 ? "error" : pct > 70 ? "warning" : "success";
							parts.push(
								theme.fg(tone, `[${bar(pct, 8)}]`) +
									theme.fg(pct > 70 ? tone : "muted", ` ${pct.toFixed(0)}%/${fmt(win)}`),
							);
						}
					}

					// ---- 右：模型 + provider + 思考档位 ----
					let right = theme.fg("accent", model?.id || "no-model");
					if (model?.provider) right += theme.fg("dim", ` @${model.provider}`);
					if (model?.reasoning) {
						const lvl = (ctx as any).thinkingLevel ?? "off";
						right += theme.fg("dim", " · ") + theme.fg("warning", THINK_LABEL[lvl] ?? lvl);
					}

					// ---- 左对齐依次排开：工作树 | token | 上下文 | 模型 ----
					const segs = [left];
					if (parts.length) segs.push(parts.join(theme.fg("dim", " ")));
					segs.push(right);
					const sep = theme.fg("dim", "  ");
					return [truncateToWidth(segs.join(sep), width, "…")];
				},
			};
		});
	};

	pi.registerCommand("statusline", {
		description: "切换增强状态栏 (工作树/模型/上下文)",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				install(ctx);
				ctx.ui.notify("增强状态栏已开启", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("已恢复 Pi 原生状态栏", "info");
			}
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		if (enabled) install(ctx);
	});
}
