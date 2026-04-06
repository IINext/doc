/* ── 文件管理系統 共用 JS ─────────────────────────────── */

/* Toast 通知（供各頁面共用） */
function showToast(msg, type) {
  const el = document.createElement('div');
  el.className = 'toast-msg' + (type === 'warning' ? ' toast-warning' : type === 'danger' ? ' toast-danger' : '');
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 3000);
}

/* HTML 轉義 */
function escHtml(s) {
  return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* CSRF-safe fetch POST（application/x-www-form-urlencoded） */
function postForm(url, data) {
  const body = Object.entries(data)
    .map(([k,v]) => encodeURIComponent(k) + '=' + encodeURIComponent(v ?? ''))
    .join('&');
  return fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });
}

/* 確認對話框 + POST */
function confirmPost(msg, url, data, successCb) {
  if (!confirm(msg)) return;
  postForm(url, data || {})
    .then(r => r.json().catch(() => ({})))
    .then(j => {
      if (j.ok || j.success) {
        showToast(j.msg || '操作成功');
        if (successCb) successCb(j);
      } else {
        showToast(j.msg || '操作失敗', 'danger');
      }
    })
    .catch(() => showToast('網路錯誤', 'danger'));
}

/* 自動收合 sidebar（小螢幕） */
document.addEventListener('DOMContentLoaded', () => {
  // 讓 flash 訊息 3 秒後自動消失
  document.querySelectorAll('.alert-dismissible').forEach(el => {
    setTimeout(() => {
      const btn = el.querySelector('.btn-close');
      if (btn) btn.click();
    }, 4000);
  });
});
