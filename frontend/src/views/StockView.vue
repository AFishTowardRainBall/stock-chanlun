<template>
  <div class="layout">
    <nav class="nav">
      <div class="nav-inner nav-inner--stock">
        <div class="nav-left">
          <div class="nav-links">
            <router-link to="/" class="nav-link">首页</router-link>
            <router-link to="/screen" class="nav-link">选股</router-link>
            <router-link to="/watchlist" class="nav-link">自选股</router-link>
          </div>
        </div>

        <div class="stock-topline" :class="{ 'stock-topline--ready': !!headerQuote }">
          <div class="stock-topline-main">
            <span class="stock-code mono">{{ headerQuote ? stockCode : '--' }}</span>
            <span class="stock-name">{{ headerQuote?.name || '加载中' }}</span>
            <span class="stock-price mono">{{ headerQuote?.price != null ? headerQuote.price.toFixed(2) : '--.--' }}</span>
            <span class="stock-change mono" :class="headerQuote ? changeClass : 'stock-change--placeholder'">
              {{ headerQuote ? `${changeAmountText} ${changeText}` : '--.-- --.--%' }}
            </span>
          </div>
          <div class="stock-topline-stats">
            <span class="top-stat"><b>开</b>{{ headerQuote ? statPrice(headerQuote.open) : '--.--' }}</span>
            <span class="top-stat"><b>高</b><span :class="headerQuote ? 'price-up' : 'stock-change--placeholder'">{{ headerQuote ? statPrice(headerQuote.high) : '--.--' }}</span></span>
            <span class="top-stat"><b>低</b><span :class="headerQuote ? 'price-down' : 'stock-change--placeholder'">{{ headerQuote ? statPrice(headerQuote.low) : '--.--' }}</span></span>
            <span class="top-stat"><b>量</b>{{ headerQuote ? formatVolume(headerQuote.volume) : '--' }}</span>
          </div>
        </div>

        <div class="nav-actions">
          <div class="trend-capsule">
            <span class="trend-pill" :class="trendClass">{{ store.chanlunResult?.trend || '待分析' }}</span>
            <div class="signal-dots" aria-label="缠论信号状态">
              <span
                v-for="dot in toolbarSignalDots"
                :key="dot.key"
                class="signal-dot"
                :class="`signal-dot--${dot.tone}`"
                :title="dot.label"
              />
            </div>
          </div>

          <div class="level-tabs nav-level-tabs">
            <button
              v-for="lv in levels"
              :key="lv.value"
              class="level-tab"
              :class="{ active: currentLevel === lv.value }"
              @click="changeLevel(lv.value)"
            >{{ lv.label }}</button>
          </div>

          <!-- <div class="ai-model-switch">
            <button
              class="model-btn"
              :class="{ active: store.aiModel === 'deepseek' }"
              @click="switchModel('deepseek')"
              title="DeepSeek"
            >DS</button>
            <button
              class="model-btn"
              :class="{ active: store.aiModel === 'gemini' }"
              @click="switchModel('gemini')"
              title="Gemini"
            >GM</button>
          </div> -->
          <button class="btn btn-ghost" @click="loadData" :disabled="loadingAny">
            {{ loadingAny ? '加载中...' : '刷新' }}
          </button>
          <button
            class="btn btn-ghost"
            @click="toggleWatch"
            :class="{ 'btn-danger': isWatching, 'btn-loading': watchToggling }"
            :disabled="loadingAny || watchToggling"
          >
            <span v-if="watchToggling" class="btn-spinner" />
            <span v-else>{{ isWatching ? '取消自选' : '+自选' }}</span>
          </button>
        </div>
      </div>
    </nav>

    <div v-if="loadingAny" class="loading-overlay">
      <div class="loading-progress">
        <span>加载 K 线数据...</span>
        <div class="spinner" />
      </div>
    </div>

    <div v-else-if="error" class="error-page">
      <div class="error-icon">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
      </div>
      <p class="error-message">{{ error }}</p>
      <button class="btn btn-primary" @click="loadData">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="23 4 23 10 17 10" /><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
        </svg>
        重试（R键）
      </button>
    </div>

    <div v-else class="workspace">
      <div class="workspace-main">
        <div class="chart-shell">
          <div class="chart-header card">
            <div class="chart-header-left">
              <div class="date-filter" :class="{ 'has-filter': startDate || endDate }">
                <button class="date-filter-toggle" @click.stop="toggleDatePanel" :class="{ active: startDate || endDate }">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                    <line x1="16" y1="2" x2="16" y2="6" />
                    <line x1="8" y1="2" x2="8" y2="6" />
                    <line x1="3" y1="10" x2="21" y2="10" />
                  </svg>
                  <span>{{ formatFilterText() }}</span>
                </button>
                <div v-if="showDatePanel" class="date-panel">
                  <div class="date-panel-row">
                    <label class="date-panel-label">开始日期</label>
                    <input
                      v-model="startDate"
                      type="date"
                      :max="endDate || undefined"
                      class="date-panel-input"
                    />
                  </div>
                  <div class="date-panel-row">
                    <label class="date-panel-label">结束日期</label>
                    <input
                      v-model="endDate"
                      type="date"
                      :min="startDate || undefined"
                      class="date-panel-input"
                    />
                  </div>
                  <div class="date-panel-actions">
                    <button v-if="startDate || endDate" class="date-panel-reset" @click="resetDateFilter">清除</button>
                    <button class="date-panel-apply" @click="applyDateFilter">应用</button>
                  </div>
                </div>
              </div>
              <span class="chart-summary">{{ store.chanlunResult?.summary || 'K 线主区已独占工作台，可从右上角抽屉查看详情。' }}</span>
            </div>
            <div class="chart-actions">
              <IndicatorSelector />
            </div>
            <span v-if="store.klineUpdatedAt" class="chart-timestamp">K线 {{ store.klineUpdatedAt }}</span>
          </div>

          <div class="chart-stack">
            <KLineChart
              ref="klineChartRef"
              :klines="store.klines"
              :bis="store.chanlunResult?.bis || []"
              :xiangs="store.chanlunResult?.xiangs || []"
              :zhongshus="store.chanlunResult?.zhongshus || []"
              :signals="store.chanlunResult?.signals || []"
              :ai-signal="store.aiSignal"
              :support-resistance="store.chanlunResult?.supportResistance || []"
              :indicators="store.indicators"
              @zoom-change="onZoomChange"
            />
            <VolumeChart v-if="store.indicators.volume" :klines="store.klines" :zoom-start="zoomStart" :zoom-end="zoomEnd" class="sub-chart" />
            <MACDChart v-if="store.indicators.macd" :klines="store.klines" :zoom-start="zoomStart" :zoom-end="zoomEnd" class="sub-chart" />
            <RSIChart v-if="store.indicators.rsi" :klines="store.klines" :zoom-start="zoomStart" :zoom-end="zoomEnd" class="sub-chart" />
            <SKDJChart v-if="store.indicators.skdj" :klines="store.klines" :zoom-start="zoomStart" :zoom-end="zoomEnd" class="sub-chart" />
          </div>

        </div>

        <Transition name="drawer-slide">
          <aside
            v-if="drawerState.active"
            class="drawer-dock"
          >
            <!-- Switch 选项卡栏 -->
            <div class="drawer-switch">
              <button
                class="drawer-switch-btn"
                :class="{ active: drawerState.active === 'quote' }"
                title="行情详情与缠论信号 (Q)"
                @click="toggleDrawer('quote')"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                  <rect x="3" y="4" width="4" height="16" rx="1" />
                  <rect x="10" y="8" width="4" height="12" rx="1" />
                  <rect x="17" y="2" width="4" height="18" rx="1" />
                </svg>
                <span>行情</span>
                <span v-if="drawerAlertMap.quote && drawerState.active !== 'quote'" class="switch-dot" />
              </button>
              <button
                class="drawer-switch-btn"
                :class="{ active: drawerState.active === 'info' }"
                title="盘口・资料・新闻 (I)"
                @click="toggleDrawer('info')"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                  <line x1="8" y1="6" x2="21" y2="6" />
                  <line x1="8" y1="12" x2="21" y2="12" />
                  <line x1="8" y1="18" x2="21" y2="18" />
                  <circle cx="4" cy="6" r="1.5" />
                  <circle cx="4" cy="12" r="1.5" />
                  <circle cx="4" cy="18" r="1.5" />
                </svg>
                <span>盘口资讯</span>
                <span v-if="drawerAlertMap.info && drawerState.active !== 'info'" class="switch-dot" />
              </button>
              <button
                class="drawer-switch-btn"
                :class="{ active: drawerState.active === 'ai' }"
                title="缠师 AI 与笔记 (A)"
                @click="toggleDrawer('ai')"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                  <path d="M12 2a2 2 0 0 1 2 2c0 .74-.4 1.39-1 1.73V7h1a7 7 0 0 1 7 7h1a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-1v1a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-1H2a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1h1a7 7 0 0 1 7-7h1V5.73c-.6-.34-1-.99-1-1.73a2 2 0 0 1 2-2z" />
                  <circle cx="8.5" cy="14.5" r="1.5" />
                  <circle cx="15.5" cy="14.5" r="1.5" />
                </svg>
                <span>AI诊股</span>
                <span v-if="drawerAlertMap.ai && drawerState.active !== 'ai'" class="switch-dot" />
              </button>
              <button class="drawer-close-btn" title="关闭 (Esc)" @click="toggleDrawer(drawerState.active)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            </div>

            <!-- Quote 面板 -->
            <div v-if="drawerState.active === 'quote'" class="drawer-body">
              <section class="drawer-hero drawer-hero--quote">
                <div class="hero-price-line">
                  <span class="hero-price mono">{{ headerQuote?.price != null ? headerQuote.price.toFixed(2) : '—' }}</span>
                  <span class="hero-change mono" :class="changeClass">{{ changeAmountText }} {{ changeText }}</span>
                </div>
                <div class="hero-code-line">
                  <span>{{ headerQuote?.name || stockCode }}</span>
                  <span class="mono">{{ stockCode }}</span>
                </div>
              </section>

              <section class="drawer-card">
                <div class="drawer-card-title">OHLC</div>
                <div class="quote-grid">
                  <div v-for="item in quotePrimaryRows" :key="item.label" class="quote-grid-item">
                    <span class="quote-label">{{ item.label }}</span>
                    <span class="quote-value mono" :class="item.valueClass">{{ item.value }}</span>
                  </div>
                </div>
              </section>

              <section class="drawer-card">
                <div class="drawer-card-title">成交与估值</div>
                <div class="quote-grid">
                  <div v-for="item in quoteSecondaryRows" :key="item.label" class="quote-grid-item">
                    <span class="quote-label">{{ item.label }}</span>
                    <span class="quote-value mono" :class="item.valueClass">{{ item.value }}</span>
                  </div>
                </div>
              </section>

              <section class="drawer-card">
                <div class="drawer-card-title">分析级别</div>
                <div class="level-tabs drawer-level-tabs">
                  <button
                    v-for="lv in levels"
                    :key="`dr-${lv.value}`"
                    class="level-tab"
                    :class="{ active: currentLevel === lv.value }"
                    @click="changeLevel(lv.value)"
                  >{{ lv.label }}</button>
                </div>
              </section>

              <section class="drawer-card">
                <div class="drawer-card-title">走势判断</div>
                <div class="drawer-trend">
                  <span class="trend-pill" :class="trendClass">{{ store.chanlunResult?.trend || '—' }}</span>
                  <p class="drawer-paragraph">{{ store.chanlunResult?.summary || '暂无走势判断。' }}</p>
                </div>
              </section>

              <section class="drawer-card">
                <div class="drawer-card-title">缠论信号历史</div>
                <div v-if="sortedSignals.length" class="signal-timeline">
                  <button
                    v-for="(sig, idx) in sortedSignals.slice(0, 10)"
                    :key="`s-${sig.datetime}-${sig.type}-${idx}`"
                    class="signal-timeline-item"
                    :class="signalToneClass(sig.type)"
                    @click="focusSignal(sig)"
                  >
                    <div class="signal-timeline-top">
                      <span class="signal-type">{{ sig.type }}</span>
                      <span class="signal-level mono">{{ sig.level }}</span>
                    </div>
                    <div class="signal-timeline-mid">
                      <span class="mono">{{ sig.price.toFixed(2) }}</span>
                      <span>{{ formatSignalTime(sig.datetime) }}</span>
                    </div>
                    <p class="signal-timeline-desc">{{ sig.description }}</p>
                  </button>
                </div>
                <div v-else class="drawer-empty">当前级别尚未形成有效背驰或买卖点。</div>
              </section>
            </div>

            <!-- Info 面板 -->
            <div v-else-if="drawerState.active === 'info'" class="drawer-body">
              <div class="drawer-tabs">
                <button class="drawer-tab" :class="{ active: drawerState.tabs.info === 'depth' }" @click="setInfoTab('depth')">盘口</button>
                <button class="drawer-tab" :class="{ active: drawerState.tabs.info === 'profile' }" @click="setInfoTab('profile')">资料</button>
                <button class="drawer-tab" :class="{ active: drawerState.tabs.info === 'news' }" @click="setInfoTab('news')">新闻</button>
              </div>

              <section v-if="drawerState.tabs.info === 'depth'" class="drawer-card">
                <div class="drawer-card-title">五档盘口</div>
                <div v-if="hasDepth" class="depth-wrap">
                  <div class="depth-head">
                    <span />
                    <span class="dh-p">价格</span>
                    <span class="dh-v">量</span>
                  </div>
                  <div v-for="(row, i) in depthAsks" :key="`da-${i}`" class="depth-row depth-sell">
                    <span class="depth-lab">卖{{ 5 - i }}</span>
                    <span class="mono depth-price">{{ fmtDepthPrice(row.price) }}</span>
                    <span class="mono depth-vol">{{ fmtDepthVol(row.volume) }}</span>
                  </div>
                  <div class="depth-divider" />
                  <div v-for="(row, i) in depthBids" :key="`db-${i}`" class="depth-row depth-buy">
                    <span class="depth-lab">买{{ i + 1 }}</span>
                    <span class="mono depth-price">{{ fmtDepthPrice(row.price) }}</span>
                    <span class="mono depth-vol">{{ fmtDepthVol(row.volume) }}</span>
                  </div>
                </div>
                <div v-else class="drawer-empty">暂无盘口数据</div>
              </section>

              <section v-else-if="drawerState.tabs.info === 'profile'" class="drawer-card">
                <div class="drawer-card-title">基本资料</div>
                <div class="profile-section">
                  <div class="sector-chip">{{ extras?.boards?.industry || '行业待补充' }}</div>
                  <div class="quote-grid">
                    <div v-for="item in companyProfileRows" :key="item.label" class="quote-grid-item">
                      <span class="quote-label">{{ item.label }}</span>
                      <span class="quote-value mono" :class="item.valueClass">{{ item.value }}</span>
                    </div>
                  </div>
                  <div v-if="boardHighlightRows.length" class="board-highlights">
                    <div v-for="(row, idx) in boardHighlightRows" :key="`bh-${idx}`" class="board-highlight">
                      <span class="quote-label">{{ row.label }}</span>
                      <span class="quote-value mono">{{ row.value }}</span>
                    </div>
                  </div>
                </div>
              </section>

              <section v-else class="drawer-card drawer-card--stretch">
                <div class="drawer-card-title">公司新闻</div>
                <div v-if="extras?.news?.length" class="news-list">
                  <a
                    v-for="(item, idx) in extras.news"
                    :key="`n-${idx}`"
                    class="news-item"
                    :href="item.url"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <span class="news-title">{{ item.title }}</span>
                    <span class="news-meta">
                      <span v-if="item.source">{{ item.source }}</span>
                      <span v-if="item.time">{{ item.time }}</span>
                    </span>
                  </a>
                </div>
                <div v-else class="drawer-empty">暂无相关新闻</div>
              </section>
            </div>

            <!-- AI 面板 -->
            <div v-else class="drawer-body">
              <div v-if="showAiGuideTip" class="ai-guide-banner">
                <span>缠师在这里，按 A 可随时呼出</span>
                <button class="ai-guide-dismiss" @click="dismissAiGuide">知道了</button>
              </div>
              <div class="drawer-tabs">
                <button class="drawer-tab" :class="{ active: drawerState.tabs.ai === 'chat' }" @click="setAiTab('chat')">缠师对话</button>
                <button class="drawer-tab" :class="{ active: drawerState.tabs.ai === 'notes' }" @click="setAiTab('notes')">我的笔记</button>
                <button class="drawer-tab" :class="{ active: drawerState.tabs.ai === 'strategy' }" @click="setAiTab('strategy')">策略建议</button>
              </div>
              <AIChat v-if="drawerState.tabs.ai === 'chat'" :stock-code="stockCode" />
              <CommentSection v-else-if="drawerState.tabs.ai === 'notes'" :stock-code="stockCode" />
              <StrategyCard v-else :signal="store.aiSignal" :loading="store.loadingAI" :updated-at="store.aiUpdatedAt" />
            </div>
          </aside>
        </Transition>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { stockApi, type Quote, type StockExtras, type StockInfoFields, type Signal } from '../api/stock'
