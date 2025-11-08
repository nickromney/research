const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Subscription key storage (simulates APIM subscription keys)
const subscriptionKeys = {
  'primary-key-12345': {
    name: 'Project 1 Subscription',
    product: 'project-1-apis',
    rateLimit: 100,  // requests per minute
    quota: 10000,    // requests per month
  },
  'secondary-key-67890': {
    name: 'Project 2 Subscription',
    product: 'project-2-apis',
    rateLimit: 10,   // lower rate limit for demo
    quota: 1000,
  },
  'admin-key-99999': {
    name: 'Admin Subscription',
    product: 'admin-apis',
    rateLimit: 1000,
    quota: 100000,
  },
};

// Rate limiting tracker (in-memory)
const rateLimitTracker = {};

// Request counter for quota
const quotaTracker = {};

// Middleware: Check subscription key
const checkSubscriptionKey = (req, res, next) => {
  const subKey = req.headers['ocp-apim-subscription-key'];

  if (!subKey) {
    return res.status(401).json({
      statusCode: 401,
      message: 'Access denied due to missing subscription key. Make sure to include subscription key when making requests to an API.',
    });
  }

  if (!subscriptionKeys[subKey]) {
    return res.status(401).json({
      statusCode: 401,
      message: 'Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription.',
    });
  }

  req.subscription = subscriptionKeys[subKey];
  req.subscriptionKey = subKey;
  next();
};

// Middleware: Rate limiting
const rateLimit = (req, res, next) => {
  const subKey = req.subscriptionKey;
  const now = Date.now();
  const minute = Math.floor(now / 60000);

  if (!rateLimitTracker[subKey]) {
    rateLimitTracker[subKey] = {};
  }

  if (!rateLimitTracker[subKey][minute]) {
    rateLimitTracker[subKey][minute] = 0;
  }

  rateLimitTracker[subKey][minute]++;

  const requests = rateLimitTracker[subKey][minute];
  const limit = req.subscription.rateLimit;

  res.setHeader('X-RateLimit-Limit', limit);
  res.setHeader('X-RateLimit-Remaining', Math.max(0, limit - requests));
  res.setHeader('X-RateLimit-Reset', (minute + 1) * 60);

  if (requests > limit) {
    return res.status(429).json({
      statusCode: 429,
      message: `Rate limit is exceeded. Try again in ${60 - (now % 60000) / 1000} seconds.`,
    });
  }

  next();
};

// Middleware: Quota tracking (simplified)
const quotaCheck = (req, res, next) => {
  const subKey = req.subscriptionKey;

  if (!quotaTracker[subKey]) {
    quotaTracker[subKey] = 0;
  }

  quotaTracker[subKey]++;

  const used = quotaTracker[subKey];
  const limit = req.subscription.quota;

  res.setHeader('X-Quota-Limit', limit);
  res.setHeader('X-Quota-Remaining', Math.max(0, limit - used));

  if (used > limit) {
    return res.status(403).json({
      statusCode: 403,
      message: 'Quota exceeded. The subscription has used up its quota.',
    });
  }

  next();
};

