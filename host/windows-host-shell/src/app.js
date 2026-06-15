
const settingsKey = 'djKaraokeHostShellSettings.v1';
const settingsSchemaVersion = 1;
const legacySettingsKeys = Object.freeze([
  'djKaraokeHostShellSettings'
]);

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

function migrateSavedSettings() {
  const currentSettings = JSON.parse(localStorage.getItem(settingsKey) || '{}');
  const legacySettings = legacySettingsKeys
    .map((legacyKey) => JSON.parse(localStorage.getItem(legacyKey) || '{}'))
    .find((settings) => Object.keys(settings).length > 0) || {};

  const migratedSettings = {
    ...defaultSettings,
    ...legacySettings,
    ...currentSettings,
    settingsSchemaVersion
  };

  localStorage.setItem(settingsKey, JSON.stringify(migratedSettings));
  return migratedSettings;
}

function loadSettings() {
  try {
    return migrateSavedSettings();
  } catch {
    return { ...defaultSettings, settingsSchemaVersion };
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

function parseImportFilenameCandidate(fileName) {
  const baseName = fileName.replace(/\.[^.]+$/, '');
  const [artist = 'Needs review', title = 'Needs review'] = baseName.split(' - ').map((part) => part.trim());
  return { artist, title, state: 'Ready for manual review' };
}

function renderFilenameParsePreview() {
  const parsed = parseImportFilenameCandidate(importFilenamePreview.value);
  filenameParsePreview.innerHTML = `
    <div><dt>Artist</dt><dd>${parsed.artist}</dd></div>
    <div><dt>Title</dt><dd>${parsed.title}</dd></div>
    <div><dt>State</dt><dd>${parsed.state}</dd></div>
  `;
}

function showImportCancelPreview() {
  importCancelDialog.showModal();
  appendActivityLog('Import', 'Displayed safe cancellation and rollback preview.');
}

function appendImportAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  importAuditLogPreview.prepend(item);
}

function setImportReviewState(actionName) {
  appendImportAudit('Review action', `${actionName} previewed with no catalog writes.`);
  appendActivityLog('Import review', `${actionName} previewed safely.`);
  showToast(`${actionName} preview saved to the import audit log.`, 'info');
}

function showMergeDuplicatePreview() {
  mergeDuplicateDialog.showModal();
  appendImportAudit('Merge preview', 'Safe confirmation displayed before duplicate merge preview.');
}

function showSiglosMigrationPreview() {
  siglosMigrationDialog.showModal();
  appendActivityLog('Siglos migration', 'Opened preview summary with no file reads or writes.');
}

function appendSingerProfileAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  singerProfileAuditPreview.prepend(item);
}

function showSingerAliasPreview() {
  singerAliasDialog.showModal();
  appendSingerProfileAudit('Alias', 'Alias merge preview opened without changing singer records.');
}

function showRepeatSingerPreview() {
  repeatSingerDialog.showModal();
  appendSingerProfileAudit('Repeat warning', 'Repeat singer preview opened without changing rotation.');
}

function appendRotationAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  rotationAuditPreview.prepend(item);
}

function showRotationPreview() {
  rotationPreviewDialog.showModal();
  appendRotationAudit('Preview', 'Rotation order and wait estimates previewed without changing live state.');
}

function showRotationPolicyPreview() {
  rotationPolicyDialog.showModal();
  appendRotationAudit('Policy', 'Fair-round and priority rules previewed without changing live state.');
}

function showRotationActionPreview(actionName, message) {
  rotationActionDialogText.textContent = message;
  rotationActionDialog.showModal();
  appendRotationAudit(actionName, `${message} No live state was changed.`);
  appendActivityLog('Rotation action', `${actionName} preview opened without changing live rotation.`);
}

function showSessionSnapshotPreview() {
  sessionSnapshotDialog.showModal();
  appendRotationAudit('Snapshot', 'Manual session snapshot preview opened without writing files or records.');
}

function showAutosavePreview() {
  autosavePreviewDialog.showModal();
  appendRotationAudit('Autosave', 'Autosave trigger preview opened without persisting rotation changes.');
}

function noteShowNotesEdited() {
  appendRotationAudit('Show notes', 'Show notes preview changed without saving records.');
}

function appendSessionRecoveryAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  sessionRecoveryAuditPreview.prepend(item);
}