import { useStorage } from '../composables/useStorage'
import toast from '../composables/useToast'
import KLineChart from '../components/Chart/KLineChart.vue'
import VolumeChart from '../components/Chart/VolumeChart.vue'
import MACDChart from '../components/Chart/MACDChart.vue'
import RSIChart from '../components/Chart/RSIChart.vue'
import SKDJChart from '../components/Chart/SKDJChart.vue'
import IndicatorSelector from '../components/IndicatorSelector.vue'
import AIChat from '../components/AIChat.vue'
import CommentSection from '../components/Signal/CommentSection.vue'
import StrategyCard from '../components/Signal/StrategyCard.vue'
import { useChanlunStore, type LevelOption } from '../stores/chanlun'
import { useCommentStore } from '../stores/comment'
import { useWatchlistStore } from '../stores/watchlist'

type DrawerKey = 'quote' | 'info' | 'ai'
type InfoTab = 'depth' | 'profile' | 'news'
type AiTab = 'chat' | 'notes' | 'strategy'

interface DrawerState {
  active: DrawerKey | null
  tabs: {
    info: InfoTab
    ai: AiTab
  }
  aiGuideSeen: boolean
}

interface KLineChartExposed {
  focusSignal?: (datetime: string, price?: number) => void
}

const route = useRoute()
const store = useChanlunStore()
const commentStore = useCommentStore()
const watchlistStore = useWatchlistStore()
const klineChartRef = ref<KLineChartExposed | null>(null)