// APIM Gateway: Proxy to backend
app.all('/api/*', checkSubscriptionKey, rateLimit, quotaCheck, async (req, res) => {
  // Extract path after /api/
  const backendPath = req.path.replace('/api/', '');

  // WARNING: SSRF VULNERABILITY - FOR DEMO/LEARNING ONLY!
  // The backend URL can be specified via query parameter, which allows
  // arbitrary URL redirection (Server-Side Request Forgery).
  // DO NOT USE IN PRODUCTION without proper URL validation/whitelisting!
  //
  // For production, use a whitelist of allowed backend URLs:
  // const allowedBackends = ['https://api1.example.com', 'https://api2.example.com'];
  // if (req.query.backend && !allowedBackends.includes(req.query.backend)) {
  //   return res.status(400).json({error: 'Invalid backend URL'});
  // }
  const backendUrl = req.query.backend || `https://httpbin.org/${backendPath}`;

  console.log(`[APIM] ${req.method} ${req.path} -> ${backendUrl}`);
  console.log(`[APIM] Subscription: ${req.subscription.name} (${req.subscription.product})`);

  try {
    const response = await axios({
      method: req.method,
      url: backendUrl,
      data: req.body,
      headers: {
        'Content-Type': 'application/json',
        'X-Forwarded-For': req.ip,
        'X-APIM-Subscription-Name': req.subscription.name,
      },
      timeout: 30000,
      validateStatus: () => true, // Accept any status code
    });

    // Add APIM headers to response
    res.setHeader('X-APIM-Gateway', 'mock-apim-simulator');
    res.setHeader('X-APIM-Product', req.subscription.product);

    res.status(response.status).json(response.data);
  } catch (error) {
    console.error(`[APIM] Error: ${error.message}`);

    if (error.code === 'ECONNABORTED') {
      return res.status(504).json({
        statusCode: 504,
        message: 'Gateway timeout. The backend service did not respond in time.',
      });
    }

    res.status(500).json({
      statusCode: 500,
      message: 'Internal server error occurred while processing the request.',
      error: error.message,
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'APIM Simulator',
    timestamp: new Date().toISOString(),
    subscriptions: Object.keys(subscriptionKeys).length,
  });
});

// Info endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Azure APIM Simulator',
    version: '1.0.0',
    description: 'Simulates Azure API Management with subscription keys and rate limiting',
    endpoints: {
      gateway: 'ALL /api/* (requires Ocp-Apim-Subscription-Key header)',
      health: 'GET /health',
      stats: 'GET /stats',
    },
    subscriptionKeys: Object.keys(subscriptionKeys).map(key => ({
      key: key,
      name: subscriptionKeys[key].name,
      product: subscriptionKeys[key].product,
      rateLimit: `${subscriptionKeys[key].rateLimit} req/min`,
      quota: `${subscriptionKeys[key].quota} req/month`,
    })),
    usage: {
      header: 'Ocp-Apim-Subscription-Key: YOUR_KEY',
      example: `curl -H "Ocp-Apim-Subscription-Key: primary-key-12345" http://localhost:8080/api/get`,
    },
  });
});

// Stats endpoint
app.get('/stats', (req, res) => {
  const stats = {};

  Object.keys(subscriptionKeys).forEach(key => {
    const currentMinute = Math.floor(Date.now() / 60000);
    const rateLimitCount = rateLimitTracker[key]?.[currentMinute] || 0;
    const quotaCount = quotaTracker[key] || 0;

    stats[key] = {
      name: subscriptionKeys[key].name,
      currentMinuteRequests: rateLimitCount,
      rateLimit: subscriptionKeys[key].rateLimit,
      totalRequests: quotaCount,
      quota: subscriptionKeys[key].quota,
    };
  });

  res.json(stats);
});

// Reset stats (for testing)
app.post('/reset-stats', (req, res) => {
  Object.keys(rateLimitTracker).forEach(key => delete rateLimitTracker[key]);
  Object.keys(quotaTracker).forEach(key => delete quotaTracker[key]);

  res.json({
    message: 'Statistics reset successfully',
    timestamp: new Date().toISOString(),
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log('=====================================');
  console.log('APIM Simulator Started');
  console.log('=====================================');
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Gateway endpoint: http://localhost:${PORT}/api/*`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Stats: http://localhost:${PORT}/stats`);
  console.log('');
  console.log('Available subscription keys:');
  Object.keys(subscriptionKeys).forEach(key => {
    const sub = subscriptionKeys[key];
    console.log(`  - ${key}`);
    console.log(`    Name: ${sub.name}`);
    console.log(`    Rate Limit: ${sub.rateLimit} req/min`);
  });
  console.log('');
  console.log('Example usage:');
  console.log(`  curl -H "Ocp-Apim-Subscription-Key: primary-key-12345" http://localhost:${PORT}/api/get`);
  console.log('=====================================');
});
