const GEMINI_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

export default {
  async fetch(request, env) {

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin':  '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-App-Token',
          'Access-Control-Max-Age':       '86400',
        },
      });
    }

    if (request.method !== 'POST') {
      return errorResponse(405, 'Method not allowed');
    }

    const appToken = request.headers.get('X-App-Token') ?? '';
    if (appToken !== (env.APP_TOKEN ?? 'megavital-2024')) {
      return errorResponse(401, 'Unauthorized');
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return errorResponse(400, 'Invalid JSON body');
    }

    if (!env.GEMINI_KEY) {
      return errorResponse(500, 'GEMINI_KEY not configured on server');
    }

    let geminiRes;
    try {
      geminiRes = await fetch(`${GEMINI_URL}?key=${env.GEMINI_KEY}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(body),
      });
    } catch (e) {
      return errorResponse(502, `Error conectando con Gemini: ${e.message}`);
    }

    const data = await geminiRes.json();
    return new Response(JSON.stringify(data), {
      status: geminiRes.status,
      headers: {
        'Content-Type':                'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  },
};

function errorResponse(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type':                'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}