const zoomStart = ref(0)
const zoomEnd = ref(100)
const watchToggling = ref(false)
const quote = ref<Quote | null>(null)
const stockInfo = ref<StockInfoFields | null>(null)
const extras = ref<StockExtras | null>(null)
const showAiGuideTip = ref(false)
const drawerStateRef = useStorage<DrawerState>('stock_view_drawers_v3', {
  active: null,
  tabs: {
    info: 'depth',
    ai: 'chat',
  },
  aiGuideSeen: false,
})[0]

const drawerState = computed(() => drawerStateRef.value)

const stockCode = computed(() => route.params.code as string)
const currentLevel = computed(() => store.currentLevel)
const loadingAny = computed(() => store.loadingKline && !store.klines.length)
const error = computed(() => store.errorKline || store.errorChanlun || store.errorAI)
const isWatching = computed(() => watchlistStore.stocks.some(s => s.code === stockCode.value))

function onZoomChange(start: number, end: number) {
  zoomStart.value = start
  zoomEnd.value = end
}

function getOneYearAgo(): string {
  const date = new Date()
  date.setFullYear(date.getFullYear() - 1)
  return date.toISOString().split('T')[0]
}

const startDate = ref(getOneYearAgo())
const endDate = ref('')
const showDatePanel = ref(false)
let datePanelClickHandler: ((e: MouseEvent) => void) | null = null

