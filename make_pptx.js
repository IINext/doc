const pptxgen = require("pptxgenjs");

let pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';
pres.author = '文件管理系統';
pres.title = '文件管理系統 + 即時通 產品說明';

// Color palette: Ocean Gradient
const C = {
  primary: "065A82",
  secondary: "1C7293",
  accent: "0A9DC2",
  dark: "032D41",
  white: "FFFFFF",
  lightBg: "EEF6FA",
  midBg: "D0E8F2",
  textDark: "1A2F3A",
  textMid: "2D5A72",
  textLight: "6B9BB0",
  success: "27AE60",
  warning: "F39C12",
  info: "2980B9",
  cardBg: "F5FBFE",
};

const makeShadow = () => ({ type: "outer", color: "000000", blur: 8, offset: 3, angle: 135, opacity: 0.12 });
const makeCardShadow = () => ({ type: "outer", color: "065A82", blur: 10, offset: 2, angle: 135, opacity: 0.10 });

// ─────────────────────────────────────────────
// SLIDE 1: Cover
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.primary };

  // Dark overlay rectangle on right side for depth
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.5, y: 0, w: 3.5, h: 5.625,
    fill: { color: C.dark },
    line: { color: C.dark, width: 0 }
  });

  // Decorative circles
  slide.addShape(pres.shapes.OVAL, {
    x: 7.2, y: -0.5, w: 2.5, h: 2.5,
    fill: { color: C.secondary, transparency: 60 },
    line: { color: C.secondary, width: 0 }
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 7.8, y: 3.5, w: 1.8, h: 1.8,
    fill: { color: C.accent, transparency: 70 },
    line: { color: C.accent, width: 0 }
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 6.2, y: 2.5, w: 0.8, h: 0.8,
    fill: { color: C.accent, transparency: 50 },
    line: { color: C.accent, width: 0 }
  });

  // Top accent bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 0.55, w: 1.2, h: 0.06,
    fill: { color: C.accent },
    line: { color: C.accent, width: 0 }
  });

  // Version tag
  slide.addText("v2.0  |  2026", {
    x: 0.5, y: 0.42, w: 5, h: 0.25,
    fontSize: 10, color: C.accent, fontFace: "Calibri",
    bold: false, margin: 0
  });

  // Main product name
  slide.addText("文件管理系統", {
    x: 0.5, y: 0.9, w: 5.8, h: 0.85,
    fontSize: 42, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });

  slide.addText("+ 即時通", {
    x: 0.5, y: 1.75, w: 5.8, h: 0.65,
    fontSize: 32, color: C.accent, fontFace: "Calibri",
    bold: true, margin: 0
  });

  // Divider line
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 2.52, w: 5.5, h: 0.04,
    fill: { color: C.accent, transparency: 30 },
    line: { color: C.accent, width: 0 }
  });

  // Tagline
  slide.addText("企業文件合規管理一站式解決方案", {
    x: 0.5, y: 2.65, w: 5.8, h: 0.5,
    fontSize: 18, color: C.midBg, fontFace: "Calibri",
    bold: false, margin: 0
  });

  // Sub description
  slide.addText("自建部署  ·  ISO 9001:2015 合規  ·  行動裝置支援", {
    x: 0.5, y: 3.25, w: 5.8, h: 0.35,
    fontSize: 12, color: C.textLight, fontFace: "Calibri",
    bold: false, margin: 0
  });

  // Bottom info bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.1, w: 6.5, h: 0.525,
    fill: { color: C.dark },
    line: { color: C.dark, width: 0 }
  });
  slide.addText("Flask 3.0  +  FastAPI  +  PostgreSQL  |  Bootstrap 5  |  Cloudflare Tunnel", {
    x: 0.5, y: 5.12, w: 6, h: 0.35,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    bold: false, margin: 0
  });

  // Right column text
  slide.addText("中小型製造業", {
    x: 6.7, y: 1.2, w: 3, h: 0.4,
    fontSize: 13, color: C.textLight, fontFace: "Calibri",
    align: "center", margin: 0
  });
  slide.addText("ISO合規", {
    x: 6.7, y: 1.75, w: 3, h: 0.55,
    fontSize: 22, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });
  slide.addText("解決方案", {
    x: 6.7, y: 2.35, w: 3, h: 0.45,
    fontSize: 18, color: C.accent, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });

  // Feature list on right
  const feats = ["文件版本管控", "簽核流程自動化", "即時訊息整合", "稽核軌跡追蹤"];
  feats.forEach((f, i) => {
    slide.addShape(pres.shapes.OVAL, {
      x: 6.85, y: 3.1 + i * 0.44, w: 0.18, h: 0.18,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 }
    });
    slide.addText(f, {
      x: 7.1, y: 3.06 + i * 0.44, w: 2.6, h: 0.25,
      fontSize: 11, color: C.midBg, fontFace: "Calibri",
      margin: 0
    });
  });
}