function showRestoreSessionPreview() {
  restoreSessionDialog.showModal();
  appendSessionRecoveryAudit('Restore', 'Restore session preview opened without restoring records.');
  appendActivityLog('Session recovery', 'Restore preview opened without changing live state.');
}

function showDiscardSessionPreview() {
  discardSessionDialog.showModal();
  appendSessionRecoveryAudit('Discard', 'Discard stale session preview opened without deleting records.');
  appendActivityLog('Session recovery', 'Discard preview opened without changing live state.');
}

function appendHostChecksAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  hostChecksAuditPreview.prepend(item);
}

function showHostChecksPreview(kind, message) {
  hostChecksDialogText.textContent = message;
  hostChecksDialog.showModal();
  appendHostChecksAudit(kind, `${message} No playback, display state, monitor reconnect, keyboard hook, file read, or runtime write occurred.`);
  appendActivityLog('Host checks', `${kind} preview opened without live control access.`);
}

function appendThemeShellAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  themeShellAuditPreview.prepend(item);
}

function showThemeShellPreview(kind, message) {
  themeShellDialogText.textContent = message;
  themeShellDialog.showModal();
  appendThemeShellAudit(kind, `${message} No logo file, background file, camera, monitor state, live-show control, or media read occurred.`);
  appendActivityLog('Theme shell', `${kind} preview opened without live system access.`);
}

function appendDisplayShellAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  displayShellAuditPreview.prepend(item);
}

function showDisplayShellPreview(kind, message) {
  displayShellDialogText.textContent = message;
  displayShellDialog.showModal();
  appendDisplayShellAudit(kind, `${message} No real window, display, full-screen, camera, background, or state action occurred.`);
  appendActivityLog('Audience display', `${kind} preview opened without display access.`);
}

function appendOutputControlsAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  outputControlsAuditPreview.prepend(item);
}

function showOutputControlPreview(kind, message) {
  outputControlDialogText.textContent = message;
  outputControlDialog.showModal();
  appendOutputControlsAudit(kind, `${message} No device, microphone, recording, media, or output action occurred.`);
  appendActivityLog('Output control', `${kind} preview opened without device access.`);
}

function appendPlaybackAudit(kind, message) {
  const item = document.createElement('li');
  item.innerHTML = `<strong>${kind}:</strong> ${message}`;
  playbackAuditPreview.prepend(item);
}

function showPlaybackControlPreview(actionName, message) {
  playbackControlDialogText.textContent = message;
  playbackControlDialog.showModal();
  appendPlaybackAudit(actionName, `${message} No audio was played and no file was read.`);
  appendActivityLog('Playback control', `${actionName} preview opened without audio output.`);
}