function sanitizeDrawerState() {
  const validKeys: DrawerKey[] = ['quote', 'info', 'ai']
  const active = validKeys.includes(drawerStateRef.value.active as DrawerKey) ? drawerStateRef.value.active : null
  const infoTab: InfoTab = ['depth', 'profile', 'news'].includes(drawerStateRef.value.tabs?.info as InfoTab)
    ? drawerStateRef.value.tabs.info
    : 'depth'
  const aiTab: AiTab = ['chat', 'notes', 'strategy'].includes(drawerStateRef.value.tabs?.ai as AiTab)
    ? drawerStateRef.value.tabs.ai
    : 'chat'

  drawerStateRef.value = {
    active,
    tabs: {
      info: infoTab,
      ai: aiTab,
    },
    aiGuideSeen: !!drawerStateRef.value.aiGuideSeen,
  }
}

function toggleDatePanel() {
  showDatePanel.value = !showDatePanel.value
  if (showDatePanel.value) {
    nextTick(() => {
      datePanelClickHandler = (e: MouseEvent) => {
        const filterEl = document.querySelector('.date-filter')
        if (filterEl && !filterEl.contains(e.target as Node)) {
          showDatePanel.value = false
          cleanupDatePanelHandler()
        }
      }
      setTimeout(() => {
        if (datePanelClickHandler) document.addEventListener('click', datePanelClickHandler)
      }, 0)
    })
  } else {
    cleanupDatePanelHandler()
  }
}

function cleanupDatePanelHandler() {
  if (datePanelClickHandler) {
    document.removeEventListener('click', datePanelClickHandler)
    datePanelClickHandler = null
  }
}

function formatFilterText() {
  if (startDate.value && endDate.value) return `${startDate.value} ~ ${endDate.value}`
  if (startDate.value) return `${startDate.value} 至今`
  if (endDate.value) return `~ ${endDate.value}`
  return '时间筛选'
}

