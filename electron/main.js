const { app, BrowserWindow, protocol, net, Menu, shell, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');

// بروتوكول app:// يُعامل كسياق آمن (Secure Context): يدعم التشفير وlocalStorage وIndexedDB وWebAuthn
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true } }
]);

const WWW = path.join(__dirname, '..', 'www');
let win;

function createWindow() {
  win = new BrowserWindow({
    width: 1366, height: 860, minWidth: 900, minHeight: 600,
    title: 'MMY.YE',
    icon: path.join(__dirname, '..', 'build', 'icon.png'),
    backgroundColor: '#060A07',
    autoHideMenuBar: true,
    show: false,
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, preload: path.join(__dirname, 'preload.js') }
  });
  Menu.setApplicationMenu(null);
  // لا تُعرض النافذة إلا بعد جاهزية المحتوى (بدون وميض شاشة فارغة)
  win.once('ready-to-show', () => win.show());
  win.loadURL('app://mmy/index.html');
  // الروابط الخارجية تُفتح في المتصفح وليس داخل البرنامج
  win.webContents.setWindowOpenHandler(({ url }) => { if (/^https?:/.test(url)) shell.openExternal(url); return { action: 'deny' }; });
  win.webContents.on('will-navigate', (e, url) => { if (!url.startsWith('app://')) { e.preventDefault(); if (/^https?:/.test(url)) shell.openExternal(url); } });
}

// حفظ ملف (نسخة احتياطية / أرشيف) بنافذة «حفظ باسم» — يمكن اختيار أي قرص أو فلاشة خارجية
ipcMain.handle('mmy:save-file', async (event, { name, data }) => {
  const url = (event.senderFrame && event.senderFrame.url) || '';
  if (!url.startsWith('app://')) throw new Error('غير مسموح');
  const safe = String(name).replace(/[\\/:*?"<>|]/g, '_');
  const ext = path.extname(safe).replace('.', '');
  const r = await dialog.showSaveDialog(win, {
    title: 'حفظ الملف',
    defaultPath: path.join(app.getPath('documents'), safe),
    filters: ext ? [{ name: ext.toUpperCase(), extensions: [ext] }, { name: 'All', extensions: ['*'] }] : undefined
  });
  if (r.canceled || !r.filePath) return { saved: false };
  await fs.promises.writeFile(r.filePath, Buffer.from(data));
  return { saved: true, path: r.filePath };
});

app.whenReady().then(() => {
  protocol.handle('app', (req) => {
    const u = new URL(req.url);
    let rel = decodeURIComponent(u.pathname);
    if (rel === '/' || rel === '') rel = '/index.html';
    const file = path.normalize(path.join(WWW, rel));
    if (!file.startsWith(WWW)) return new Response('Forbidden', { status: 403 });
    return net.fetch(pathToFileURL(file).toString());
  });
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

// نسخة واحدة فقط من البرنامج
if (!app.requestSingleInstanceLock()) app.quit();
else app.on('second-instance', () => { if (win) { if (win.isMinimized()) win.restore(); win.focus(); } });

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
