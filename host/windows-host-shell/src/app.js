
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
  rotationChangesLiveState: false
});