function _num(v: unknown): number | null {
  if (v == null || v === '') return null
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

function statPrice(v: number | null | undefined): string {
  if (v == null || Number.isNaN(v)) return '—'
  return v.toFixed(2)
}

function formatVolume(v?: number | null) {
  if (!v) return '—'
  if (v >= 1e8) return `${(v / 1e8).toFixed(2)}亿`
  if (v >= 1e4) return `${(v / 1e4).toFixed(2)}万`
  return v.toString()
}

function fmtAmount(v?: number | null) {
  if (v == null || Number.isNaN(v) || v === 0) return '—'
  if (v >= 1e8) return `${(v / 1e8).toFixed(2)}亿`
  if (v >= 1e4) return `${(v / 1e4).toFixed(2)}万`
  return v.toFixed(0)
}

function fmtRatio(v?: number | null) {
  if (v == null || Number.isNaN(v) || v === 0) return '—'
  return v.toFixed(2)
}

const headerQuote = computed((): Quote | null => {
  const q = quote.value
  const s = stockInfo.value as Record<string, unknown> | null
  if (!q && !s) return null

  const price = _num(q?.price) ?? _num(s?.['现价'])
  if (price == null) return null

  return {
    code: String(q?.code ?? s?.['代码'] ?? stockCode.value),
    name:
      (q?.name != null && String(q.name).trim() !== '' ? String(q.name) : '') ||
      (s?.['名称'] != null ? String(s['名称']).trim() : '') ||
      '',
    price,
    change_pct: _num(q?.change_pct) ?? _num(s?.['涨跌幅']) ?? 0,
    volume: _num(q?.volume) ?? _num(s?.['成交量']) ?? 0,
    amount: _num(q?.amount) ?? _num(s?.['成交额']) ?? 0,
    high: _num(q?.high) ?? _num(s?.['最高']) ?? 0,
    low: _num(q?.low) ?? _num(s?.['最低']) ?? 0,
    open: _num(q?.open) ?? _num(s?.['今开']) ?? 0,
    prev_close: _num(q?.prev_close) ?? _num(s?.['昨收']) ?? 0,
  }
})

const levels = [
  { value: '1min' as LevelOption, label: '1分' },
  { value: '5min' as LevelOption, label: '5分' },
  { value: '30min' as LevelOption, label: '30分' },
  { value: 'daily' as LevelOption, label: '日线' },
  { value: 'weekly' as LevelOption, label: '周线' },
  { value: 'monthly' as LevelOption, label: '月线' },
] as const

const changeClass = computed(() => {
  const hq = headerQuote.value
  if (!hq) return ''
  return hq.change_pct > 0 ? 'price-up' : hq.change_pct < 0 ? 'price-down' : 'price-flat'
})

const changeText = computed(() => {
  const hq = headerQuote.value
  if (!hq) return '—'
  const pct = hq.change_pct ?? 0
  return `${pct > 0 ? '+' : ''}${pct.toFixed(2)}%`
})

const changeAmountText = computed(() => {
  const amount = _num((stockInfo.value as Record<string, unknown> | null)?.['涨跌额'])
    ?? ((headerQuote.value?.price != null && headerQuote.value?.prev_close != null) ? headerQuote.value.price - headerQuote.value.prev_close : null)
  if (amount == null) return '—'
  return `${amount > 0 ? '+' : ''}${amount.toFixed(2)}`
})

const trendClass = computed(() => {
  const t = store.chanlunResult?.trend
  if (t === '上涨') return 'trend-up'
  if (t === '下跌') return 'trend-down'
  return 'trend-side'
})

const sortedSignals = computed(() =>
  [...(store.chanlunResult?.signals || [])].sort((a, b) => new Date(b.datetime).getTime() - new Date(a.datetime).getTime())
)

const toolbarSignalDots = computed(() => {
  const signals = sortedSignals.value.slice(0, 3)
  if (!signals.length) {
    return [
      { key: 'n1', tone: 'neutral', label: '暂无信号' },
      { key: 'n2', tone: 'neutral', label: '暂无信号' },
      { key: 'n3', tone: 'neutral', label: '暂无信号' },
    ]
  }
  return signals.map((signal, index) => ({
    key: `${signal.type}-${index}`,
    tone: signal.type.includes('买') ? 'buy' : signal.type.includes('卖') ? 'sell' : 'neutral',
    label: `${signal.type} ${formatSignalTime(signal.datetime)}`,
  }))
})

const quotePrimaryRows = computed(() => [
  { label: '开盘', value: statPrice(headerQuote.value?.open), valueClass: '' },
  { label: '最高', value: statPrice(headerQuote.value?.high), valueClass: 'price-up' },
  { label: '最低', value: statPrice(headerQuote.value?.low), valueClass: 'price-down' },
  { label: '昨收', value: statPrice(headerQuote.value?.prev_close), valueClass: '' },
])

const quoteSecondaryRows = computed(() => {
  const info = stockInfo.value as Record<string, unknown> | null
  const amplitude = _num(info?.['振幅'])
  const pe = _num(info?.['市盈率'])
  const pb = _num(info?.['市净率'])
  return [
    { label: '成交量', value: formatVolume(headerQuote.value?.volume), valueClass: '' },
    { label: '成交额', value: fmtAmount(headerQuote.value?.amount), valueClass: '' },
    { label: '振幅', value: amplitude != null ? `${amplitude.toFixed(2)}%` : '—', valueClass: '' },
    { label: '市盈率', value: fmtRatio(pe), valueClass: '' },
    { label: '市净率', value: fmtRatio(pb), valueClass: '' },
    { label: '涨跌额', value: changeAmountText.value, valueClass: changeClass.value },
  ]
})

const companyProfileRows = computed(() => {
  const info = stockInfo.value as Record<string, unknown> | null
  if (!info) return quoteSecondaryRows.value
  return [
    { label: '现价', value: statPrice(_num(info['现价'])), valueClass: changeClass.value },
    { label: '涨跌幅', value: changeText.value, valueClass: changeClass.value },
    { label: '成交量', value: formatVolume(_num(info['成交量'])), valueClass: '' },
    { label: '成交额', value: fmtAmount(_num(info['成交额'])), valueClass: '' },
    { label: '振幅', value: _num(info['振幅']) != null ? `${_num(info['振幅'])?.toFixed(2)}%` : '—', valueClass: '' },
    { label: '市盈率', value: fmtRatio(_num(info['市盈率'])), valueClass: '' },
    { label: '市净率', value: fmtRatio(_num(info['市净率'])), valueClass: '' },
    { label: '昨收', value: statPrice(_num(info['昨收'])), valueClass: '' },
  ]
})

const depthAsks = computed(() => extras.value?.depth?.asks ?? [])
const depthBids = computed(() => extras.value?.depth?.bids ?? [])
const hasDepth = computed(() => {
  const d = extras.value?.depth
  if (!d) return false
  const ok = (rows: { price: number; volume: number }[]) => rows.some(r => r.price > 0 || r.volume > 0)
  return ok(d.asks) || ok(d.bids)
})

const boardHighlightRows = computed(() => {
  const list = extras.value?.boards?.highlights ?? []
  return list.filter(h => h.label !== '行业' && !/^行业/.test(h.label))
})

const drawerAlertMap = computed<Record<DrawerKey, boolean>>(() => ({
  quote: sortedSignals.value.length > 0,
  info: !!extras.value?.news?.length,
  ai: !!store.aiSignal,
}))

function toggleDrawer(key: DrawerKey) {
  drawerStateRef.value.active = drawerStateRef.value.active === key ? null : key
}

function setInfoTab(tab: InfoTab) {
  drawerStateRef.value.tabs.info = tab
}

function setAiTab(tab: AiTab) {
  drawerStateRef.value.tabs.ai = tab
}

function dismissAiGuide() {
  showAiGuideTip.value = false
}

function fmtDepthPrice(p: number) {
  if (p == null || Number.isNaN(p) || p <= 0) return '—'
  return p.toFixed(2)
}

function fmtDepthVol(v: number) {
  if (v == null || Number.isNaN(v) || v <= 0) return '—'
  if (v >= 1e8) return `${(v / 1e8).toFixed(2)}亿`
  if (v >= 1e4) return `${(v / 1e4).toFixed(2)}万`
  return String(Math.round(v))
}

function formatSignalTime(datetime: string) {
  if (!datetime) return '—'
  return datetime.replace('T', ' ').slice(0, 16)
}

function signalToneClass(type: string) {
  if (type.includes('买')) return 'signal-timeline-item--buy'
  if (type.includes('卖')) return 'signal-timeline-item--sell'
  return 'signal-timeline-item--neutral'
}

function focusSignal(signal: Signal) {
  klineChartRef.value?.focusSignal?.(signal.datetime, signal.price)
  drawerStateRef.value.active = null
}

async function loadData() {
  const code = stockCode.value
  if (!code) return

  await store.loadAll(code, currentLevel.value, startDate.value || undefined, endDate.value || undefined)
  const settled = await Promise.allSettled([
    stockApi.quote(code),
    stockApi.info(code),
    stockApi.extras(code, 8),
  ])

  quote.value = settled[0].status === 'fulfilled' ? settled[0].value.data as Quote : null

  if (settled[1].status === 'fulfilled') {
    const info = settled[1].value.data.info
    stockInfo.value = info && Object.keys(info).length ? info : null
  } else {
    stockInfo.value = null
  }

  extras.value = settled[2].status === 'fulfilled' ? settled[2].value.data : null

  commentStore.fetchComments(code)
}

async function changeLevel(level: LevelOption) {
  await store.loadAll(stockCode.value, level, startDate.value || undefined, endDate.value || undefined)
}

function resetDateFilter() {
  startDate.value = getOneYearAgo()
  endDate.value = ''
  showDatePanel.value = false
  cleanupDatePanelHandler()
  loadData()
}

function applyDateFilter() {
  showDatePanel.value = false
  cleanupDatePanelHandler()
  loadData()
}

async function toggleWatch() {
  if (watchToggling.value) return
  watchToggling.value = true
  try {
    if (isWatching.value) {
      await watchlistStore.removeStock(stockCode.value)
      toast.success('已从自选股移除')
    } else {
      await watchlistStore.addStock(stockCode.value)
      toast.success('已添加到自选股')
    }
  } catch (e: any) {
    toast.error(e.message || '操作失败，请重试')
  } finally {
    watchToggling.value = false
  }
}


function handleKeydown(e: KeyboardEvent) {
  const target = e.target as HTMLElement | null
  if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) return

  switch (e.key) {
    case 'r':
    case 'R':
      if (!loadingAny.value) loadData()
      break
    case '1':
      changeLevel('1min')
      break
    case '5':
      changeLevel('5min')
      break
    case 'd':
    case 'D':
      changeLevel('daily')
      break
    case 'w':
    case 'W':
      changeLevel('weekly')
      break
    case 'm':
    case 'M':
      changeLevel('monthly')
      break
    case 'q':
    case 'Q':
      toggleDrawer('quote')
      break
    case 'i':
    case 'I':
      toggleDrawer('info')
      break
    case 'a':
    case 'A':
      toggleDrawer('ai')
      break
    case 'Escape':
      if (drawerStateRef.value.active) drawerStateRef.value.active = null
      break
  }
}

