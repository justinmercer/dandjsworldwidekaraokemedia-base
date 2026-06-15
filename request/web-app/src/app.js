
const guestNameInput = document.querySelector('#guestNameInput');
const returningSingerPreviewButton = document.querySelector('#returningSingerPreviewButton');
const privacyMatchPreviewButton = document.querySelector('#privacyMatchPreviewButton');
const singerPreviewStatus = document.querySelector('#singerPreviewStatus');
const catalogSearchInput = document.querySelector('#catalogSearchInput');
const searchDebounceStatus = document.querySelector('#searchDebounceStatus');
const searchEmptyState = document.querySelector('#searchEmptyState');
const catalogSearchResults = document.querySelector('#catalogSearchResults');
const keyChangePreviewSelect = document.querySelector('#keyChangePreviewSelect');
const duetPartnerInput = document.querySelector('#duetPartnerInput');
const requestNoteInput = document.querySelector('#requestNoteInput');
const requestPreviewButton = document.querySelector('#requestPreviewButton');
const requestPreviewStatus = document.querySelector('#requestPreviewStatus');
const venueAccessCodeInput = document.querySelector('#venueAccessCodeInput');
const accessCodeStatus = document.querySelector('#accessCodeStatus');
const connectionModeStatus = document.querySelector('#connectionModeStatus');

const requestWebSafety = {
  submitsRequests: false,
  callsServerApis: false,
  readsSingerRecords: false,
  writesSingerRecords: false,
  writesQueueRecords: false,
  validatesVenueAccessCodes: false,
  changesNetworkMode: false,
  searchesRealCatalog: false,
  storesPersonalData: false,
  moderatesRequests: false,
  sendsNotifications: false,
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

function setRequestStatus(message) {
  requestPreviewStatus.textContent = message;
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

venueAccessCodeInput.addEventListener('input', () => {
  accessCodeStatus.textContent = venueAccessCodeInput.value.trim()
    ? 'Venue access-code preview captured in memory only. No validation was performed.'
    : 'Access-code entry preview only. No code is validated.';
});

catalogSearchInput.addEventListener('input', () => {
  clearTimeout(debounceTimer);
  setSearchStatus('Waiting for debounce preview...');
  debounceTimer = setTimeout(() => {
    const query = catalogSearchInput.value.trim();
    setSearchStatus(query ? `Fixture search preview for "${query}". No catalog API was called.` : 'Start typing a song or artist.');
    searchEmptyState.hidden = Boolean(query);
    catalogSearchResults.hidden = !query;
  }, requestWebSafety.searchDebounceMs);
});

requestPreviewButton.addEventListener('click', () => {
  const keyChange = keyChangePreviewSelect.value;
  const duetPartner = duetPartnerInput.value.trim() || 'No duet partner entered';
  const note = requestNoteInput.value.trim() || 'No note entered';
  setRequestStatus(`Draft preview only. Key: ${keyChange}. Duet: ${duetPartner}. Note: ${note}. Nothing was submitted.`);
  connectionModeStatus.textContent = 'Automatic fallback message preview only. No network mode was changed.';
});
