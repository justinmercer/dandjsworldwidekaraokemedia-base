const DUET_SEPARATOR_PATTERN = /\b(?:and|feat|featuring|ft|with)\.?\b|[&+/\\]/gi;

function normalizeCatalogText(value) {
  const raw = String(value || '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(DUET_SEPARATOR_PATTERN, ' ')
    .replace(/[^a-z0-9]+/g, ' ');

  return collapseCommonArtistInitialisms(raw.split(/\s+/).filter(Boolean)).join(' ');
}

function normalizeArtistName(value) {
  const tokens = normalizeCatalogText(value).split(/\s+/).filter(Boolean);
  if (tokens[0] === 'the') {
    tokens.shift();
  }

  return tokens.join(' ');
}

function collapseCommonArtistInitialisms(tokens) {
  const collapsed = [];

  for (let index = 0; index < tokens.length; index += 1) {
    const current = tokens[index];
    const next = tokens[index + 1];

    if (current === 'd' && next === 'j') {
      collapsed.push('dj');
      index += 1;
      continue;
    }

    collapsed.push(current);
  }

  return collapsed;
}

module.exports = {
  normalizeArtistName,
  normalizeCatalogText
};
