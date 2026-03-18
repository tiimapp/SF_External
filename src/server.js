const express = require('express');
const { MOCK_RESULTS } = require('./mockData');

const app = express();

const PORT = Number(process.env.PORT || 3000);
const BASE_URL = process.env.BASE_URL || `http://localhost:${PORT}`;
const DEFAULT_RESULT_COUNT = Number(process.env.DEFAULT_RESULT_COUNT || 3);
const MOCK_SERVICE_NAME = process.env.MOCK_SERVICE_NAME || 'Salesforce Mock OpenSearch';

app.use(express.json());

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

function getSearchTerm(req) {
  return (
    req.query.q ||
    req.query.query ||
    req.query.searchTerms ||
    req.query.term ||
    ''
  ).toString();
}

function getLimitedResults() {
  return MOCK_RESULTS.slice(0, DEFAULT_RESULT_COUNT).map((item) => ({ ...item }));
}

function buildJsonResponse(searchTerm) {
  const items = getLimitedResults();

  return {
    service: MOCK_SERVICE_NAME,
    searchTerms: searchTerm,
    totalResults: items.length,
    startIndex: 1,
    itemsPerPage: items.length,
    items
  };
}

function buildOpenSearchSuggestionArray(searchTerm) {
  const items = getLimitedResults();

  return [
    searchTerm,
    items.map((item) => item.title),
    items.map((item) => item.description),
    items.map((item) => item.url)
  ];
}

app.get('/', (req, res) => {
  res.json({
    name: MOCK_SERVICE_NAME,
    message: 'Mock OpenSearch service for Salesforce Federated Search testing.',
    endpoints: {
      health: `${BASE_URL}/health`,
      description: `${BASE_URL}/opensearch.xml`,
      search: `${BASE_URL}/search?q=test`,
      suggestStyle: `${BASE_URL}/search?q=test&format=os-array`
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: MOCK_SERVICE_NAME,
    timestamp: new Date().toISOString()
  });
});

app.get('/opensearch.xml', (req, res) => {
  res.type('application/opensearchdescription+xml');
  res.send(`<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>${MOCK_SERVICE_NAME}</ShortName>
  <Description>Mock OpenSearch service for Salesforce Federated Search testing</Description>
  <InputEncoding>UTF-8</InputEncoding>
  <OutputEncoding>UTF-8</OutputEncoding>
  <Url type="application/json" template="${BASE_URL}/search?q={searchTerms}" />
  <Url type="application/json" rel="suggestions" template="${BASE_URL}/search?q={searchTerms}&amp;format=os-array" />
</OpenSearchDescription>`);
});

app.get('/search', (req, res) => {
  const searchTerm = getSearchTerm(req);
  const format = (req.query.format || req.query.output || 'json').toString().toLowerCase();

  if (format === 'os-array' || format === 'suggest' || format === 'suggestions') {
    return res.json(buildOpenSearchSuggestionArray(searchTerm));
  }

  return res.json(buildJsonResponse(searchTerm));
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'Use /search, /health, or /opensearch.xml'
  });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`${MOCK_SERVICE_NAME} running at ${BASE_URL}`);
  });
}

module.exports = app;