function showVolumePreview() {
  appendPlaybackAudit('Volume', `Volume preview changed to ${volumePreviewSlider.value}% without changing audio output.`);
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
const importFilenamePreview = document.querySelector('#importFilenamePreview');
const filenameParsePreview = document.querySelector('#filenameParsePreview');
const importCancelPreviewButton = document.querySelector('#importCancelPreviewButton');
const importCancelDialog = document.querySelector('#importCancelDialog');
const closeImportCancelButton = document.querySelector('#closeImportCancelButton');
const skipForNowButton = document.querySelector('#skipForNowButton');
const markPreferredButton = document.querySelector('#markPreferredButton');
const keepBothButton = document.querySelector('#keepBothButton');
const mergeDuplicatePreviewButton = document.querySelector('#mergeDuplicatePreviewButton');
const mergeDuplicateDialog = document.querySelector('#mergeDuplicateDialog');
const closeMergeDuplicateButton = document.querySelector('#closeMergeDuplicateButton');
const importAuditLogPreview = document.querySelector('#importAuditLogPreview');
const siglosPreviewButton = document.querySelector('#siglosPreviewButton');
const siglosMigrationDialog = document.querySelector('#siglosMigrationDialog');
const closeSiglosMigrationButton = document.querySelector('#closeSiglosMigrationButton');
const aliasMergePreviewButton = document.querySelector('#aliasMergePreviewButton');
const repeatSingerPreviewButton = document.querySelector('#repeatSingerPreviewButton');
const singerAliasDialog = document.querySelector('#singerAliasDialog');
const repeatSingerDialog = document.querySelector('#repeatSingerDialog');
const closeSingerAliasButton = document.querySelector('#closeSingerAliasButton');
const closeRepeatSingerButton = document.querySelector('#closeRepeatSingerButton');
const singerProfileAuditPreview = document.querySelector('#singerProfileAuditPreview');
const rotationPreviewButton = document.querySelector('#rotationPreviewButton');
const rotationPolicyButton = document.querySelector('#rotationPolicyButton');
const rotationPreviewDialog = document.querySelector('#rotationPreviewDialog');
const rotationPolicyDialog = document.querySelector('#rotationPolicyDialog');
const closeRotationPreviewButton = document.querySelector('#closeRotationPreviewButton');
const closeRotationPolicyButton = document.querySelector('#closeRotationPolicyButton');
const rotationAuditPreview = document.querySelector('#rotationAuditPreview');
const callSingerPreviewButton = document.querySelector('#callSingerPreviewButton');
const singerNotReadyPreviewButton = document.querySelector('#singerNotReadyPreviewButton');
const moveNextRoundPreviewButton = document.querySelector('#moveNextRoundPreviewButton');
const removeTonightPreviewButton = document.querySelector('#removeTonightPreviewButton');
const restoreSingerPreviewButton = document.querySelector('#restoreSingerPreviewButton');
const sessionSnapshotPreviewButton = document.querySelector('#sessionSnapshotPreviewButton');
const autosavePreviewButton = document.querySelector('#autosavePreviewButton');
const rotationActionDialog = document.querySelector('#rotationActionDialog');
const rotationActionDialogText = document.querySelector('#rotationActionDialogText');
const closeRotationActionButton = document.querySelector('#closeRotationActionButton');
const sessionSnapshotDialog = document.querySelector('#sessionSnapshotDialog');
const closeSessionSnapshotButton = document.querySelector('#closeSessionSnapshotButton');
const autosavePreviewDialog = document.querySelector('#autosavePreviewDialog');
const closeAutosavePreviewButton = document.querySelector('#closeAutosavePreviewButton');
const showNotesPreview = document.querySelector('#showNotesPreview');
const restoreSessionPreviewButton = document.querySelector('#restoreSessionPreviewButton');
const discardSessionPreviewButton = document.querySelector('#discardSessionPreviewButton');
const restoreSessionDialog = document.querySelector('#restoreSessionDialog');
const discardSessionDialog = document.querySelector('#discardSessionDialog');
const closeRestoreSessionButton = document.querySelector('#closeRestoreSessionButton');
const closeDiscardSessionButton = document.querySelector('#closeDiscardSessionButton');
const sessionRecoveryAuditPreview = document.querySelector('#sessionRecoveryAuditPreview');
const playbackAuditPreview = document.querySelector('#playbackAuditPreview');
const outputControlsAuditPreview = document.querySelector('#outputControlsAuditPreview');
const outputDevicePreviewSelect = document.querySelector('#outputDevicePreviewSelect');
const micArmPreviewButton = document.querySelector('#micArmPreviewButton');
const micRecordPreviewButton = document.querySelector('#micRecordPreviewButton');
const keyChangePreviewInput = document.querySelector('#keyChangePreviewInput');
const tempoPreviewInput = document.querySelector('#tempoPreviewInput');
const resetDefaultsPreviewButton = document.querySelector('#resetDefaultsPreviewButton');
const fillerEnabledPreviewToggle = document.querySelector('#fillerEnabledPreviewToggle');
const outputControlDialog = document.querySelector('#outputControlDialog');
const outputControlDialogText = document.querySelector('#outputControlDialogText');
const closeOutputControlButton = document.querySelector('#closeOutputControlButton');
const displayShellAuditPreview = document.querySelector('#displayShellAuditPreview');
const fillerVolumePreviewInput = document.querySelector('#fillerVolumePreviewInput');
const previewWindowPreviewButton = document.querySelector('#previewWindowPreviewButton');
const displaySelectionPreviewSelect = document.querySelector('#displaySelectionPreviewSelect');
const externalDisplayPreviewButton = document.querySelector('#externalDisplayPreviewButton');
const fullscreenPreviewButton = document.querySelector('#fullscreenPreviewButton');
const cloneDisplayPreviewButton = document.querySelector('#cloneDisplayPreviewButton');
const announcementPreviewButton = document.querySelector('#announcementPreviewButton');
const announcementPreviewText = document.querySelector('#announcementPreviewText');
const displayShellDialog = document.querySelector('#displayShellDialog');
const displayShellDialogText = document.querySelector('#displayShellDialogText');
const closeDisplayShellButton = document.querySelector('#closeDisplayShellButton');
const themeShellAuditPreview = document.querySelector('#themeShellAuditPreview');
const venueLogoOverlayPreviewToggle = document.querySelector('#venueLogoOverlayPreviewToggle');
const customBackgroundPreviewSelect = document.querySelector('#customBackgroundPreviewSelect');
const cameraBackgroundPreviewButton = document.querySelector('#cameraBackgroundPreviewButton');
const themePreviewSelect = document.querySelector('#themePreviewSelect');
const monitorFallbackPreviewButton = document.querySelector('#monitorFallbackPreviewButton');
const failureIsolationPreviewButton = document.querySelector('#failureIsolationPreviewButton');
const demoFixturePreviewButton = document.querySelector('#demoFixturePreviewButton');
const themeShellDialog = document.querySelector('#themeShellDialog');
const themeShellDialogText = document.querySelector('#themeShellDialogText');
const closeThemeShellButton = document.querySelector('#closeThemeShellButton');
const hostChecksAuditPreview = document.querySelector('#hostChecksAuditPreview');
const controlChecksPreviewButton = document.querySelector('#controlChecksPreviewButton');
const displayStateChecksPreviewButton = document.querySelector('#displayStateChecksPreviewButton');
const monitorReconnectChecksPreviewButton = document.querySelector('#monitorReconnectChecksPreviewButton');
const keyboardShortcutChecksPreviewButton = document.querySelector('#keyboardShortcutChecksPreviewButton');
const troubleshootingPreviewButton = document.querySelector('#troubleshootingPreviewButton');
const hostChecksDialog = document.querySelector('#hostChecksDialog');
const hostChecksDialogText = document.querySelector('#hostChecksDialogText');
const closeHostChecksButton = document.querySelector('#closeHostChecksButton');
const playPreviewButton = document.querySelector('#playPreviewButton');
const pausePreviewButton = document.querySelector('#pausePreviewButton');
const stopPreviewButton = document.querySelector('#stopPreviewButton');
const nextPreviewButton = document.querySelector('#nextPreviewButton');
const previousPreviewButton = document.querySelector('#previousPreviewButton');
const fadeOutPreviewButton = document.querySelector('#fadeOutPreviewButton');
const emergencySkipPreviewButton = document.querySelector('#emergencySkipPreviewButton');
const volumePreviewSlider = document.querySelector('#volumePreviewSlider');
const playbackControlDialog = document.querySelector('#playbackControlDialog');
const playbackControlDialogText = document.querySelector('#playbackControlDialogText');
const closePlaybackControlButton = document.querySelector('#closePlaybackControlButton');

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
importFilenamePreview.addEventListener('input', () => renderFilenameParsePreview());
importCancelPreviewButton.addEventListener('click', () => showImportCancelPreview());
closeImportCancelButton.addEventListener('click', () => importCancelDialog.close());
skipForNowButton.addEventListener('click', () => setImportReviewState('Skip for now'));
markPreferredButton.addEventListener('click', () => setImportReviewState('Mark preferred version'));
keepBothButton.addEventListener('click', () => setImportReviewState('Keep both versions'));
mergeDuplicatePreviewButton.addEventListener('click', () => showMergeDuplicatePreview());
closeMergeDuplicateButton.addEventListener('click', () => mergeDuplicateDialog.close());
siglosPreviewButton.addEventListener('click', () => showSiglosMigrationPreview());
closeSiglosMigrationButton.addEventListener('click', () => siglosMigrationDialog.close());
aliasMergePreviewButton.addEventListener('click', () => showSingerAliasPreview());
repeatSingerPreviewButton.addEventListener('click', () => showRepeatSingerPreview());
closeSingerAliasButton.addEventListener('click', () => singerAliasDialog.close());
closeRepeatSingerButton.addEventListener('click', () => repeatSingerDialog.close());
rotationPreviewButton.addEventListener('click', () => showRotationPreview());
rotationPolicyButton.addEventListener('click', () => showRotationPolicyPreview());
closeRotationPreviewButton.addEventListener('click', () => rotationPreviewDialog.close());
closeRotationPolicyButton.addEventListener('click', () => rotationPolicyDialog.close());
callSingerPreviewButton.addEventListener('click', () => showRotationActionPreview('Call singer', 'Call singer preview displayed.'));
singerNotReadyPreviewButton.addEventListener('click', () => showRotationActionPreview('Singer not ready', 'Singer not ready preview displayed.'));
moveNextRoundPreviewButton.addEventListener('click', () => showRotationActionPreview('Move to next round', 'Move to next round preview displayed.'));
removeTonightPreviewButton.addEventListener('click', () => showRotationActionPreview('Remove from tonight', 'Remove from tonight preview displayed.'));
restoreSingerPreviewButton.addEventListener('click', () => showRotationActionPreview('Restore singer', 'Restore singer preview displayed.'));
sessionSnapshotPreviewButton.addEventListener('click', () => showSessionSnapshotPreview());
autosavePreviewButton.addEventListener('click', () => showAutosavePreview());
closeRotationActionButton.addEventListener('click', () => rotationActionDialog.close());
closeSessionSnapshotButton.addEventListener('click', () => sessionSnapshotDialog.close());
closeAutosavePreviewButton.addEventListener('click', () => autosavePreviewDialog.close());
showNotesPreview.addEventListener('change', () => noteShowNotesEdited());
restoreSessionPreviewButton.addEventListener('click', () => showRestoreSessionPreview());
discardSessionPreviewButton.addEventListener('click', () => showDiscardSessionPreview());
closeRestoreSessionButton.addEventListener('click', () => restoreSessionDialog.close());
closeDiscardSessionButton.addEventListener('click', () => discardSessionDialog.close());
controlChecksPreviewButton.addEventListener('click', () => showHostChecksPreview('Control checks', 'Playback-control test preview displayed.'));
displayStateChecksPreviewButton.addEventListener('click', () => showHostChecksPreview('Display-state checks', 'External-display state test preview displayed.'));
monitorReconnectChecksPreviewButton.addEventListener('click', () => showHostChecksPreview('Monitor reconnect checks', 'Monitor reconnect test preview displayed.'));
keyboardShortcutChecksPreviewButton.addEventListener('click', () => showHostChecksPreview('Shortcut checks', 'Keyboard shortcut test preview displayed.'));
troubleshootingPreviewButton.addEventListener('click', () => showHostChecksPreview('Troubleshooting', 'Live-show troubleshooting guide preview displayed.'));
closeHostChecksButton.addEventListener('click', () => hostChecksDialog.close());

venueLogoOverlayPreviewToggle.addEventListener('change', () => showThemeShellPreview('Venue logo', `Venue logo overlay placeholder ${venueLogoOverlayPreviewToggle.checked ? 'enabled' : 'disabled'}.`));
customBackgroundPreviewSelect.addEventListener('change', () => showThemeShellPreview('Background', 'Custom background placeholder changed.'));
cameraBackgroundPreviewButton.addEventListener('click', () => showThemeShellPreview('Camera background', 'Camera-background placeholder displayed.'));
themePreviewSelect.addEventListener('change', () => showThemeShellPreview('Theme selection', `${themePreviewSelect.value} theme preview selected.`));
monitorFallbackPreviewButton.addEventListener('click', () => showThemeShellPreview('Monitor fallback', 'Disconnected-monitor fallback placeholder displayed.'));
failureIsolationPreviewButton.addEventListener('click', () => showThemeShellPreview('Failure isolation', 'Failure isolation placeholder displayed.'));
demoFixturePreviewButton.addEventListener('click', () => showThemeShellPreview('Demo fixtures', 'Demo fixture placeholder displayed.'));
closeThemeShellButton.addEventListener('click', () => themeShellDialog.close());

fillerVolumePreviewInput.addEventListener('change', () => showDisplayShellPreview('Filler volume', `Filler volume preview changed to ${fillerVolumePreviewInput.value}%.`));
previewWindowPreviewButton.addEventListener('click', () => showDisplayShellPreview('Preview window', 'Preview-window plumbing placeholder displayed.'));
displaySelectionPreviewSelect.addEventListener('change', () => showDisplayShellPreview('Display selection', 'Display selection placeholder changed.'));
externalDisplayPreviewButton.addEventListener('click', () => showDisplayShellPreview('External display', 'External display placeholder displayed.'));
fullscreenPreviewButton.addEventListener('click', () => showDisplayShellPreview('Full-screen', 'Full-screen placeholder displayed.'));
cloneDisplayPreviewButton.addEventListener('click', () => showDisplayShellPreview('Clone display', 'Clone display placeholder displayed.'));
announcementPreviewButton.addEventListener('click', () => {
  announcementPreviewText.textContent = 'Preview announcement: thank you for singing with D & J Karaoke.';
  showDisplayShellPreview('Announcement', 'Scrolling announcement placeholder displayed.');
});
closeDisplayShellButton.addEventListener('click', () => displayShellDialog.close());

outputDevicePreviewSelect.addEventListener('change', () => showOutputControlPreview('Output device', 'Output-device selection preview changed.'));
micArmPreviewButton.addEventListener('click', () => showOutputControlPreview('Mic arm', 'Microphone arm placeholder displayed.'));
micRecordPreviewButton.addEventListener('click', () => showOutputControlPreview('Recording', 'Recording placeholder displayed.'));
keyChangePreviewInput.addEventListener('change', () => showOutputControlPreview('Key change', `Key preview changed to ${keyChangePreviewInput.value} semitones.`));
tempoPreviewInput.addEventListener('change', () => showOutputControlPreview('Tempo', `Tempo preview changed to ${tempoPreviewInput.value}%.`));
resetDefaultsPreviewButton.addEventListener('click', () => {
  keyChangePreviewInput.value = 0;
  tempoPreviewInput.value = 100;
  showOutputControlPreview('Defaults', 'Reset-to-default controls preview displayed.');
});
fillerEnabledPreviewToggle.addEventListener('change', () => showOutputControlPreview('Filler hook', `Filler placeholder preview ${fillerEnabledPreviewToggle.checked ? 'enabled' : 'disabled'}.`));
closeOutputControlButton.addEventListener('click', () => outputControlDialog.close());

playPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Play', 'Play preview displayed.'));
pausePreviewButton.addEventListener('click', () => showPlaybackControlPreview('Pause', 'Pause preview displayed.'));
stopPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Stop', 'Stop preview displayed.'));
nextPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Next', 'Next preview displayed.'));
previousPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Previous', 'Previous where safe preview displayed.'));
fadeOutPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Fade out', 'Fade-out preview displayed.'));
emergencySkipPreviewButton.addEventListener('click', () => showPlaybackControlPreview('Emergency skip', 'Emergency skip preview displayed.'));
volumePreviewSlider.addEventListener('change', () => showVolumePreview());
closePlaybackControlButton.addEventListener('click', () => playbackControlDialog.close());

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
renderFilenameParsePreview();
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
    if (importCancelDialog.open) importCancelDialog.close();
    if (mergeDuplicateDialog.open) mergeDuplicateDialog.close();
    if (siglosMigrationDialog.open) siglosMigrationDialog.close();
    if (singerAliasDialog.open) singerAliasDialog.close();
    if (repeatSingerDialog.open) repeatSingerDialog.close();
    if (rotationPreviewDialog.open) rotationPreviewDialog.close();
    if (rotationPolicyDialog.open) rotationPolicyDialog.close();
    if (rotationActionDialog.open) rotationActionDialog.close();
    if (sessionSnapshotDialog.open) sessionSnapshotDialog.close();
    if (autosavePreviewDialog.open) autosavePreviewDialog.close();
    if (restoreSessionDialog.open) restoreSessionDialog.close();
    if (discardSessionDialog.open) discardSessionDialog.close();
    if (playbackControlDialog.open) playbackControlDialog.close();
    if (outputControlDialog.open) outputControlDialog.close();
    if (displayShellDialog.open) displayShellDialog.close();
    if (themeShellDialog.open) themeShellDialog.close();
    if (hostChecksDialog.open) hostChecksDialog.close();
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
  diagnosticsExportWritesFiles: false,
  ciCompileChecksEnabled: true,
  startupSmokeTestEnabled: true,
  cleanShutdownSmokeTestEnabled: true,
  settingsMigrationTestEnabled: true,
  demoModeScreenshotChecklistEnabled: true,
  catalogImportWizardEnabled: true,
  catalogImportFolderSelectionPlaceholderEnabled: true,
  supportedFileTypeDetectionPreviewEnabled: true,
  filenameMetadataParsingPreviewEnabled: true,
  manualMetadataCorrectionPreviewEnabled: true,
  batchMetadataReviewPreviewEnabled: true,
  duplicateWarningDisplayEnabled: true,
  alternateVersionWarningDisplayEnabled: true,
  importProgressDisplayEnabled: true,
  importCancellationSafeRollbackPreviewEnabled: true,
  importErrorSummaryEnabled: true,
  importReviewQueueEnabled: true,
  importReadsMediaFiles: false,
  importNeedsManualReviewStateEnabled: true,
  importSkipForNowActionEnabled: true,
  importMarkPreferredVersionActionEnabled: true,
  importKeepBothVersionsActionEnabled: true,
  importMergeDuplicateRecordsPreviewEnabled: true,
  importSafeMergeConfirmationEnabled: true,
  importAuditLogPreviewEnabled: true,
  importDemoFixturesForTestsOnly: true,
  catalogImportTestsEnabled: true,
  malformedFilenameTestsEnabled: true,
  duplicateDetectionTestsEnabled: true,
  alternateVersionTestsEnabled: true,
  importCancellationTestsEnabled: true,
  importWritesCatalogRecords: false,
  siglosMigrationWizardEnabled: true,
  siglosSongMetadataExportPreviewEnabled: true,
  siglosSingerProfileExportPreviewEnabled: true,
  siglosSingerHistoryExportPreviewEnabled: true,
  siglosRememberedKeyChangePreviewEnabled: true,
  siglosVenueEntryPreviewEnabled: true,
  siglosSavedPreferencePreviewEnabled: true,
  siglosMigrationPreviewEnabled: true,
  siglosMigrationValidationEnabled: true,
  siglosDuplicateWarningPreviewEnabled: true,
  siglosBackupFirstMessagingEnabled: true,
  siglosMigrationSummaryReportPreviewEnabled: true,
  siglosDemoExportFixturesEnabled: true,
  siglosMigrationTestsEnabled: true,
  siglosMigrationReadsFiles: false,
  siglosMigrationWritesRecords: false,
  singerProfileModelShellEnabled: true,
  singerDisplayNamesEnabled: true,
  singerOptionalContactPrivacyDefaultsEnabled: true,
  singerStaffOnlyNotesEnabled: true,
  singerFavouritesPreviewEnabled: true,
  singerSongHistoryPreviewEnabled: true,
  singerRememberedKeyChangePreviewEnabled: true,
  singerDuetGroupPerformancePreviewEnabled: true,
  singerAliasMergePreviewEnabled: true,
  repeatSingerDetectionPreviewEnabled: true,
  singerProfileContainsRealSingerData: false,
  singerProfileWritesRecords: false,
  singerProfileMergesRecords: false,
  singerContactPublicExposureEnabled: false,
  showSessionModelShellEnabled: true,
  showSessionTimestampPreviewEnabled: true,
  showSessionVenueAssociationPreviewEnabled: true,
  activeRotationStatePreviewEnabled: true,
  queuedSongsPerSingerPreviewEnabled: true,
  currentSingerStatePreviewEnabled: true,
  upNextStatePreviewEnabled: true,
  temporaryDisableStatePreviewEnabled: true,
  skipStatePreviewEnabled: true,
  priorityInsertPreviewEnabled: true,
  dragDropOrderingPreviewEnabled: true,
  fairRoundOrderingRulesPreviewEnabled: true,
  configurableRotationPoliciesPreviewEnabled: true,
  estimatedWaitCalculationsPreviewEnabled: true,
  rotationPreviewEnabled: true,
  showSessionWritesRecords: false,
  rotationWritesRecords: false,
  rotationChangesLiveState: false,
  callSingerActionPreviewEnabled: true,
  singerNotReadyActionPreviewEnabled: true,
  moveToNextRoundActionPreviewEnabled: true,
  removeFromTonightActionPreviewEnabled: true,
  restoreSingerActionPreviewEnabled: true,
  completedPerformanceRecordPreviewEnabled: true,
  showNotesFieldPreviewEnabled: true,
  manualSessionSnapshotPreviewEnabled: true,
  autosaveTriggerPreviewEnabled: true,
  rotationActionChangesLiveState: false,
  completedPerformanceWritesRecords: false,
  showNotesWritesRecords: false,
  manualSessionSnapshotWritesFiles: false,
  autosavePersistsChanges: false,
  uncleanShutdownRecoveryPromptPreviewEnabled: true,
  restoreSessionFlowPreviewEnabled: true,
  discardStaleSessionFlowPreviewEnabled: true,
  rotationRuleTestsPreviewEnabled: true,
  estimatedWaitTestsPreviewEnabled: true,
  crashRecoveryTestsPreviewEnabled: true,
  sessionRecoveryWritesRecords: false,
  sessionRecoveryWritesFiles: false,
  sessionRecoveryRestoresRealSession: false,
  sessionRecoveryDiscardsRealSession: false,
  playbackEngineDecisionDocumented: true,
  localPlaybackStatePreviewEnabled: true,
  playActionPreviewEnabled: true,
  pauseActionPreviewEnabled: true,
  stopActionPreviewEnabled: true,
  nextActionPreviewEnabled: true,
  previousWhereSafeActionPreviewEnabled: true,
  fadeOutActionPreviewEnabled: true,
  emergencySkipActionPreviewEnabled: true,
  volumeControlsPreviewEnabled: true,
  playbackStartsAudio: false,
  playbackReadsMediaFiles: false,
  playbackChangesAudioOutput: false,
  playbackWritesState: false,
  outputDeviceSelectionPreviewEnabled: true,
  microphoneRecordingControlPlaceholdersEnabled: true,
  keyChangeControlsPreviewEnabled: true,
  tempoControlsPreviewEnabled: true,
  resetToDefaultControlsPreviewEnabled: true,
  playbackProgressPreviewEnabled: true,
  remainingTimeDisplayPreviewEnabled: true,
  endOfTrackDetectionPreviewEnabled: true,
  fillerHooksPreviewEnabled: true,
  fillerEnableDisablePreviewEnabled: true,
  outputControlsEnumerateDevices: false,
  outputControlsSelectRealDevice: false,
  outputControlsAccessMicrophone: false,
  outputControlsStartRecording: false,
  outputControlsPlayAudio: false,
  outputControlsReadMediaFiles: false,
  outputControlsWriteState: false,
  fillerAudioVolumePreviewEnabled: true,
  previewWindowPlumbingPreviewEnabled: true,
  externalDisplayWindowPreviewEnabled: true,
  fullscreenExternalDisplayPreviewEnabled: true,
  displaySelectionPreviewEnabled: true,
  clonedDisplaySupportPreviewEnabled: true,
  nowSingingCardPreviewEnabled: true,
  upNextCardPreviewEnabled: true,
  welcomeScreenPreviewEnabled: true,
  scrollingAnnouncementPreviewEnabled: true,
  displayShellOpensRealPreviewWindow: false,
  displayShellOpensRealExternalWindow: false,
  displayShellEntersFullscreen: false,
  displayShellEnumeratesDisplays: false,
  displayShellSelectsDisplay: false,
  displayShellClonesDisplay: false,
  displayShellLoadsBackgroundFiles: false,
  displayShellUsesCamera: false,
  displayShellWritesState: false,
  venueLogoOverlayPreviewEnabled: true,
  customBackgroundSupportPreviewEnabled: true,
  cameraBackgroundPlaceholderEnabled: true,
  themeSelectionPreviewEnabled: true,
  privatePartyThemePreviewEnabled: true,
  weddingThemePreviewEnabled: true,
  barNightThemePreviewEnabled: true,
  monitorDisconnectFallbackPreviewEnabled: true,
  failureIsolationPreviewEnabled: true,
  demoFixturesOnlyEnabled: true,
  themeShellLoadsLogoFiles: false,
  themeShellLoadsBackgroundFiles: false,
  themeShellUsesCamera: false,
  themeShellChangesRealMonitorState: false,
  themeShellControlsLiveShow: false,
  themeShellReadsMediaFiles: false,
  themeShellWritesState: false,
  playbackControlTestsPreviewEnabled: true,
  externalDisplayStateTestsPreviewEnabled: true,
  monitorReconnectTestsPreviewEnabled: true,
  keyboardShortcutTestsPreviewEnabled: true,
  liveShowTroubleshootingDocsEnabled: true,
  hostChecksRunRealPlayback: false,
  hostChecksControlLiveShow: false,
  hostChecksChangeDisplayState: false,
  hostChecksReconnectMonitors: false,
  hostChecksRegisterKeyboardHooks: false,
  hostChecksReadMediaFiles: false,
  hostChecksWriteRuntimeState: false
});
