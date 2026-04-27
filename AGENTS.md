# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 项目概述

ChanStock — 缠论智能股票分析系统，基于缠中说禅理论的 A 股技术分析工具，支持 PC 端与移动端。

## 常用命令

### 后端 (FastAPI)

```bash
# 启动后端服务
cd backend && python run_server.py

# 或直接运行
cd backend && python main.py

# API 文档: http://localhost:8000/docs
# 健康检查: http://localhost:8000/health
```

### 前端 (Vue 3 + Vite)

```bash
# 安装依赖
cd frontend && npm install

# 启动开发服务器
cd frontend && npm run dev

# 生产构建
cd frontend && npm run build

# 访问: http://localhost:5173
# 移动端: http://localhost:5173/m/
```

## 架构概览

```
backend/
├── main.py              # FastAPI 入口，所有 REST 路由
├── chanlun/             # 缠论核心算法
│   ├── engine.py        # 缠论引擎（整合分析步骤）
│   ├── elements.py      # Pydantic 数据模型
│   ├── fenxing_detector.py   # 分型检测
│   ├── bi_detector.py        # 笔检测
│   ├── segment_detector.py   # 线段 & 中枢检测
│   └── signals.py            # 买卖点判定
├── ai/                  # AI 增强模块
│   ├── llm_client.py    # LLM 客户端 (DeepSeek/Gemini)
│   ├── analysis_agent.py     # Prompt 构建
│   ├── strategy_engine.py    # 规则策略引擎
│   └── divergence.py    # 背驰检测
└── services/
    ├── akshare_service.py    # 多源数据（东财/腾讯/新浪降级）
    └── screening_service.py  # 选股服务（SSE 流式）

frontend/
├── src/
│   ├── api/stock.ts     # API 调用 + TypeScript 类型
│   ├── stores/          # Pinia 状态管理
│   ├── views/           # PC 页面
│   ├── mobile/          # 移动端页面和组件
│   └── components/      # 共享组件（图表、信号卡片等）
└── vite.config.ts       # 代理到后端 8000
```

## 核心模块依赖

- **缠论分析链**: `ChanlunEngine` → `FenxingDetector` → `BiDetector` → `SegmentDetector` → `signals.py`
- **AI 分析链**: `llm_client.py` → `analysis_agent.py` → `strategy_engine.py` + `divergence.py`
- **数据获取**: `akshare_service.py` 提供多源降级（东财 → 腾讯 → 新浪）

## K 线级别参数

`level` 参数支持: `1min` `5min` `15min` `30min` `60min` `daily` `weekly` `monthly`

## 环境变量

后端 `.env` 文件（可选，无 AI Key 时仍可运行纯规则模式）:

```env
DEEPSEEK_API_KEY=sk-xxxxx
GEMINI_API_KEY=AIzaSyxxxxx
```

## 端口配置

| 服务 | 端口 |
|------|------|
| 前端 | 5173 |
| 后端 API | 8000 |

前端通过 Vite proxy 自动转发 `/api` 到后端。


<claude-mem-context>
# Memory Context

# [stock-chanlun] recent context, 2026-04-27 9:18pm GMT+8

No previous sessions found.
</claude-mem-context>