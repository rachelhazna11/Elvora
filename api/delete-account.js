// api/delete-account.js — Vercel Node.js Function
// Deletes the authenticated user's account and all owned data.
// Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars (server-side only).

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default async function handler(req, res) {
  Object.entries(CORS).forEach(([k, v]) => res.setHeader(k, v));

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceKey  = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceKey) return res.status(503).json({ error: 'Server not configured' });

  const authHeader = req.headers['authorization'] || '';
  if (!authHeader.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  const token = authHeader.slice(7);

  // Verify the token and get the user's ID
  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: serviceKey, Authorization: `Bearer ${token}` },
  });
  if (!userRes.ok) return res.status(401).json({ error: 'Invalid session' });
  const { id: userId } = await userRes.json();
  if (!userId) return res.status(401).json({ error: 'Invalid session' });

  const serviceHeaders = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    'Content-Type': 'application/json',
    Prefer: 'return=minimal',
  };

  const del = (path) =>
    fetch(`${supabaseUrl}/rest/v1/${path}`, { method: 'DELETE', headers: serviceHeaders });

  const userFilter = `user_id=eq.${userId}`;

  // Delete order_items first (child rows), then orders — avoids the
  // orders_user_or_guest check constraint firing when auth.users SET NULL cascades.
  const orderRows = await fetch(
    `${supabaseUrl}/rest/v1/orders?${userFilter}&select=id`,
    { headers: { ...serviceHeaders, Prefer: 'return=representation' } },
  );
  if (orderRows.ok) {
    const orders = await orderRows.json();
    if (Array.isArray(orders) && orders.length > 0) {
      const ids = orders.map((o) => o.id).join(',');
      await del(`order_items?order_id=in.(${ids})`);
      await del(`orders?${userFilter}`);
    }
  }

  // Delete remaining user-owned tables in parallel
  await Promise.all([
    del(`cart_items?${userFilter}`),
    del(`wishlist_items?${userFilter}`),
    del(`ai_style_sessions?${userFilter}`),
  ]);

  // user_profiles has ON DELETE CASCADE from auth.users, but delete explicitly
  // first so the cascade has nothing left to do.
  await del(`user_profiles?id=eq.${userId}`);

  // Delete the Supabase Auth user (requires service_role)
  const deleteRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
    method: 'DELETE',
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
  });

  if (!deleteRes.ok) {
    const detail = await deleteRes.text();
    console.error('[delete-account] auth user delete failed:', deleteRes.status, detail);
    return res.status(500).json({ error: 'Failed to delete account', detail });
  }

  return res.status(200).json({ success: true });
}