onMounted(() => {
  sanitizeDrawerState()
  loadData()
  window.addEventListener('keydown', handleKeydown)

  if (!drawerStateRef.value.aiGuideSeen) {
    drawerStateRef.value.active = 'ai'
    drawerStateRef.value.aiGuideSeen = true
    showAiGuideTip.value = true
    window.setTimeout(() => {
      showAiGuideTip.value = false
    }, 5000)
  }
})

onUnmounted(() => {
  cleanupDatePanelHandler()
  window.removeEventListener('keydown', handleKeydown)
})

watch(() => route.params.code, () => {
  loadData()
})
</script>

<style scoped>
.layout {
  min-height: 100vh;
}

.nav-inner--stock {
  display: flex;
  align-items: center;
  gap: 16px;
  min-width: 0;
  min-height: 58px;
  height: auto;
  padding-top: 10px;
  padding-bottom: 10px;
}

.nav-left {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
  flex: 0 0 auto;
}

.stock-topline {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px 14px;
  min-width: 0;
  flex: 1 1 360px;
  opacity: 0.72;
  transition: opacity 0.16s ease;
}

.stock-topline--ready {
  opacity: 1;
}

.stock-topline-main {
  display: flex;
  align-items: baseline;
  gap: 8px;
  min-width: 0;
  flex: 1 1 auto;
  flex-wrap: wrap;
}

.stock-code {
  color: var(--text-muted);
  font-size: 0.78rem;
}

.stock-name {
  font-size: 0.92rem;
  font-weight: 700;
  color: var(--text-primary);
}

.stock-price {
  font-size: 1.18rem;
  font-weight: 800;
  color: var(--text-primary);
}

.stock-change {
  font-size: 0.76rem;
  font-weight: 700;
}

.stock-change--placeholder {
  color: var(--text-muted);
}

.stock-topline-stats {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: flex-end;
  flex: 0 1 auto;
}

.top-stat {
  font-size: 0.68rem;
  color: var(--text-secondary);
  white-space: nowrap;
}

.top-stat b {
  color: var(--text-muted);
  margin-right: 4px;
  font-weight: 600;
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: nowrap;
  justify-content: flex-end;
  margin-left: auto;
  flex: 0 1 auto;
}

.trend-capsule {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 10px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
}

.trend-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 52px;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
}

.trend-up {
  background: rgba(239, 68, 68, 0.14);
  color: var(--accent-red);
  border: 1px solid rgba(239, 68, 68, 0.25);
}

.trend-down {
  background: rgba(34, 197, 94, 0.14);
  color: var(--accent-green);
  border: 1px solid rgba(34, 197, 94, 0.25);
}

.trend-side {
  background: rgba(245, 158, 11, 0.12);
  color: var(--accent-amber);
  border: 1px solid rgba(245, 158, 11, 0.28);
}

.signal-dots {
  display: flex;
  align-items: center;
  gap: 6px;
}

.signal-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.04);
}

.signal-dot--buy {
  background: var(--accent-green);
}

.signal-dot--sell {
  background: var(--accent-red);
}

.signal-dot--neutral {
  background: #6b7280;
}

.nav-level-tabs {
  flex-wrap: nowrap;
}

