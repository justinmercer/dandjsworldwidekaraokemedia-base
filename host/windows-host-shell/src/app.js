
const settingsKey = 'djKaraokeHostShellSettings.v1';

const defaultSettings = Object.freeze({
  venue: "D & J's Demo Venue",
  connectionMode: 'local-only',
  hostDisplayName: 'Main Host Laptop'
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

const navItems = Array.from(document.querySelectorAll('.nav-item'));
const shortcutHelpButton = document.querySelector('#shortcutHelpButton');
const shortcutDialog = document.querySelector('#shortcutDialog');
const closeShortcutsButton = document.querySelector('#closeShortcutsButton');
const songSearchInput = document.querySelector('#songSearchInput');
const settingsForm = document.querySelector('#settingsForm');
const venueSelector = document.querySelector('#venueSelector');
const connectionMode = document.querySelector('#connectionMode');
const hostDisplayName = document.querySelector('#hostDisplayName');
const settingsStatus = document.querySelector('#settingsStatus');

function applySettings(settings) {
  venueSelector.value = settings.venue;
  connectionMode.value = settings.connectionMode;
  hostDisplayName.value = settings.hostDisplayName;
  document.querySelector('.host-shell').dataset.connectionState = settings.connectionMode;
}

for (const item of navItems) {
  item.addEventListener('click', () => {
    for (const navItem of navItems) navItem.classList.remove('active');
    item.classList.add('active');
  });
}

shortcutHelpButton.addEventListener('click', () => shortcutDialog.showModal());
closeShortcutsButton.addEventListener('click', () => shortcutDialog.close());

settingsForm.addEventListener('submit', (event) => {
  event.preventDefault();

  saveSettings({
    venue: venueSelector.value,
    connectionMode: connectionMode.value,
    hostDisplayName: hostDisplayName.value.trim() || defaultSettings.hostDisplayName
  });

  applySettings(loadSettings());
  settingsStatus.textContent = 'Settings saved locally in this browser only.';
});

document.addEventListener('keydown', (event) => {
  const activeElement = document.activeElement;
  const isTyping = activeElement && ['INPUT', 'SELECT', 'TEXTAREA'].includes(activeElement.tagName);

  if (event.key === 'Escape' && shortcutDialog.open) {
    shortcutDialog.close();
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
  settingsPersistence: 'browser-localStorage'
});
