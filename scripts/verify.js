const http = require('http');
const app = require('../src/server');

const PORT = 3100;

function request(path) {
  return new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${PORT}${path}`, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body: data, headers: res.headers });
      });
    }).on('error', reject);
  });
}

async function main() {
  const server = app.listen(PORT);

  try {
    const health = await request('/health');
    const search = await request('/search?q=test');
    const xml = await request('/opensearch.xml');

    console.log('HEALTH_STATUS:', health.statusCode);
    console.log('HEALTH_BODY:', health.body);
    console.log('SEARCH_STATUS:', search.statusCode);
    console.log('SEARCH_BODY:', search.body);
    console.log('XML_STATUS:', xml.statusCode);
    console.log('XML_CONTENT_TYPE:', xml.headers['content-type']);
  } finally {
    server.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});