// ─────────────────────────────────────────────
// SLIDE 2: 企業痛點
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Top header band
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.05,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("企業痛點", {
    x: 0.5, y: 0.15, w: 9, h: 0.55,
    fontSize: 28, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("中小型製造業面臨的文件管理困境", {
    x: 0.5, y: 0.68, w: 9, h: 0.3,
    fontSize: 13, color: C.midBg, fontFace: "Calibri",
    margin: 0
  });

  // 3 pain point cards
  const pains = [
    { num: "01", title: "文件版本混亂", desc: "多人同時編輯同一份文件，版本難以追蹤，舊版本誤用導致生產錯誤，無法確認哪個版本為最新核准版。", color: "C0392B" },
    { num: "02", title: "ISO稽核難追蹤", desc: "文件簽核紀錄分散各處，稽核人員無法快速查閱歷史記錄，ISO 9001:2015 第7.5條要求的紀錄保存難以達成。", color: "E67E22" },
    { num: "03", title: "簽核流程不透明", desc: "文件送審後不知審核進度，簽核人員未及時通知，流程瓶頸無法識別，審核時間過長影響作業效率。", color: "8E44AD" },
  ];

  pains.forEach((p, i) => {
    const x = 0.35 + i * 3.2;
    // Card bg
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.25, w: 3.0, h: 3.9,
      fill: { color: C.white },
      line: { color: C.white, width: 0 },
      shadow: makeShadow()
    });
    // Top color band
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.25, w: 3.0, h: 0.07,
      fill: { color: p.color },
      line: { color: p.color, width: 0 }
    });
    // Number circle
    slide.addShape(pres.shapes.OVAL, {
      x: x + 1.05, y: 1.5, w: 0.9, h: 0.9,
      fill: { color: p.color },
      line: { color: p.color, width: 0 }
    });
    slide.addText(p.num, {
      x: x + 1.05, y: 1.5, w: 0.9, h: 0.9,
      fontSize: 20, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    // Title
    slide.addText(p.title, {
      x: x + 0.15, y: 2.6, w: 2.7, h: 0.5,
      fontSize: 16, color: C.textDark, fontFace: "Calibri",
      bold: true, align: "center", margin: 0
    });
    // Desc
    slide.addText(p.desc, {
      x: x + 0.15, y: 3.18, w: 2.7, h: 1.8,
      fontSize: 11.5, color: "555555", fontFace: "Calibri",
      align: "left", valign: "top", margin: 0.08
    });
  });

  // Bottom arrow
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 3.8, y: 5.25, w: 2.4, h: 0.28,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("以上痛點，我們全部解決", {
    x: 3.8, y: 5.25, w: 2.4, h: 0.28,
    fontSize: 11, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", valign: "middle", margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 3: 解決方案全景
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.dark };

  // Title
  slide.addText("解決方案全景", {
    x: 0.5, y: 0.2, w: 9, h: 0.6,
    fontSize: 30, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("兩大系統協同運作，共用企業資料庫", {
    x: 0.5, y: 0.8, w: 9, h: 0.3,
    fontSize: 13, color: C.textLight, fontFace: "Calibri", margin: 0
  });

  // Left column - 文件管理
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.4, y: 1.25, w: 3.8, h: 3.9,
    fill: { color: C.primary },
    line: { color: C.accent, width: 1 },
    shadow: makeShadow()
  });
  slide.addText("文件管理系統", {
    x: 0.5, y: 1.35, w: 3.6, h: 0.5,
    fontSize: 16, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });

  const dmFeats = ["文件版本歷史", "簽核工作流程", "ISO 9001:2015 合規", "資料夾 / 權限管理", "浮水印 PDF 下載", "模糊搜尋 & 稽核記錄"];
  dmFeats.forEach((f, i) => {
    slide.addShape(pres.shapes.OVAL, {
      x: 0.65, y: 1.97 + i * 0.47, w: 0.16, h: 0.16,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 }
    });
    slide.addText(f, {
      x: 0.87, y: 1.93 + i * 0.47, w: 3.1, h: 0.25,
      fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
    });
  });

  // Center - shared DB
  slide.addShape(pres.shapes.OVAL, {
    x: 4.3, y: 2.1, w: 1.4, h: 1.4,
    fill: { color: C.secondary },
    line: { color: C.accent, width: 2 }
  });
  slide.addText([
    { text: "共用", options: { breakLine: true } },
    { text: "資料庫" }
  ], {
    x: 4.3, y: 2.1, w: 1.4, h: 1.4,
    fontSize: 13, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", valign: "middle", margin: 0
  });

  // Arrows
  slide.addShape(pres.shapes.LINE, {
    x: 4.2, y: 2.8, w: -0.05, h: 0,
    line: { color: C.accent, width: 2 }
  });
  // Left arrow
  slide.addText("←", {
    x: 3.95, y: 2.65, w: 0.5, h: 0.35,
    fontSize: 18, color: C.accent, fontFace: "Calibri",
    align: "center", margin: 0
  });
  // Right arrow
  slide.addText("→", {
    x: 5.55, y: 2.65, w: 0.5, h: 0.35,
    fontSize: 18, color: C.accent, fontFace: "Calibri",
    align: "center", margin: 0
  });

  // Right column - 即時通
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 5.8, y: 1.25, w: 3.8, h: 3.9,
    fill: { color: C.secondary },
    line: { color: C.accent, width: 1 },
    shadow: makeShadow()
  });
  slide.addText("即時通", {
    x: 5.9, y: 1.35, w: 3.6, h: 0.5,
    fontSize: 16, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });

  const imFeats = ["即時訊息聊天室", "檔案傳送 & 下載", "我的檔案歷史", "文件系統通知整合", "多人協作支援", "行動裝置友善"];
  imFeats.forEach((f, i) => {
    slide.addShape(pres.shapes.OVAL, {
      x: 6.05, y: 1.97 + i * 0.47, w: 0.16, h: 0.16,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 }
    });
    slide.addText(f, {
      x: 6.27, y: 1.93 + i * 0.47, w: 3.1, h: 0.25,
      fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
    });
  });

  // Bottom label — 縮小寬度避免溢出右側區塊
  slide.addText("共用 company_db", {
    x: 3.9, y: 3.55, w: 2.2, h: 0.3,
    fontSize: 9, color: C.textLight, fontFace: "Calibri",
    align: "center", margin: 0
  });
  slide.addText("統一使用者 · 權限 · 通知", {
    x: 3.9, y: 3.82, w: 2.2, h: 0.25,
    fontSize: 8.5, color: C.textLight, fontFace: "Calibri",
    align: "center", margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 4: 核心功能 — 文件管理
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("核心功能 — 文件管理", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("完整的企業文件生命週期管理", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  const features = [
    { icon: "V", color: "1A6E9E", title: "版本歷史管理", desc: "完整記錄每次修訂，可比對差異、回溯舊版，確保最新核准版本易於識別" },
    { icon: "F", color: "1A7A5E", title: "資料夾層級架構", desc: "支援多層資料夾與分頁，群組 / 使用者雙層權限控管，精細存取管理" },
    { icon: "W", color: "7D3C8C", title: "簽核工作流程", desc: "可設定多階段審查人，送審→審查→核准完整流程，範本與檔案類型關聯設定" },
    { icon: "S", color: "C0392B", title: "搜尋 & 批次匯入", desc: "跨欄位模糊搜尋 (編號/主旨/備註/部門)，支援批次匯入，資源回收桶保護" },
    { icon: "A", color: "B7950B", title: "稽核軌跡記錄", desc: "ISO 7.5 合規要求，所有操作全程記錄，下載附浮水印 PDF，確保可追溯性" },
    { icon: "E", color: "1A5C9E", title: "到期管理 & 外網存取", desc: "文件到期提醒 & 複審警示，透過 Cloudflare Tunnel 安全對外發布" },
  ];

  features.forEach((f, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = 0.35 + col * 3.2;
    const y = 1.1 + row * 2.08;

    slide.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 3.05, h: 1.9,
      fill: { color: C.white },
      line: { color: C.white, width: 0 },
      shadow: makeCardShadow()
    });
    // Color accent left bar
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 0.07, h: 1.9,
      fill: { color: f.color },
      line: { color: f.color, width: 0 }
    });
    // Icon circle
    slide.addShape(pres.shapes.OVAL, {
      x: x + 0.2, y: y + 0.18, w: 0.48, h: 0.48,
      fill: { color: f.color },
      line: { color: f.color, width: 0 }
    });
    slide.addText(f.icon, {
      x: x + 0.2, y: y + 0.18, w: 0.48, h: 0.48,
      fontSize: 16, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    // Title
    slide.addText(f.title, {
      x: x + 0.75, y: y + 0.18, w: 2.2, h: 0.4,
      fontSize: 13, color: C.textDark, fontFace: "Calibri",
      bold: true, margin: 0
    });
    // Desc
    slide.addText(f.desc, {
      x: x + 0.12, y: y + 0.7, w: 2.82, h: 1.1,
      fontSize: 11, color: "555555", fontFace: "Calibri",
      valign: "top", margin: 0.05
    });
  });
}

// ─────────────────────────────────────────────
// SLIDE 5: ISO 9001:2015 合規流程
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.white };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.secondary },
    line: { color: C.secondary, width: 0 }
  });
  slide.addText("ISO 9001:2015 合規流程", {
    x: 0.5, y: 0.1, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("文件管制符合 ISO 第 7.5 條要求 — 完整生命週期追蹤", {
    x: 0.5, y: 0.64, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // Steps flow
  const steps = [
    { label: "草稿", sub: "起草人員\n建立文件", color: "95A5A6", badge: "DRAFT" },
    { label: "送審", sub: "提交審查\n申請", color: "3498DB", badge: "PENDING" },
    { label: "審查中", sub: "審查人員\n進行審閱", color: "E67E22", badge: "REVIEW" },
    { label: "核准", sub: "主管核可\n簽核", color: "27AE60", badge: "APPROVED" },
    { label: "發行", sub: "正式發布\n通知相關人", color: C.primary, badge: "ISSUED" },
  ];

  // Flow connector line
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.8, y: 2.82, w: 8.4, h: 0.06,
    fill: { color: C.midBg },
    line: { color: C.midBg, width: 0 }
  });

  steps.forEach((s, i) => {
    const cx = 0.5 + i * 1.85;  // 縮小間距，避免第5步被裁切
    // Vertical connector from circle to line
    // Circle
    slide.addShape(pres.shapes.OVAL, {
      x: cx, y: 1.9, w: 1.0, h: 1.0,
      fill: { color: s.color },
      line: { color: s.color, width: 0 },
      shadow: makeShadow()
    });
    // Step number
    slide.addText(String(i + 1), {
      x: cx, y: 1.9, w: 1.0, h: 1.0,
      fontSize: 22, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    // Arrow between steps
    if (i < 4) {
      slide.addText("›", {
        x: cx + 1.02, y: 2.1, w: 0.35, h: 0.6,
        fontSize: 22, color: C.textLight, fontFace: "Calibri",
        align: "center", valign: "middle", margin: 0
      });
    }
    // Label
    slide.addText(s.label, {
      x: cx - 0.1, y: 3.0, w: 1.2, h: 0.4,
      fontSize: 14, color: C.textDark, fontFace: "Calibri",
      bold: true, align: "center", margin: 0
    });
    // Sub
    slide.addText(s.sub, {
      x: cx - 0.15, y: 3.42, w: 1.3, h: 0.6,
      fontSize: 10, color: C.textMid, fontFace: "Calibri",
      align: "center", margin: 0
    });
    // Badge
    slide.addShape(pres.shapes.RECTANGLE, {
      x: cx + 0.03, y: 4.15, w: 0.94, h: 0.28,
      fill: { color: s.color },
      line: { color: s.color, width: 0 }
    });
    slide.addText(s.badge, {
      x: cx + 0.03, y: 4.15, w: 0.94, h: 0.28,
      fontSize: 9, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
  });

  // Info boxes below
  const infos = [
    { title: "退回機制", desc: "審查不通過時可退回修改，保留退回意見紀錄" },
    { title: "版本鎖定", desc: "核准後文件自動鎖定，變更需重新走流程" },
    { title: "稽核記錄", desc: "每個狀態變更均記錄時間戳記與操作人員" },
  ];
  infos.forEach((info, i) => {
    const x = 0.5 + i * 3.1;
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 4.6, w: 2.9, h: 0.85,
      fill: { color: C.lightBg },
      line: { color: C.midBg, width: 1 }
    });
    slide.addText(info.title, {
      x: x + 0.1, y: 4.63, w: 2.7, h: 0.28,
      fontSize: 11, color: C.primary, fontFace: "Calibri",
      bold: true, margin: 0
    });
    slide.addText(info.desc, {
      x: x + 0.1, y: 4.9, w: 2.7, h: 0.42,
      fontSize: 10, color: C.textMid, fontFace: "Calibri", margin: 0
    });
  });
}

// ─────────────────────────────────────────────
// SLIDE 6: 簽核範本設定
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("簽核範本設定", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("可設定工作流程範本並關聯至特定檔案類型，自動套用審核階段", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // Table header
  const tableRows = [
    [
      { text: "檔案類型", options: { bold: true, color: C.white, fill: { color: C.primary }, align: "center" } },
      { text: "簽核範本", options: { bold: true, color: C.white, fill: { color: C.primary }, align: "center" } },
      { text: "審查層級", options: { bold: true, color: C.white, fill: { color: C.primary }, align: "center" } },
      { text: "適用部門", options: { bold: true, color: C.white, fill: { color: C.primary }, align: "center" } },
      { text: "狀態", options: { bold: true, color: C.white, fill: { color: C.primary }, align: "center" } },
    ],
    [
      { text: "SOP 作業程序書", options: { color: C.textDark } },
      { text: "三階審核", options: { color: C.textDark } },
      { text: "主管 → 品保 → 總經理", options: { color: "555555", fontSize: 10 } },
      { text: "品保 / 製造", options: { color: "555555" } },
      { text: "啟用", options: { color: "27AE60", bold: true } },
    ],
    [
      { text: "WI 作業指導書", options: { color: C.textDark } },
      { text: "雙階審核", options: { color: C.textDark } },
      { text: "主管 → 品保", options: { color: "555555", fontSize: 10 } },
      { text: "製造", options: { color: "555555" } },
      { text: "啟用", options: { color: "27AE60", bold: true } },
    ],
    [
      { text: "QP 品質計劃", options: { color: C.textDark } },
      { text: "四階審核", options: { color: C.textDark } },
      { text: "主管→品保→技術→總經理", options: { color: "555555", fontSize: 9 } },
      { text: "品保 / 技術", options: { color: "555555" } },
      { text: "啟用", options: { color: "27AE60", bold: true } },
    ],
    [
      { text: "RD 研發文件", options: { color: C.textDark } },
      { text: "單階審核", options: { color: C.textDark } },
      { text: "技術主管", options: { color: "555555", fontSize: 10 } },
      { text: "研發", options: { color: "555555" } },
      { text: "啟用", options: { color: "27AE60", bold: true } },
    ],
    [
      { text: "FM 表單", options: { color: C.textDark } },
      { text: "雙階審核", options: { color: C.textDark } },
      { text: "主管 → 品保", options: { color: "555555", fontSize: 10 } },
      { text: "全部門", options: { color: "555555" } },
      { text: "草稿", options: { color: "E67E22", bold: true } },
    ],
  ];

  slide.addTable(tableRows, {
    x: 0.4, y: 1.1, w: 9.2, h: 3.8,
    colW: [2.1, 1.7, 2.6, 1.6, 1.2],
    fontSize: 12,
    fontFace: "Calibri",
    border: { pt: 0.5, color: "D0E8F2" },
    fill: { color: C.white },
    autoPage: false,
    rowH: 0.55,
  });

  // Bottom note
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.4, y: 5.05, w: 9.2, h: 0.45,
    fill: { color: C.midBg },
    line: { color: C.midBg, width: 0 }
  });
  slide.addText("管理員可隨時新增、修改範本，並指定每個審核階段的負責人員與代理人", {
    x: 0.6, y: 5.07, w: 8.8, h: 0.35,
    fontSize: 11, color: C.textMid, fontFace: "Calibri",
    italic: true, margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 7: 權限與安全
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.dark };

  // Title
  slide.addText("權限與安全管理", {
    x: 0.5, y: 0.2, w: 9, h: 0.6,
    fontSize: 28, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("三層角色體系 + 精細資源存取控制", {
    x: 0.5, y: 0.8, w: 9, h: 0.3,
    fontSize: 13, color: C.textLight, fontFace: "Calibri", margin: 0
  });

  // Role cards
  const roles = [
    { role: "Admin\n管理員", color: C.primary, perms: ["系統設定與使用者管理", "全部文件讀取/編輯", "工作流程範本設定", "稽核記錄完整存取", "批次匯入 & 資源回收桶"] },
    { role: "Manager\n主管", color: C.secondary, perms: ["部門文件管理", "核准/退回文件申請", "部門稽核記錄查閱", "下載浮水印 PDF", "到期文件複審管理"] },
    { role: "Staff\n一般人員", color: "1A5276", perms: ["被授權資料夾存取", "送審新文件", "閱覽核准版本", "下載自身提交紀錄", "接收通知提醒"] },
  ];

  roles.forEach((r, i) => {
    const x = 0.35 + i * 3.2;
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.2, w: 3.0, h: 3.8,
      fill: { color: r.color },
      line: { color: C.accent, width: 0.5 },
      shadow: makeShadow()
    });
    slide.addText(r.role, {
      x: x + 0.1, y: 1.3, w: 2.8, h: 0.7,
      fontSize: 15, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", margin: 0
    });
    // Divider
    slide.addShape(pres.shapes.RECTANGLE, {
      x: x + 0.3, y: 2.1, w: 2.4, h: 0.03,
      fill: { color: C.accent, transparency: 40 },
      line: { color: C.accent, width: 0 }
    });
    r.perms.forEach((p, j) => {
      slide.addShape(pres.shapes.OVAL, {
        x: x + 0.25, y: 2.22 + j * 0.5, w: 0.14, h: 0.14,
        fill: { color: C.accent },
        line: { color: C.accent, width: 0 }
      });
      slide.addText(p, {
        x: x + 0.45, y: 2.18 + j * 0.5, w: 2.42, h: 0.28,
        fontSize: 11, color: C.midBg, fontFace: "Calibri", margin: 0
      });
    });
  });

  // Bottom security features
  const secFeats = ["HTTPS via Cloudflare Tunnel", "資料夾 & 分頁雙層授權", "操作全程 Log 記錄"];
  secFeats.forEach((s, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.35 + i * 3.2, y: 5.1, w: 3.0, h: 0.4,
      fill: { color: "0A3D57" },
      line: { color: C.accent, width: 0.5 }
    });
    slide.addText(s, {
      x: 0.35 + i * 3.2, y: 5.1, w: 3.0, h: 0.4,
      fontSize: 11, color: C.accent, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
  });
}

// ─────────────────────────────────────────────
// SLIDE 8: 即時通功能
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.secondary },
    line: { color: C.secondary, width: 0 }
  });
  slide.addText("即時通功能", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("企業內部即時溝通 + 與文件系統深度整合", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // Two column layout
  // Left: main features (large)
  const mainFeats = [
    { icon: "C", color: "2471A3", title: "即時訊息聊天室", desc: "建立多個主題聊天室，支援多人即時對話，訊息即時同步，不遺漏任何重要溝通。" },
    { icon: "F", color: "1A7A5E", title: "檔案附件傳送", desc: "在聊天室中直接傳送文件、圖片、附件，支援預覽與下載，完整記錄傳輸歷史。" },
    { icon: "H", color: "7D3C8C", title: "我的檔案歷史", desc: "一覽所有曾下載的檔案，包含下載時間、來源聊天室，方便快速重新存取。" },
  ];

  mainFeats.forEach((f, i) => {
    const y = 1.1 + i * 1.5;
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.35, y, w: 5.4, h: 1.35,
      fill: { color: C.white },
      line: { color: C.white, width: 0 },
      shadow: makeCardShadow()
    });
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.35, y, w: 0.07, h: 1.35,
      fill: { color: f.color },
      line: { color: f.color, width: 0 }
    });
    slide.addShape(pres.shapes.OVAL, {
      x: 0.55, y: y + 0.22, w: 0.55, h: 0.55,
      fill: { color: f.color },
      line: { color: f.color, width: 0 }
    });
    slide.addText(f.icon, {
      x: 0.55, y: y + 0.22, w: 0.55, h: 0.55,
      fontSize: 18, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    slide.addText(f.title, {
      x: 1.2, y: y + 0.18, w: 4.3, h: 0.38,
      fontSize: 14, color: C.textDark, fontFace: "Calibri",
      bold: true, margin: 0
    });
    slide.addText(f.desc, {
      x: 1.2, y: y + 0.58, w: 4.3, h: 0.65,
      fontSize: 11, color: "555555", fontFace: "Calibri",
      valign: "top", margin: 0
    });
  });

  // Right: integration highlight
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 5.95, y: 1.1, w: 3.7, h: 4.35,
    fill: { color: C.primary },
    line: { color: C.accent, width: 1 },
    shadow: makeShadow()
  });
  slide.addText("文件系統整合", {
    x: 6.05, y: 1.2, w: 3.5, h: 0.45,
    fontSize: 15, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.3, y: 1.68, w: 3.0, h: 0.03,
    fill: { color: C.accent, transparency: 40 },
    line: { color: C.accent, width: 0 }
  });

  const integrations = [
    "文件核准時自動推送通知",
    "簽核進度更新即時提醒",
    "到期文件複審警示",
    "新版本發布通知",
    "退回意見即時傳達",
    "跨系統統一登入 (SSO)",
  ];
  integrations.forEach((item, i) => {
    slide.addShape(pres.shapes.OVAL, {
      x: 6.15, y: 1.82 + i * 0.52, w: 0.16, h: 0.16,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 }
    });
    slide.addText(item, {
      x: 6.37, y: 1.78 + i * 0.52, w: 3.1, h: 0.28,
      fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
    });
  });

  // Bottom badge
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.15, y: 5.0, w: 3.3, h: 0.32,
    fill: { color: C.accent },
    line: { color: C.accent, width: 0 }
  });
  slide.addText("FastAPI WebSocket 即時推送", {
    x: 6.15, y: 5.0, w: 3.3, h: 0.32,
    fontSize: 10, color: C.dark, fontFace: "Calibri",
    bold: true, align: "center", valign: "middle", margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 9: 搜尋與稽核
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.white };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("搜尋 & 稽核軌跡", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("快速定位文件 + 完整合規記錄", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // Left: Search
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.35, y: 1.1, w: 4.5, h: 4.35,
    fill: { color: C.lightBg },
    line: { color: C.midBg, width: 1 },
    shadow: makeShadow()
  });
  slide.addText("模糊搜尋引擎", {
    x: 0.5, y: 1.2, w: 4.2, h: 0.45,
    fontSize: 16, color: C.primary, fontFace: "Calibri",
    bold: true, margin: 0
  });

  // Mock search bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.75, w: 4.0, h: 0.45,
    fill: { color: C.white },
    line: { color: C.secondary, width: 1.5 }
  });
  slide.addText("搜尋文件編號、主旨、備註...", {
    x: 0.6, y: 1.78, w: 3.6, h: 0.38,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    italic: true, valign: "middle", margin: 0
  });

  const searchFields = [
    { label: "文件編號", example: "SOP-001, WI-003..." },
    { label: "文件主旨", example: "關鍵字模糊匹配" },
    { label: "備  注", example: "說明欄位全文搜尋" },
    { label: "部  門", example: "品保、製造、研發..." },
    { label: "資料夾", example: "按資料夾結構篩選" },
  ];
  searchFields.forEach((f, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.5, y: 2.35 + i * 0.52, w: 4.05, h: 0.44,
      fill: { color: C.white },
      line: { color: C.midBg, width: 0.5 }
    });
    slide.addText(f.label, {
      x: 0.62, y: 2.37 + i * 0.52, w: 1.2, h: 0.3,
      fontSize: 11, color: C.primary, fontFace: "Calibri",
      bold: true, margin: 0
    });
    slide.addText(f.example, {
      x: 1.85, y: 2.37 + i * 0.52, w: 2.55, h: 0.3,
      fontSize: 11, color: C.textMid, fontFace: "Calibri", margin: 0
    });
  });

  slide.addText("PostgreSQL ILIKE 跨欄位模糊比對", {
    x: 0.5, y: 5.0, w: 4.1, h: 0.3,
    fontSize: 10, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });

  // Divider
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 5.0, y: 1.1, w: 0.03, h: 4.35,
    fill: { color: C.midBg },
    line: { color: C.midBg, width: 0 }
  });

  // Right: Audit Trail
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 5.15, y: 1.1, w: 4.5, h: 4.35,
    fill: { color: C.lightBg },
    line: { color: C.midBg, width: 1 },
    shadow: makeShadow()
  });
  slide.addText("稽核軌跡記錄", {
    x: 5.3, y: 1.2, w: 4.2, h: 0.45,
    fontSize: 16, color: C.primary, fontFace: "Calibri",
    bold: true, margin: 0
  });

  const auditItems = [
    { time: "10:23", user: "王品保", action: "核准文件 SOP-002 v3", color: "27AE60" },
    { time: "09:45", user: "李主管", action: "送審 WI-015 v2", color: "3498DB" },
    { time: "09:12", user: "張工程師", action: "下載 QP-001 (浮水印)", color: C.primary },
    { time: "昨天", user: "陳品保", action: "退回 SOP-008 — 需修改", color: "E74C3C" },
    { time: "昨天", user: "系統", action: "FM-003 即將到期提醒", color: "E67E22" },
  ];
  auditItems.forEach((a, i) => {
    slide.addShape(pres.shapes.OVAL, {
      x: 5.25, y: 1.82 + i * 0.6, w: 0.18, h: 0.18,
      fill: { color: a.color },
      line: { color: a.color, width: 0 }
    });
    slide.addText(a.time, {
      x: 5.5, y: 1.78 + i * 0.6, w: 0.6, h: 0.28,
      fontSize: 10, color: C.textLight, fontFace: "Calibri",
      margin: 0
    });
    slide.addText(a.user, {
      x: 6.12, y: 1.78 + i * 0.6, w: 1.0, h: 0.28,
      fontSize: 11, color: C.textDark, fontFace: "Calibri",
      bold: true, margin: 0
    });
    slide.addText(a.action, {
      x: 5.5, y: 2.0 + i * 0.6, w: 3.8, h: 0.24,
      fontSize: 10, color: C.textMid, fontFace: "Calibri",
      margin: 0
    });
  });

  slide.addText("符合 ISO 9001:2015 第 7.5 條文件化資訊要求", {
    x: 5.3, y: 5.0, w: 4.2, h: 0.3,
    fontSize: 10, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 10: 行動裝置支援
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.secondary },
    line: { color: C.secondary, width: 0 }
  });
  slide.addText("行動裝置支援", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("Bootstrap 5 RWD — 桌面、平板、手機全覆蓋", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // Left: feature bullets
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.35, y: 1.1, w: 5.4, h: 4.3,
    fill: { color: C.white },
    line: { color: C.midBg, width: 1 },
    shadow: makeShadow()
  });

  const mobileFeats = [
    { title: "全寬度側滑面板", desc: "導覽選單以動畫方式從側邊滑入，觸控友善的開關按鈕，不遮蔽主要內容區域。" },
    { title: "自適應表格佈局", desc: "文件列表在小螢幕自動調整欄位顯示，優先呈現最重要的資訊 (文件名稱、狀態)。" },
    { title: "觸控優化操作", desc: "按鈕、連結尺寸符合觸控目標規範，手勢滑動支援，下拉選單適合手指操作。" },
    { title: "Cloudflare Tunnel 外網", desc: "員工可透過 HTTPS 安全連接，無需 VPN，出差或在家均可存取企業文件系統。" },
  ];

  mobileFeats.forEach((f, i) => {
    const y = 1.2 + i * 1.0;
    // Number badge
    slide.addShape(pres.shapes.OVAL, {
      x: 0.5, y: y, w: 0.38, h: 0.38,
      fill: { color: C.primary },
      line: { color: C.primary, width: 0 }
    });
    slide.addText(String(i + 1), {
      x: 0.5, y: y, w: 0.38, h: 0.38,
      fontSize: 13, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    slide.addText(f.title, {
      x: 1.0, y: y, w: 4.5, h: 0.35,
      fontSize: 13, color: C.textDark, fontFace: "Calibri",
      bold: true, margin: 0
    });
    slide.addText(f.desc, {
      x: 1.0, y: y + 0.37, w: 4.5, h: 0.5,
      fontSize: 11, color: "555555", fontFace: "Calibri",
      margin: 0
    });
  });

  // Right: device illustration (mock phone frame)
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.0, y: 1.1, w: 3.65, h: 4.3,
    fill: { color: C.primary },
    line: { color: C.accent, width: 1.5 },
    shadow: makeShadow()
  });
  slide.addText("行動裝置預覽", {
    x: 6.1, y: 1.2, w: 3.45, h: 0.4,
    fontSize: 13, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });

  // Mock mobile UI elements
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.2, y: 1.7, w: 3.25, h: 0.5,
    fill: { color: C.secondary },
    line: { color: C.secondary, width: 0 }
  });
  slide.addText("文件管理系統  ≡", {
    x: 6.25, y: 1.72, w: 3.15, h: 0.35,
    fontSize: 12, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });

  const mockItems = ["SOP-001 作業程序書 v3", "WI-005 焊接指導書 v2", "QP-002 品質計劃 v1", "FM-012 檢驗表單 v1"];
  mockItems.forEach((item, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 6.2, y: 2.28 + i * 0.65, w: 3.25, h: 0.55,
      fill: { color: i % 2 === 0 ? "0A3D57" : "0D4A6B" },
      line: { color: "0D4A6B", width: 0 }
    });
    slide.addText(item, {
      x: 6.3, y: 2.3 + i * 0.65, w: 2.3, h: 0.3,
      fontSize: 10, color: C.midBg, fontFace: "Calibri", margin: 0
    });
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 8.62, y: 2.34 + i * 0.65, w: 0.65, h: 0.22,
      fill: { color: "27AE60" },
      line: { color: "27AE60", width: 0 }
    });
    slide.addText("核准", {
      x: 8.62, y: 2.34 + i * 0.65, w: 0.65, h: 0.22,
      fontSize: 9, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
  });

  slide.addShape(pres.shapes.RECTANGLE, {
    x: 6.2, y: 4.9, w: 3.25, h: 0.38,
    fill: { color: C.accent },
    line: { color: C.accent, width: 0 }
  });
  slide.addText("+ 新增文件", {
    x: 6.2, y: 4.9, w: 3.25, h: 0.38,
    fontSize: 11, color: C.dark, fontFace: "Calibri",
    bold: true, align: "center", valign: "middle", margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 11: 技術架構
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.dark };

  slide.addText("技術架構", {
    x: 0.5, y: 0.15, w: 9, h: 0.6,
    fontSize: 30, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("自建部署、輕量級、易於維護的現代化技術棧", {
    x: 0.5, y: 0.75, w: 9, h: 0.3,
    fontSize: 13, color: C.textLight, fontFace: "Calibri", margin: 0
  });

  // Architecture layers
  // Layer 1: Client
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 1.15, w: 9.4, h: 0.85,
    fill: { color: "0A3D57" },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("客戶端 (Browser / Mobile)", {
    x: 0.5, y: 1.18, w: 2.5, h: 0.3,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });
  const clientTech = ["Bootstrap 5 RWD", "HTML5 / CSS3", "JavaScript ES6", "WebSocket Client"];
  clientTech.forEach((t, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.5 + i * 2.25, y: 1.5, w: 2.1, h: 0.38,
      fill: { color: C.secondary },
      line: { color: C.secondary, width: 0 }
    });
    slide.addText(t, {
      x: 0.5 + i * 2.25, y: 1.52, w: 2.1, h: 0.34,
      fontSize: 11, color: C.white, fontFace: "Calibri",
      align: "center", valign: "middle", bold: true, margin: 0
    });
  });

  // Arrow down
  slide.addText("↓", {
    x: 4.7, y: 2.1, w: 0.6, h: 0.3,
    fontSize: 16, color: C.accent, fontFace: "Calibri",
    align: "center", margin: 0
  });

  // Layer 2: App Server
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 2.45, w: 9.4, h: 0.85,
    fill: { color: C.primary },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("應用層", {
    x: 0.5, y: 2.48, w: 1.5, h: 0.3,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });
  const appTech = ["Flask 3.0 (文件管理)", "FastAPI (即時通 + WS)", "Jinja2 Templates", "psycopg2 (直連 PG)"];
  appTech.forEach((t, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.5 + i * 2.25, y: 2.82, w: 2.1, h: 0.38,
      fill: { color: "1A5C7A" },
      line: { color: C.accent, width: 0.5 }
    });
    slide.addText(t, {
      x: 0.5 + i * 2.25, y: 2.84, w: 2.1, h: 0.34,
      fontSize: 11, color: C.white, fontFace: "Calibri",
      align: "center", valign: "middle", bold: true, margin: 0
    });
  });

  // Arrow down
  slide.addText("↓", {
    x: 4.7, y: 3.4, w: 0.6, h: 0.3,
    fontSize: 16, color: C.accent, fontFace: "Calibri",
    align: "center", margin: 0
  });

  // Layer 3: Database
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 3.75, w: 4.5, h: 0.85,
    fill: { color: "0D2B3D" },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("資料庫", {
    x: 0.5, y: 3.78, w: 1.5, h: 0.28,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });
  slide.addText("PostgreSQL (company_db)", {
    x: 0.5, y: 4.12, w: 4.1, h: 0.35,
    fontSize: 12, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });

  // Layer 4: Network
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 5.1, y: 3.75, w: 4.6, h: 0.85,
    fill: { color: "0D2B3D" },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("網路 / 部署", {
    x: 5.3, y: 3.78, w: 2.0, h: 0.28,
    fontSize: 11, color: C.textLight, fontFace: "Calibri",
    italic: true, margin: 0
  });
  slide.addText("Windows Server + Cloudflare Tunnel (HTTPS)", {
    x: 5.3, y: 4.12, w: 4.2, h: 0.35,
    fontSize: 12, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });

  // Bottom note
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 4.75, w: 9.4, h: 0.7,
    fill: { color: "051520" },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("自建部署優勢：資料完全掌控  ·  無月費  ·  可客製化  ·  低延遲  ·  離線可用", {
    x: 0.5, y: 4.82, w: 9.0, h: 0.38,
    fontSize: 12, color: C.accent, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });
}

