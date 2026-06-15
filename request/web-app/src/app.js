
const guestNameInput = document.querySelector('#guestNameInput');
const returningSingerPreviewButton = document.querySelector('#returningSingerPreviewButton');
const privacyMatchPreviewButton = document.querySelector('#privacyMatchPreviewButton');
const singerPreviewStatus = document.querySelector('#singerPreviewStatus');
const catalogSearchInput = document.querySelector('#catalogSearchInput');
const searchDebounceStatus = document.querySelector('#searchDebounceStatus');
const catalogSearchResults = document.querySelector('#catalogSearchResults');

const requestWebSafety = {
  submitsRequests: false,
  callsServerApis: false,
  readsSingerRecords: false,
  writesSingerRecords: false,
  searchesRealCatalog: false,
  storesPersonalData: false,
  moderatesRequests: false,
  enablesPwaInstall: false,
  searchDebounceMs: 300
};

let debounceTimer = null;

function setSingerStatus(message) {
  singerPreviewStatus.textContent = message;
}

function setSearchStatus(message) {
  searchDebounceStatus.textContent = message;
}

returningSingerPreviewButton.addEventListener('click', () => {
  setSingerStatus('Returning singer lookup preview only. No singer records were read.');
});

privacyMatchPreviewButton.addEventListener('click', () => {
  setSingerStatus('Privacy-safe match preview only. No personal data was stored.');
});

guestNameInput.addEventListener('input', () => {
  const value = guestNameInput.value.trim();
  setSingerStatus(value ? 'Guest name preview captured in memory only.' : 'No singer data is read or written.');
});

catalogSearchInput.addEventListener('input', () => {
  clearTimeout(debounceTimer);
  setSearchStatus('Waiting for debounce preview...');
  debounceTimer = setTimeout(() => {
    const query = catalogSearchInput.value.trim();
    setSearchStatus(query ? `Fixture search preview for "${query}". No catalog API was called.` : 'Start typing a song or artist.');
    catalogSearchResults.hidden = !query;
  }, requestWebSafety.searchDebounceMs);
});
