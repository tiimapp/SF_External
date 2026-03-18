const MOCK_RESULTS = [
  {
    id: 'mock-001',
    title: 'Sample Knowledge Article: Federated Search Overview',
    url: 'https://example.com/articles/federated-search-overview',
    description: 'A mock result describing how Salesforce Federated Search can connect to external content sources.',
    type: 'Knowledge',
    updatedAt: '2026-03-18T08:00:00Z'
  },
  {
    id: 'mock-002',
    title: 'Sample FAQ: OpenSearch Endpoint Test Record',
    url: 'https://example.com/faq/opensearch-endpoint-test',
    description: 'A fixed mock FAQ record returned by the Node.js OpenSearch service for connectivity testing.',
    type: 'FAQ',
    updatedAt: '2026-03-17T10:30:00Z'
  },
  {
    id: 'mock-003',
    title: 'Sample External Document: Customer Integration Guide',
    url: 'https://example.com/docs/customer-integration-guide',
    description: 'A mock external document result used to validate Salesforce search result rendering.',
    type: 'Document',
    updatedAt: '2026-03-16T14:15:00Z'
  },
  {
    id: 'mock-004',
    title: 'Sample Release Note: Search Connector Mock Service',
    url: 'https://example.com/releases/search-connector-mock-service',
    description: 'A mock release note entry for testing fixed search results from a hosted VPS service.',
    type: 'Release Note',
    updatedAt: '2026-03-15T09:45:00Z'
  }
];

module.exports = {
  MOCK_RESULTS
};