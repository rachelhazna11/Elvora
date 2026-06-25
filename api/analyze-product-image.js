// api/analyze-product-image.js — Vercel Serverless Function
// Analyzes a product image using NVIDIA NIM vision (Llama 3.2 Vision) to suggest
// the best Elvora activity category and style subcollection.
// Uses the same NVIDIA_API_KEY as style-match (OpenAI-compatible format).
// POST body: { image: string (base64), mediaType?: string }
// Response: { activity: string, subcollection: string }

const NVIDIA_BASE_URL = 'https://integrate.api.nvidia.com/v1';
const MODEL = 'meta/llama-3.2-11b-vision-instruct';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });

const VALID_SUBCOLLECTIONS = {
  padel:    ['matcha-babe', 'court-crush', 'rally-ready'],
  pilates:  ['soft-flow', 'main-character', 'studio-muse'],
  tennis:   ['love-match', 'ace-energy', 'court-girl'],
  training: ['power-mood', 'built-different', 'hot-girl-lift'],
  running:  ['run-era', 'pace-mode', 'runners-high'],
};

const PROMPT = `You are a fashion analyst for Elvora, a premium Indonesian women's activewear brand. Analyze this product image and classify it.

Determine:
1. Which activity category the garment is best suited for
2. Which specific style subcollection it fits

Available categories and their subcollections:

PADEL:
- matcha-babe: sage, ivory, warm cream colors — sporty luxury club aesthetic
- court-crush: charcoal, ivory, soft neutrals — confident feminine court style
- rally-ready: stone, black, muted green — performance-neutral court kit

PILATES:
- soft-flow: warm neutrals, ivory, soft sage, stone — graceful studio luxury
- main-character: monochrome charcoal, cream, earth tones — luxury pilates muse
- studio-muse: soft beige, minimal neutrals — quiet luxury studio uniform

TENNIS:
- love-match: ivory, soft green, clean whites — romantic luxury tennis
- ace-energy: contrast neutrals, charcoal, white — modern performance tennis
- court-girl: ivory, soft cream, muted sage — feminine luxury tennis lifestyle

TRAINING (Gym):
- power-mood: charcoal, black, muted earth tones — elevated training wear
- built-different: monochrome neutrals, deep charcoal — high-performance gym
- hot-girl-lift: soft neutrals, warm beige, muted sage — feminine strength

RUNNING:
- run-era: high-performance running gear, technical fabrics
- pace-mode: speed-focused design, interval and track training
- runners-high: recovery and casual running lifestyle pieces

Analyze the garment's silhouette, color palette, fabric type, design details, and intended movement.

Respond ONLY with a valid JSON object — no explanation, no markdown:
{"activity": "<activity>", "subcollection": "<subcollection-slug>"}`;

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const apiKey = process.env.NVIDIA_API_KEY;
  if (!apiKey) {
    return json({ error: 'AI analysis not configured' }, 503);
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON' }, 400);
  }

  const { image, mediaType = 'image/jpeg' } = body;
  if (!image) {
    return json({ error: 'image field required (base64)' }, 400);
  }

  // Ensure data URL format for NVIDIA NIM image_url
  const dataUrl = image.startsWith('data:')
    ? image
    : `data:${mediaType};base64,${image}`;

  try {
    const response = await fetch(`${NVIDIA_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 100,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: { url: dataUrl },
              },
              {
                type: 'text',
                text: PROMPT,
              },
            ],
          },
        ],
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      return json({ error: data.error?.message || 'NVIDIA API error' }, response.status);
    }

    const rawText = (data.choices?.[0]?.message?.content || '').trim();

    const match = rawText.match(/\{[^}]+\}/);
    if (!match) {
      return json({ error: 'Could not parse AI response', raw: rawText.slice(0, 200) }, 500);
    }

    let result;
    try { result = JSON.parse(match[0]); } catch {
      return json({ error: 'Invalid JSON from AI', raw: rawText.slice(0, 200) }, 500);
    }

    const activity = result.activity;

    if (!VALID_SUBCOLLECTIONS[activity]) {
      return json({ error: 'AI returned unknown activity', raw: rawText }, 500);
    }
    if (!VALID_SUBCOLLECTIONS[activity].includes(result.subcollection)) {
      result.subcollection = VALID_SUBCOLLECTIONS[activity][0];
    }

    return json({ activity: result.activity, subcollection: result.subcollection });
  } catch (err) {
    return json({ error: 'Upstream error', detail: String(err) }, 502);
  }
}