// ─────────────────────────────────────────────
// SLIDE 12: 商業價值
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.lightBg };

  // Header
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 1.0,
    fill: { color: C.primary },
    line: { color: C.primary, width: 0 }
  });
  slide.addText("商業價值", {
    x: 0.5, y: 0.08, w: 9, h: 0.55,
    fontSize: 26, color: C.white, fontFace: "Calibri",
    bold: true, margin: 0
  });
  slide.addText("可量化的效益，幫助企業達到合規並提升效率", {
    x: 0.5, y: 0.62, w: 9, h: 0.28,
    fontSize: 12, color: C.midBg, fontFace: "Calibri", margin: 0
  });

  // 3 big stat callouts
  const stats = [
    { num: "70%", label: "簽核時間縮短", sub: "自動化流程取代人工傳遞，審核瓶頸即時可見，平均簽核時間由 3 天降至 1 天以內", color: C.primary },
    { num: "100%", label: "ISO 稽核通過率", sub: "完整的文件記錄與軌跡追蹤，確保 ISO 9001:2015 第 7.5 條合規，稽核準備時間大幅減少", color: C.secondary },
    { num: "3x", label: "文件搜尋效率", sub: "模糊搜尋引擎讓員工在秒內找到所需文件，告別翻資料夾的時代，提升日常作業效率", color: "1A5C7A" },
  ];

  stats.forEach((s, i) => {
    const x = 0.35 + i * 3.2;
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.15, w: 3.05, h: 3.7,
      fill: { color: C.white },
      line: { color: C.white, width: 0 },
      shadow: makeShadow()
    });
    // Top color band
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.15, w: 3.05, h: 0.08,
      fill: { color: s.color },
      line: { color: s.color, width: 0 }
    });
    // Big stat number
    slide.addText(s.num, {
      x: x + 0.1, y: 1.4, w: 2.85, h: 1.0,
      fontSize: 56, color: s.color, fontFace: "Calibri",
      bold: true, align: "center", margin: 0
    });
    // Label
    slide.addShape(pres.shapes.RECTANGLE, {
      x: x + 0.25, y: 2.5, w: 2.55, h: 0.4,
      fill: { color: s.color },
      line: { color: s.color, width: 0 }
    });
    slide.addText(s.label, {
      x: x + 0.25, y: 2.5, w: 2.55, h: 0.4,
      fontSize: 13, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
    // Sub
    slide.addText(s.sub, {
      x: x + 0.15, y: 3.0, w: 2.75, h: 1.7,
      fontSize: 11, color: "555555", fontFace: "Calibri",
      valign: "top", margin: 0.08
    });
  });

  // Bottom row
  const extras = [
    "零月費訂閱 — 自建部署一次性成本",
    "跨裝置存取 — 桌機/手機/平板",
    "快速部署 — 數日內上線投入使用",
  ];
  extras.forEach((e, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.35 + i * 3.2, y: 4.98, w: 3.05, h: 0.5,
      fill: { color: C.primary },
      line: { color: C.primary, width: 0 }
    });
    slide.addText(e, {
      x: 0.35 + i * 3.2, y: 4.98, w: 3.05, h: 0.5,
      fontSize: 11, color: C.white, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0.05
    });
  });
}

