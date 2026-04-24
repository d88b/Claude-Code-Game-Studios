# IARC Submission Guide

**Story**: age-001
**Date**: 2026-04-25

---

## IARC 概述

**IARC** (International Age Rating Coalition) 是国际年龄分级联盟，通过单一问卷自动生成多个地区年龄分级。

### 覆盖分级机构

| 机构 | 地区 | 自动生成 |
|------|------|----------|
| **ESRB** | 北美 | ✅ |
| **PEGI** | 欧洲 | ✅ |
| **USK** | 德国 | ✅ |
| **ClassInd** | 巴西 | ✅ |
| **GRB** | 韩国 | ✅ (需额外提交) |
| **CERO** | 日本 | ❌ (需单独提交) |

---

## 提交平台

| 平台 | 提交入口 |
|------|----------|
| **Steam** | Steamworks → App Admin → Age Rating Questionnaire |
| **Epic** | Epic Developer Portal → Age Rating |

---

## 问卷准备

### 基本信息

| 项目 | 回答 |
|------|------|
| **游戏类型** | Action/Strategy/Survival |
| **游戏模式** | Single-player only |
| **网络功能** | None |
| **用户生成内容** | None |
| **付费模式** | Premium (one-time purchase) |
| **随机奖励** | No (no loot boxes) |

---

### 暴力内容问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含暴力？ | **Yes** | 僵尸战斗 |
| 暴力类型？ | **Fantasy Violence** | 非写实虚构暴力 |
| 暴力对象？ | **Non-human creatures** | 僵尸敌人 |
| 暴力表现？ | **No blood/gore** | 僵尸化为粒子消失 |
| 暴力频率？ | **Moderate** | 战斗是核心玩法 |
| 伤害表现？ | **No dismemberment** | 无肢体损伤 |

---

### 语言内容问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含粗俗语言？ | **No** | 无 swear words |
| 是否包含性暗示语言？ | **No** | 无 |
| 是否包含歧视语言？ | **No** | 无 |

---

### 性内容问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含裸露？ | **No** | 无人类角色裸露 |
| 是否包含性行为？ | **No** | 无 |
| 是否包含性暗示？ | **No** | 无 |

---

### 药物/酒精/烟草问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含毒品相关？ | **No** | 无 |
| 是否包含酒精？ | **No** | 无 |
| 是否包含烟草？ | **No** | 无 |

---

### 赌博内容问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含赌博？ | **No** | 无 |
| 是否包含随机奖励/开箱？ | **No** | 资源掉落随机但非赌博 |
| 是否包含真实货币交易？ | **No** | Premium 模式 |

---

### 恐怖/恐惧问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含恐怖元素？ | **Mild** | 僵尸敌人但卡通化 |
| 是否包含惊吓元素？ | **No** | 无 jump scares |
| 恐怖程度？ | **Low** | 像素风格，不写实 |

---

### 其他内容问答

| 问题 | 回答 | 理由 |
|------|------|------|
| 是否包含歧视内容？ | **No** | 无 |
| 是否包含宗教内容？ | **No** | 无 |
| 是否包含真实人物？ | **No** | 无 |

---

## 预期分级结果

| 机构 | 预期评级 | 描述符 |
|------|----------|--------|
| **ESRB** | **Teen (T)** | Violence |
| **PEGI** | **12+** | Violence |
| **USK** | **12** | Violence (非写实) |
| **ClassInd** | **14** | Violence |
| **GRB** | **12** | Violence |

---

## Steam 提交步骤

### 1. 登录 Steamworks

```
URL: https://partner.steamgames.com/
```

### 2. 进入 App Admin

- 选择你的 App ID
- 进入 "Age Rating Questionnaire"

### 3. 填写问卷

- 按照上述问答填写
- 约需 10-15 分钟

### 4. 提交

- 完成问卷后提交
- 自动生成分级证书

### 5. 确认

- 检查生成的分级
- 确认后生效

---

## Epic 提交步骤

### 1. 登录 Epic Developer Portal

```
URL: https://dev.epicgames.com/
```

### 2. 进入 Product Settings

- 选择产品
- 进入 "Age Rating"

### 3. 填写问卷

- 与 Steam 类似流程

### 4. 提交确认

---

## CERO 单独提交 (日本)

如需日本发行，需单独提交 CERO:

### 步骤

1. 访问 https://www.cero.gr.jp/
2. 注册账号
3. 提交审查申请
4. 填写问卷 (日语)
5. 等待审查结果

### 预期评级

- **CERO B** (12岁以上)
- 费用: ¥50,000-100,000
- 时间: 2-4 周

---

## 提交检查清单

| 项目 | 状态 |
|------|------|
| Steam IARC 问卷填写 | ⏳ Pending |
| Epic IARC 问卷填写 | ⏳ Pending |
| CERO 申请 (日本) | ⏳ Optional |
| 分级证书保存 | ⏳ Pending |

---

## 提交后

### 保存分级证书

将分级证书保存到:

```
D:\ai\Claude-Code-Game-Studios\legal\age_ratings\
```

### 更新商店页面

- 在商店页面显示分级标识
- 添加内容警告描述

---

*IARC Submission Guide — age-001*