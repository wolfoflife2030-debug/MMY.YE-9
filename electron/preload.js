const { contextBridge, ipcRenderer } = require('electron');

// واجهة محدودة جداً للصفحة: حفظ ملف في مكان يختاره المستخدم (قرص / فلاشة)
contextBridge.exposeInMainWorld('mmyDesktop', {
  saveFile: (name, data) => ipcRenderer.invoke('mmy:save-file', { name: String(name || 'file'), data })
});
