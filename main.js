const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    title: "BoxJM - Orçamentos",
    backgroundColor: '#000000',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  // Carrega o arquivo index.html que será gerado pelo 'npx expo export --platform web'
  const indexPath = path.join(__dirname, 'dist', 'index.html');
  win.loadFile(indexPath).catch((e) => {
    console.error("Erro ao carregar o app. Você já rodou 'npx expo export --platform web'?", e);
  });

  // Opcional: Abre ferramentas de desenvolvedor (F12)
  // win.webContents.openDevTools();
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
