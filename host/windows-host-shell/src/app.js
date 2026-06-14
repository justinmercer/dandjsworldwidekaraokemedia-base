const navItems = Array.from(document.querySelectorAll('.nav-item'));

for (const item of navItems) {
  item.addEventListener('click', () => {
    for (const navItem of navItems) {
      navItem.classList.remove('active');
    }

    item.classList.add('active');
  });
}

window.DJKaraokeHostShell = Object.freeze({
  contractVersion: 'v1',
  liveShowMode: 'local-first',
  mediaPlaybackEnabled: false,
  mediaDownloadEnabled: false,
  mediaDeletionEnabled: false,
  obsIntegrationEnabled: false,
  replayIntegrationEnabled: false
});