// ─────────────────────────────────────────────
// SLIDE 13: 結語 / Closing
// ─────────────────────────────────────────────
{
  let slide = pres.addSlide();
  slide.background = { color: C.dark };

  // Decorative shapes
  slide.addShape(pres.shapes.OVAL, {
    x: -0.5, y: -0.5, w: 3.5, h: 3.5,
    fill: { color: C.primary, transparency: 40 },
    line: { color: C.primary, width: 0 }
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 7.5, y: 3.0, w: 3.0, h: 3.0,
    fill: { color: C.secondary, transparency: 50 },
    line: { color: C.secondary, width: 0 }
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 8.5, y: 0.2, w: 1.5, h: 1.5,
    fill: { color: C.accent, transparency: 60 },
    line: { color: C.accent, width: 0 }
  });

  // Top accent
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 1.5, y: 0.55, w: 7.0, h: 0.05,
    fill: { color: C.accent, transparency: 30 },
    line: { color: C.accent, width: 0 }
  });

  // Title
  slide.addText("開始您的數位文件管理之旅", {
    x: 0.8, y: 0.75, w: 8.4, h: 0.75,
    fontSize: 30, color: C.white, fontFace: "Calibri",
    bold: true, align: "center", margin: 0
  });

  slide.addText("文件管理系統 + 即時通 — 企業合規管理一站式解決方案", {
    x: 1.0, y: 1.55, w: 8.0, h: 0.4,
    fontSize: 15, color: C.midBg, fontFace: "Calibri",
    align: "center", margin: 0
  });

  // CTA box
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 2.5, y: 2.1, w: 5.0, h: 0.7,
    fill: { color: C.accent },
    line: { color: C.accent, width: 0 },
    shadow: makeShadow()
  });
  slide.addText("立即申請產品演示", {
    x: 2.5, y: 2.1, w: 5.0, h: 0.7,
    fontSize: 20, color: C.dark, fontFace: "Calibri",
    bold: true, align: "center", valign: "middle", margin: 0
  });

  // Feature summary pills
  const pills = ["ISO 9001:2015 合規", "自建部署", "行動裝置支援", "即時通整合"];
  pills.forEach((p, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.5 + i * 2.25, y: 2.98, w: 2.1, h: 0.38,
      fill: { color: "0A3D57" },
      line: { color: C.accent, width: 0.5 }
    });
    slide.addText(p, {
      x: 0.5 + i * 2.25, y: 2.98, w: 2.1, h: 0.38,
      fontSize: 11, color: C.accent, fontFace: "Calibri",
      bold: true, align: "center", valign: "middle", margin: 0
    });
  });

  // Contact section
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 3.5, w: 9.0, h: 1.8,
    fill: { color: C.primary },
    line: { color: C.accent, width: 0.5 }
  });
  slide.addText("聯絡資訊", {
    x: 1.0, y: 3.62, w: 3.0, h: 0.38,
    fontSize: 14, color: C.accent, fontFace: "Calibri",
    bold: true, margin: 0
  });

  const contacts = [
    "系統技術支援：IT 部門",
    "部署環境：Windows Server (自建)",
    "資料庫：PostgreSQL (company_db)",
    "外網存取：Cloudflare Tunnel",
  ];
  contacts.forEach((c, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    slide.addShape(pres.shapes.OVAL, {
      x: 1.0 + col * 4.5, y: 4.1 + row * 0.45, w: 0.14, h: 0.14,
      fill: { color: C.accent },
      line: { color: C.accent, width: 0 }
    });
    slide.addText(c, {
      x: 1.2 + col * 4.5, y: 4.06 + row * 0.45, w: 3.8, h: 0.28,
      fontSize: 11, color: C.midBg, fontFace: "Calibri", margin: 0
    });
  });

  // Bottom bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.2, w: 10, h: 0.425,
    fill: { color: "021520" },
    line: { color: "021520", width: 0 }
  });
  slide.addText("文件管理系統 + 即時通  v2.0  |  2026  |  企業資訊部", {
    x: 0, y: 5.22, w: 10, h: 0.35,
    fontSize: 10, color: C.textLight, fontFace: "Calibri",
    align: "center", margin: 0
  });
}

// ─────────────────────────────────────────────
// Write output
// ─────────────────────────────────────────────
pres.writeFile({ fileName: "E:/claude/文件管理/產品說明.pptx" })
  .then(() => { console.log("Done: 產品說明.pptx"); })
  .catch(err => { console.error("Error:", err); process.exit(1); });
