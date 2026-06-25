// api/ai-advisor.js — Vercel Edge Function
// Proxy for NVIDIA NIM API (MiniMax-M3) — keeps NVIDIA_API_KEY out of the browser.
// NVIDIA NIM uses OpenAI-compatible chat/completions format.
// Returns normalized { reply: "..." } so the frontend is provider-agnostic.

const NVIDIA_BASE_URL = 'https://integrate.api.nvidia.com/v1';
const MODEL = 'minimaxai/minimax-m3';

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

const SYSTEM_PROMPT = `Kamu adalah Elvy, AI Style Advisor untuk brand ELVORA — women activewear Indonesia premium.
Jawab dalam Bahasa Indonesia yang hangat, friendly, dan stylish. Gunakan emoji sesekali.
Produk ELVORA tersedia di kategori: Padel (Matcha Babe, Court Crush, Rally Ready), Pilates (Soft Flow, Main Character, Studio Muse), Tennis (Love Match, Ace Energy, Court Girl), Gym/Training (Power Mood, Built Different, Hot Girl Lift), Running (Run Era, Pace Mode, Runner's High).
Rentang harga: Rp 189.000 – Rp 689.000. Tersedia ukuran XS–XXL. Fabric: moisture-wicking, 4-way stretch, breathable.
Rekomendasikan koleksi spesifik kalau relevan. Jawab singkat, max 3-4 kalimat, langsung to the point.`;

export default async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const apiKey = process.env.NVIDIA_API_KEY;
  if (!apiKey) {
    return json({ error: 'AI advisor not configured' }, 503);
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON' }, 400);
  }

  const { messages } = body;
  if (!Array.isArray(messages) || messages.length === 0) {
    return json({ error: 'messages array required' }, 400);
  }

  // NVIDIA NIM uses OpenAI chat/completions format.
  // System prompt is injected as the first message with role "system".
  const payload = {
    model: MODEL,
    max_tokens: 512,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      ...messages,
    ],
  };

  try {
    const upstream = await fetch(`${NVIDIA_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const text = await upstream.text();
    let data;
    try { data = JSON.parse(text); } catch { data = {}; }

    // Normalize to { reply } so the frontend stays provider-agnostic.
    const reply = data?.choices?.[0]?.message?.content
      ?? data?.error?.message
      ?? `Error dari NVIDIA (${upstream.status}): ${text.slice(0, 120)}`;

    return json({ reply }, upstream.ok ? 200 : upstream.status);
  } catch (err) {
    return json({ error: 'Upstream error', detail: String(err) }, 502);
  }
};

export const config = { runtime: 'edge' };
