const express = require('express');
const OAuth2Server = require('@node-oauth/oauth2-server');
const Request = OAuth2Server.Request;
const Response = OAuth2Server.Response;

const app = express();
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// ============================================================================
// WARNING: FOR LEARNING/TESTING ONLY - DO NOT USE IN PRODUCTION!
// ============================================================================
// This server uses hardcoded credentials and in-memory storage.
// - Passwords are stored in plaintext
// - No encryption or hashing
// - Data is lost on restart
// - No input validation
//
// NEVER use these patterns in production code!
// For production, use:
// - Encrypted/hashed passwords (bcrypt, argon2)
// - Persistent database storage
// - Proper input validation and sanitization
// - Environment variables for secrets
// ============================================================================

// In-memory storage (INSECURE - FOR DEMO/LEARNING ONLY!)
const clients = [
  {
    id: 'application',
    clientId: 'application',
    clientSecret: 'secret',  // INSECURE: Hardcoded secret for demo only!
    grants: ['client_credentials', 'password'],
  },
];

const tokens = [];
const users = [
  // INSECURE: Plaintext passwords for demo/testing only!
  {username: 'user1', password: 'password1'},
  {username: 'admin', password: 'admin123'},
];

// OAuth2 model (required by oauth2-server)
const model = {
  getClient: async (clientId, clientSecret) => {
    const client = clients.find(
      c => c.clientId === clientId && (!clientSecret || c.clientSecret === clientSecret)
    );
    return client ? {
      id: client.id,
      grants: client.grants,
    } : false;
  },

  saveToken: async (token, client, user) => {
    const savedToken = {
      accessToken: token.accessToken,
      accessTokenExpiresAt: token.accessTokenExpiresAt,
      client: client,
      user: user,
    };
    tokens.push(savedToken);
    return savedToken;
  },

  getAccessToken: async (accessToken) => {
    return tokens.find(t => t.accessToken === accessToken);
  },

  getUserFromClient: async (client) => {
    // For client_credentials flow
    return {id: 'service-account', username: 'service'};
  },

  getUser: async (username, password) => {
    const user = users.find(
      u => u.username === username && u.password === password
    );
    return user ? {id: username, username: username} : false;
  },

  verifyScope: async (token, scope) => {
    return true;  // Simplified for demo
  },
};

// Create OAuth2 server instance
const oauth = new OAuth2Server({
  model: model,
  accessTokenLifetime: 3600,  // 1 hour
  allowEmptyState: true,
  allowExtendedTokenAttributes: true,
});

// Token endpoint
app.post('/oauth/token', async (req, res) => {
  const request = new Request(req);
  const response = new Response(res);

  try {
    const token = await oauth.token(request, response);
    res.json(token);
  } catch (err) {
    res.status(err.code || 500).json(err);
  }
});

// Protected resource example
app.get('/api/protected', async (req, res) => {
  const request = new Request(req);
  const response = new Response(res);

  try {
    const token = await oauth.authenticate(request, response);
    res.json({
      message: 'Success! You accessed a protected resource.',
      user: token.user,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(err.code || 500).json(err);
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'OAuth2 Server',
    timestamp: new Date().toISOString(),
    tokens: tokens.length,
  });
});

// Info endpoint (helpful for testing)
app.get('/', (req, res) => {
  res.json({
    name: 'Mock OAuth2 Server',
    version: '1.0.0',
    endpoints: {
      token: 'POST /oauth/token',
      protected: 'GET /api/protected',
      health: 'GET /health',
    },
    testClients: [
      {
        clientId: 'application',
        clientSecret: 'secret',
        grants: ['client_credentials', 'password'],
      },
    ],
    testUsers: [
      {username: 'user1', password: 'password1'},
      {username: 'admin', password: 'admin123'},
    ],
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log('=====================================');
  console.log('Mock OAuth2 Server Started');
  console.log('=====================================');
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Token endpoint: POST http://localhost:${PORT}/oauth/token`);
  console.log(`Protected resource: GET http://localhost:${PORT}/api/protected`);
  console.log(`Health check: GET http://localhost:${PORT}/health`);
  console.log('');
  console.log('Test credentials:');
  console.log('  Client ID: application');
  console.log('  Client Secret: secret');
  console.log('  Users: user1/password1, admin/admin123');
  console.log('=====================================');
});