.loading-overlay {
  position: fixed;
  inset: 0;
  z-index: 999;
  background: var(--bg-base);
  display: flex;
  align-items: center;
  justify-content: center;
}

.loading-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.spinner {
  width: 24px;
  height: 24px;
  border: 2px solid var(--border);
  border-top-color: var(--accent-blue);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.btn-spinner {
  display: inline-block;
  width: 12px;
  height: 12px;
  border: 1.5px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

.btn-loading {
  opacity: 0.7;
  cursor: not-allowed !important;
}

.btn-danger {
  color: var(--accent-red) !important;
}

.error-page {
  text-align: center;
  padding: 80px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.error-icon {
  color: var(--accent-red);
  opacity: 0.6;
}

.error-message {
  color: var(--text-secondary);
  font-size: 0.95rem;
  margin: 0;
  max-width: 320px;
}

.error-page .btn {
  margin-top: 8px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.workspace {
  padding: 16px 24px 20px;
}

.workspace-main {
  display: flex;
  align-items: stretch;
  gap: 16px;
  max-width: 1920px;
  margin: 0 auto;
  min-height: calc(100vh - 108px);
}

.chart-shell {
  position: relative;
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.chart-header {
  padding: 10px 14px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.chart-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
  flex: 1;
}

.chart-summary {
  min-width: 0;
  font-size: 0.8rem;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chart-actions {
  margin-left: auto;
}

.chart-timestamp {
  font-size: 0.68rem;
  color: var(--text-muted);
  font-family: var(--font-mono);
  white-space: nowrap;
}

.chart-stack {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}

.sub-chart {
  height: 100px;
}

.drawer-dock {
  width: min(280px, calc(100vw - 48px));
  background: rgba(16, 22, 31, 0.98);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 18px;
  box-shadow: 0 28px 48px rgba(0, 0, 0, 0.32);
  display: flex;
  flex-direction: column;
  min-height: 0;
  max-height: calc(100vh - 112px);
  flex-shrink: 0;
  align-self: stretch;
}

/* Switch 选项卡栏 */
.drawer-switch {
  display: flex;
  gap: 0;
  padding: 5px;
  margin: 8px 8px 0;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  align-items: center;
}

.drawer-switch-btn {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-size: 0.82rem;
  font-weight: 700;
  padding: 8px 12px;
  border-radius: 9px;
  cursor: pointer;
  transition: all 0.16s ease;
  position: relative;
  white-space: nowrap;
}

.drawer-switch-btn:hover {
  color: var(--text-secondary);
  background: rgba(255, 255, 255, 0.04);
}

.drawer-switch-btn.active {
  color: var(--text-primary);
  background: rgba(16, 185, 129, 0.12);
  box-shadow: inset 0 0 0 1px rgba(16, 185, 129, 0.16);
}

.drawer-close-btn {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border-radius: 6px;
  flex-shrink: 0;
  transition: all 0.16s ease;
}

.drawer-close-btn:hover {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.06);
}

.switch-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #ef4444;
  position: absolute;
  top: 5px;
  right: 5px;
}

/* AI 引导提示条 */
.ai-guide-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 10px 14px;
  border-radius: 12px;
  border: 1px solid rgba(16, 185, 129, 0.35);
  background: rgba(16, 185, 129, 0.08);
  color: var(--text-secondary);
  font-size: 0.78rem;
  line-height: 1.5;
}

.ai-guide-dismiss {
  border: none;
  background: transparent;
  color: #6ee7b7;
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.15s ease;
}

.ai-guide-dismiss:hover {
  background: rgba(16, 185, 129, 0.15);
}

/* 侧栏划入动画 */
.drawer-slide-enter-active,
.drawer-slide-leave-active {
  transition: transform 0.22s ease, opacity 0.22s ease;
}

.drawer-slide-enter-from,
.drawer-slide-leave-to {
  transform: translateX(24px);
  opacity: 0;
}

.drawer-icon-btn {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
  color: var(--text-secondary);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.16s ease;
}

.drawer-icon-btn:hover,
.drawer-icon-btn--active {
  color: #6ee7b7;
  border-color: rgba(16, 185, 129, 0.45);
  background: rgba(16, 185, 129, 0.12);
}

.drawer-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 8px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  scrollbar-width: thin;
  scrollbar-color: var(--border) transparent;
}

.drawer-body::-webkit-scrollbar {
  width: 6px;
}

.drawer-body::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 999px;
}

.drawer-hero {
  padding: 16px;
  border-radius: 16px;
  background:
    radial-gradient(circle at top right, rgba(14, 165, 233, 0.18), transparent 38%),
    linear-gradient(135deg, rgba(17, 24, 39, 0.96), rgba(15, 23, 42, 0.92));
  border: 1px solid rgba(88, 166, 255, 0.18);
}

.hero-price-line {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
}

.hero-price {
  font-size: 2rem;
  font-weight: 800;
  color: var(--text-primary);
}

.hero-change {
  font-size: 0.92rem;
  font-weight: 700;
}

.hero-code-line {
  margin-top: 8px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 0.8rem;
  color: var(--text-secondary);
}

.drawer-card {
  padding: 14px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(255, 255, 255, 0.025);
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.drawer-card--stretch {
  flex: 1;
  min-height: 320px;
}

.drawer-card-title {
  font-size: 0.78rem;
  font-weight: 800;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.quote-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.quote-grid-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.quote-label {
  font-size: 0.7rem;
  color: var(--text-muted);
}

.quote-value {
  font-size: 0.86rem;
  font-weight: 700;
  color: var(--text-primary);
}

.drawer-level-tabs {
  flex-wrap: wrap;
}

.drawer-trend {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.drawer-paragraph {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.82rem;
  line-height: 1.6;
}

.signal-timeline {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.signal-timeline-item {
  text-align: left;
  width: 100%;
  padding: 12px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.03);
  color: inherit;
  cursor: pointer;
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease;
}

.signal-timeline-item:hover {
  transform: translateY(-1px);
  background: rgba(255, 255, 255, 0.05);
}

.signal-timeline-item--buy {
  border-color: rgba(34, 197, 94, 0.18);
}

.signal-timeline-item--sell {
  border-color: rgba(239, 68, 68, 0.2);
}

.signal-timeline-item--neutral {
  border-color: rgba(107, 114, 128, 0.22);
}

.signal-timeline-top,
.signal-timeline-mid {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.signal-timeline-top {
  margin-bottom: 6px;
}

.signal-type {
  font-size: 0.82rem;
  font-weight: 800;
}

.signal-level {
  font-size: 0.68rem;
  color: var(--text-muted);
}

.signal-timeline-mid {
  font-size: 0.74rem;
  color: var(--text-secondary);
}

.signal-timeline-desc {
  margin: 8px 0 0;
  font-size: 0.76rem;
  color: var(--text-secondary);
  line-height: 1.5;
}

.drawer-tabs {
  display: inline-flex;
  gap: 6px;
  padding: 4px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  align-self: flex-start;
}

.drawer-tab {
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-size: 0.78rem;
  font-weight: 700;
  padding: 8px 12px;
  border-radius: 9px;
  cursor: pointer;
  transition: all 0.16s ease;
}

.drawer-tab.active {
  color: var(--text-primary);
  background: rgba(16, 185, 129, 0.12);
  box-shadow: inset 0 0 0 1px rgba(16, 185, 129, 0.16);
}

.drawer-empty {
  font-size: 0.78rem;
  color: var(--text-muted);
  padding: 20px 6px;
}

.profile-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.sector-chip {
  align-self: flex-start;
  padding: 6px 10px;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--accent-blue);
  background: rgba(88, 166, 255, 0.1);
  border: 1px solid rgba(88, 166, 255, 0.18);
}

.board-highlights {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.board-highlight {
  padding: 10px 12px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.depth-wrap {
  margin-top: 2px;
}

.depth-head,
.depth-row {
  display: grid;
  grid-template-columns: 2.2rem 1fr 1fr;
  gap: 4px;
  align-items: center;
}

.depth-head {
  font-size: 0.66rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 8px;
}

.dh-p,
.dh-v,
.depth-price,
.depth-vol {
  text-align: right;
}

.depth-row {
  padding: 4px 0;
  font-size: 0.78rem;
}

.depth-lab {
  color: var(--text-muted);
  font-size: 0.72rem;
}

.depth-price {
  font-weight: 700;
}

.depth-vol {
  font-size: 0.72rem;
  color: var(--text-secondary);
}

.depth-sell .depth-price {
  color: var(--accent-green);
}

.depth-buy .depth-price {
  color: var(--accent-red);
}

.depth-divider {
  height: 1px;
  background: var(--border);
  margin: 8px 0;
  opacity: 0.85;
}

.news-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
  overflow-y: auto;
}

.news-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 12px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(255, 255, 255, 0.03);
  color: inherit;
  text-decoration: none;
  transition: border-color 0.16s ease, background 0.16s ease;
}

.news-item:hover {
  border-color: rgba(88, 166, 255, 0.26);
  background: rgba(88, 166, 255, 0.06);
}

.news-title {
  font-size: 0.8rem;
  font-weight: 700;
  line-height: 1.5;
  color: var(--text-primary);
}

.news-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  font-size: 0.68rem;
  color: var(--text-muted);
}

.ai-model-switch {
  display: flex;
  gap: 4px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 4px;
}

.model-btn {
  padding: 5px 12px;
  border-radius: 7px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font-family: var(--font-mono);
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  cursor: pointer;
  transition: color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
}

.model-btn.active {
  background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
  color: #fff;
  box-shadow: 0 2px 10px rgba(14, 165, 233, 0.35);
}

.model-btn:hover:not(.active) {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.06);
}

.date-filter {
  position: relative;
}

.date-filter-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 10px;
  font-size: 0.75rem;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.date-filter-toggle:hover {
  border-color: var(--accent-blue);
  color: var(--text-primary);
}

.date-filter-toggle.active {
  background: rgba(14, 165, 233, 0.1);
  border-color: var(--accent-blue);
  color: var(--accent-blue);
}

.date-panel {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 14px;
  z-index: 50;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
  min-width: 220px;
}

.date-panel-row {
  margin-bottom: 12px;
}

.date-panel-row:last-of-type {
  margin-bottom: 14px;
}

.date-panel-label {
  display: block;
  font-size: 0.7rem;
  color: var(--text-muted);
  margin-bottom: 6px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.date-panel-input {
  width: 100%;
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 8px 10px;
  font-size: 0.8rem;
  color: var(--text-primary);
  cursor: pointer;
  outline: none;
  transition: border-color 0.15s;
  box-sizing: border-box;
}

.date-panel-input:focus {
  border-color: var(--accent-blue);
}

.date-panel-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.date-panel-reset {
  padding: 6px 14px;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 8px;
  font-size: 0.75rem;
  color: var(--text-muted);
  cursor: pointer;
}

.date-panel-apply {
  padding: 6px 14px;
  background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
  border: none;
  border-radius: 8px;
  font-size: 0.75rem;
  font-weight: 600;
  color: #fff;
  cursor: pointer;
}

@media (max-width: 1680px) {
  .nav-inner--stock {
    gap: 12px;
    flex-wrap: wrap;
  }

  .nav-actions {
    margin-left: auto;
    flex-wrap: wrap;
  }
}

@media (max-width: 1360px) {
  .workspace-main {
    flex-direction: column;
  }

  .drawer-dock {
    width: 100%;
    max-height: none;
  }

  .nav-inner--stock {
    align-items: flex-start;
  }

  .stock-topline {
    order: 3;
    width: 100%;
    flex-basis: 100%;
    flex-direction: column;
    align-items: flex-start;
    justify-content: flex-start;
  }

  .stock-topline-stats {
    justify-content: flex-start;
  }

  .nav-actions {
    width: 100%;
    margin-left: 0;
    justify-content: flex-start;
  }
}

@media (max-width: 960px) {
  .workspace {
    padding: 12px;
  }

  .chart-header {
    flex-wrap: wrap;
    align-items: flex-start;
  }

  .chart-header-left {
    width: 100%;
    flex-wrap: wrap;
  }

  .chart-actions {
    margin-left: 0;
  }
}
</style>
