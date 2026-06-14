
const settingsKey = 'djKaraokeHostShellSettings.v1';

const defaultSettings = Object.freeze({
  venue: "D & J's Demo Venue",
  connectionMode: 'local-only',
  hostDisplayName: 'Main Host Laptop',
  demoMode: 'enabled',
  authorizedMediaFolder: 'D:\\Karaoke\\Authorized',
  serverUrl: 'http://localhost:4000',
  requestServerPort: '7070',
  uiScale: '100'
});

const safeDemoData = Object.freeze({
  singerCount: 3,
  songCount: 3,
  requestCount: 2,
  mediaFilesIncluded: false
});

function loadSettings() {
  try {
    const savedSettings = JSON.parse(localStorage.getItem(settingsKey) || '{}');
    return { ...defaultSettings, ...savedSettings };
  } catch {
    return { ...defaultSettings };
  }
}

function saveSettings(settings) {
  localStorage.setItem(settingsKey, JSON.stringify(settings));
}

function showToast(message, tone = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast toast-${tone}`;
  toast.textContent = message;
  toastRegion.append(toast);

  window.setTimeout(() => {
    toast.remove();
  }, 4200);
}

function showConfirmationDialog() {
  confirmationDialog.showModal();
}

function appendActivityLog(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  activityLogList.prepend(item);
}

function showSafeErrorDialog() {
  safeErrorDialog.showModal();
  appendActivityLog('Safe error', 'Displayed a user-safe placeholder error message.');
}

function showDiagnosticsPreview() {
  diagnosticsDialog.showModal();
  appendActivityLog('Diagnostics', 'Opened diagnostics export preview without writing files.');
}

const navItems = Array.from(document.querySelectorAll('.nav-item'));
const shortcutHelpButton = document.querySelector('#shortcutHelpButton');
const shortcutDialog = document.querySelector('#shortcutDialog');
const closeShortcutsButton = document.querySelector('#closeShortcutsButton');
const firstRunButton = document.querySelector('#firstRunButton');
const firstRunDialog = document.querySelector('#firstRunDialog');
const closeFirstRunButton = document.querySelector('#closeFirstRunButton');
const songSearchInput = document.querySelector('#songSearchInput');
const settingsForm = document.querySelector('#settingsForm');
const venueSelector = document.querySelector('#venueSelector');
const connectionMode = document.querySelector('#connectionMode');
const hostDisplayName = document.querySelector('#hostDisplayName');
const demoMode = document.querySelector('#demoMode');
const authorizedMediaFolder = document.querySelector('#authorizedMediaFolder');
const serverUrl = document.querySelector('#serverUrl');
const requestServerPort = document.querySelector('#requestServerPort');
const uiScale = document.querySelector('#uiScale');
const settingsStatus = document.querySelector('#settingsStatus');
const toastRegion = document.querySelector('#toastRegion');
const toastDemoButton = document.querySelector('#toastDemoButton');
const confirmDemoButton = document.querySelector('#confirmDemoButton');
const confirmationDialog = document.querySelector('#confirmationDialog');
const cancelConfirmationButton = document.querySelector('#cancelConfirmationButton');
const acceptConfirmationButton = document.querySelector('#acceptConfirmationButton');
const activityLogList = document.querySelector('#activityLogList');
const safeErrorButton = document.querySelector('#safeErrorButton');
const toastFollowUpButton = document.querySelector('#toastFollowUpButton');
const diagnosticsPreviewButton = document.querySelector('#diagnosticsPreviewButton');
const safeErrorDialog = document.querySelector('#safeErrorDialog');
const closeSafeErrorButton = document.querySelector('#closeSafeErrorButton');
const diagnosticsDialog = document.querySelector('#diagnosticsDialog');
const closeDiagnosticsButton = document.querySelector('#closeDiagnosticsButton');

function applySettings(settings) {
  venueSelector.value = settings.venue;
  connectionMode.value = settings.connectionMode;
  hostDisplayName.value = settings.hostDisplayName;
  demoMode.value = settings.demoMode;
  authorizedMediaFolder.value = settings.authorizedMediaFolder;
  serverUrl.value = settings.serverUrl;
  requestServerPort.value = settings.requestServerPort;
  uiScale.value = settings.uiScale;
  document.querySelector('.host-shell').dataset.connectionState = settings.connectionMode;
  document.documentElement.style.fontSize = `${settings.uiScale}%`;
}

for (const item of navItems) {
  item.addEventListener('click', () => {
    for (const navItem of navItems) navItem.classList.remove('active');
    item.classList.add('active');
  });
}

shortcutHelpButton.addEventListener('click', () => shortcutDialog.showModal());
closeShortcutsButton.addEventListener('click', () => shortcutDialog.close());
firstRunButton.addEventListener('click', () => firstRunDialog.showModal());
closeFirstRunButton.addEventListener('click', () => firstRunDialog.close());
toastDemoButton.addEventListener('click', () => showToast('Safe host notification preview. No media action was started.', 'success'));
confirmDemoButton.addEventListener('click', () => showConfirmationDialog());
cancelConfirmationButton.addEventListener('click', () => confirmationDialog.close());
acceptConfirmationButton.addEventListener('click', () => {
  confirmationDialog.close();
  showToast('Placeholder confirmed. No destructive action was performed.', 'info');
  appendActivityLog('Confirmation', 'Safe placeholder confirmation accepted.');
});
safeErrorButton.addEventListener('click', () => showSafeErrorDialog());
toastFollowUpButton.addEventListener('click', () => {
  showToast('Follow-up notification saved to the local activity log.', 'info');
  appendActivityLog('Toast', 'Follow-up notification displayed.');
});
diagnosticsPreviewButton.addEventListener('click', () => showDiagnosticsPreview());
closeSafeErrorButton.addEventListener('click', () => safeErrorDialog.close());
closeDiagnosticsButton.addEventListener('click', () => diagnosticsDialog.close());

settingsForm.addEventListener('submit', (event) => {
  event.preventDefault();

  saveSettings({
    venue: venueSelector.value,
    connectionMode: connectionMode.value,
    hostDisplayName: hostDisplayName.value.trim() || defaultSettings.hostDisplayName,
    demoMode: demoMode.value,
    authorizedMediaFolder: authorizedMediaFolder.value.trim() || defaultSettings.authorizedMediaFolder,
    serverUrl: serverUrl.value.trim() || defaultSettings.serverUrl,
    requestServerPort: requestServerPort.value,
    uiScale: uiScale.value
  });

  applySettings(loadSettings());
  settingsStatus.textContent = 'Settings saved locally in this browser only. No folder scan or server connection was started.';
});

document.addEventListener('keydown', (event) => {
  const activeElement = document.activeElement;
  const isTyping = activeElement && ['INPUT', 'SELECT', 'TEXTAREA'].includes(activeElement.tagName);

  if (event.key === 'Escape') {
    if (shortcutDialog.open) shortcutDialog.close();
    if (firstRunDialog.open) firstRunDialog.close();
    if (confirmationDialog.open) confirmationDialog.close();
    if (safeErrorDialog.open) safeErrorDialog.close();
    if (diagnosticsDialog.open) diagnosticsDialog.close();
    return;
  }

  if (isTyping) return;

  if (event.key === '?' || event.key.toLowerCase() === 'h') {
    event.preventDefault();
    shortcutDialog.showModal();
    return;
  }

  if (event.key === '/') {
    event.preventDefault();
    songSearchInput.focus();
  }
});

applySettings(loadSettings());

window.DJKaraokeHostShell = Object.freeze({
  contractVersion: 'v1',
  liveShowMode: 'local-first',
  mediaPlaybackEnabled: false,
  mediaDownloadEnabled: false,
  mediaDeletionEnabled: false,
  obsIntegrationEnabled: false,
  replayIntegrationEnabled: false,
  keyboardShortcutsEnabled: true,
  settingsPersistence: 'browser-localStorage',
  demoModeEnabled: true,
  demoData: safeDemoData,
  firstRunSetupEnabled: true,
  uiScalingEnabled: true,
  loadingStateEnabled: true,
  emptyStateEnabled: true,
  errorStateEnabled: true,
  toastNotificationsEnabled: true,
  confirmationDialogPatternEnabled: true,
  destructiveConfirmationActionsEnabled: false,
  safeErrorDialogsEnabled: true,
  notificationFollowUpEnabled: true,
  activityLogPanelEnabled: true,
  diagnosticsExportPlaceholderEnabled: true,
  diagnosticsExportWritesFiles: false
});
