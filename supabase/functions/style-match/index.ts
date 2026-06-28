// Phase 5 — AI Style Match Edge Function
// Calls NVIDIA NIM (MiniMax-M3) via OpenAI-compatible API and persists results for authenticated users.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers — origin locked to known domains per D-09/D-15
const ALLOWED_ORIGINS = [
  "https://elvorastudio.vercel.app",    // production (legacy)
  "https://elvora.vercel.app",          // production (current Vercel project name)
  "http://localhost:3999",              // local dev
  "http://localhost:5173",              // Vite dev server
  "http://127.0.0.1:3999",             // local dev alt
];

function getCorsHeaders(requestOrigin: string | null): Record<string, string> {
  const origin = requestOrigin && ALLOWED_ORIGINS.includes(requestOrigin)
    ? requestOrigin
    : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

// Request shape (Phase 5 contract):
// {
//   photo_url: string | null,
//   preferences: {
//     activity: string[],
//     fit: string,
//     aesthetic: string,
//     colour: string
//   }
// }

// Response shape from AI (enforced by prompt):
// {
//   recommendations: [{
//     name: string,
//     product_ids: string[],
//     colour_guidance: string,
//     why_it_works: string
//   }],
//   colour_guidance: string  -- top-level colour palette note
// }

serve(async (req) => {
  const requestOrigin = req.headers.get("origin");
  const CORS_HEADERS = getCorsHeaders(requestOrigin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // JWT verification — reject unauthenticated requests per T-05-01 / D-07
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      {
        status: 401,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  // Parse request body
  let body: {
    photo_url?: string | null;
    preferences?: {
      activity?: string[];
      fit?: string;
      aesthetic?: string;
      colour?: string;
    };
  } = {};

  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON in request body" }),
      {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }

  // Log request shape — photo URL logged as "[photo present]" to avoid leaking signed URLs per T-05-03
  console.log(
    "style-match request:",
    JSON.stringify({
      photo_url: body.photo_url ? "[photo present]" : null,
      preferences: body.preferences,
    })
  );

  // ─── NVIDIA NIM (MiniMax-M3) API call — OpenAI-compatible ──────────────────
  const NVIDIA_API_KEY = Deno.env.get("NVIDIA_API_KEY");

  // Catalog context: live ELVORA catalog (15 products) — must stay in sync
  // with the actual `products` table. Keeping this hardcoded list out of
  // sync with the database means every recommended product_id fails to
  // resolve to a real row (caused a full outage of product images previously).
  const CATALOG_CONTEXT = `
You are Elvy, the premium personal stylist for ELVORA activewear. Your goal is to make the
user feel confident and understood. Use a sophisticated yet encouraging tone. Reference their
photo directly (e.g., "Based on your cool skin tone...", "Since you have an athletic build...").

The user's style preferences:
- Activities: ${(body.preferences?.activity ?? []).join(", ") || "general activewear"}
- Fit preference: ${body.preferences?.fit ?? "relaxed"}
- Aesthetic: ${body.preferences?.aesthetic ?? "minimal"}
- Colour preference: ${body.preferences?.colour ?? "neutral"}

ELVORA CATALOG (15 products — use ONLY these product_ids in your recommendations):
[
  {"id":"c2000000-0000-0000-0000-000000000001","name":"Contour Seam Legging","category":"leggings","tags":["training","gym","seamless","versatile"],"colours":["Burgundy","Lavender","Midnight Navy","Obsidian"],"price":1299000},
  {"id":"c2000000-0000-0000-0000-000000000002","name":"Court Racerback Bra","category":"sports-bra","tags":["tennis","padel","court","racerback","medium-support"],"colours":["Blush","Lavender","Obsidian","Pure White"],"price":999000},
  {"id":"c2000000-0000-0000-0000-000000000003","name":"Twist Ease Long Sleeve","category":"top","tags":["yoga","studio","relaxed","twist-detail"],"colours":["Blush Pink","Pure White","Sage","Warm Stone"],"price":1099000},
  {"id":"c2000000-0000-0000-0000-000000000004","name":"Kinetic Crop Tee","category":"top","tags":["training","gym","crop","versatile"],"colours":["Coral","Obsidian","Pure White","Sage"],"price":799000},
  {"id":"c2000000-0000-0000-0000-000000000005","name":"Active Flow Tunic","category":"top","tags":["studio","yoga","flowy","relaxed"],"colours":["Dusty Mauve","Ivory","Steel Teal","Warm Stone"],"price":1199000},
  {"id":"c2000000-0000-0000-0000-000000000006","name":"Swift Crop Long Sleeve","category":"top","tags":["running","outdoor","crop","technical"],"colours":["Aqua Mint","Coral Pink","Pure White","Sage"],"price":1099000},
  {"id":"c2000000-0000-0000-0000-000000000007","name":"Motion Marl Hoodie","category":"jacket","tags":["recovery","casual","cozy","marl"],"colours":["Blush","Charcoal","Heather Grey","Midnight Navy"],"price":1799000},
  {"id":"c2000000-0000-0000-0000-000000000008","name":"Revive Half-Zip","category":"jacket","tags":["recovery","training","layering","half-zip"],"colours":["Dusty Rose","Heather Grey","Ice Blue","Ivory"],"price":1499000},
  {"id":"c2000000-0000-0000-0000-000000000009","name":"Shell Run Jacket","category":"jacket","tags":["running","outdoor","weatherproof","packable"],"colours":["Forest","Ivory","Midnight Navy","Obsidian"],"price":2199000},
  {"id":"c2000000-0000-0000-0000-000000000010","name":"Pace Running Shorts","category":"shorts","tags":["running","gym","lightweight"],"colours":["Aqua Mint","Coral","Obsidian","Sage"],"price":899000},
  {"id":"c2000000-0000-0000-0000-000000000011","name":"Soft Day Wide-Leg Set","category":"set","tags":["studio","athleisure","relaxed","matched-set"],"colours":["Charcoal","Dusty Rose","Ivory","Sage"],"price":2299000},
  {"id":"c2000000-0000-0000-0000-000000000012","name":"Polo Court Set","category":"set","tags":["tennis","padel","court","matched-set"],"colours":["Blush Rose","Cream","Obsidian","Royal Blue"],"price":2499000},
  {"id":"c2000000-0000-0000-0000-000000000013","name":"Grand Slam Court Dress","category":"dress","tags":["tennis","padel","court","structured"],"colours":["Blush Rose","Ivory","Midnight Navy","Pure White"],"price":2799000},
  {"id":"c2000000-0000-0000-0000-000000000014","name":"Rally Pleated Court Skirt","category":"skirt","tags":["tennis","padel","court","pleated"],"colours":["Burgundy","Midnight Navy","Obsidian","Pure White"],"price":1399000},
  {"id":"c2000000-0000-0000-0000-000000000015","name":"Ace Tennis Dress","category":"dress","tags":["tennis","court","elevated"],"colours":["Blush Pink","Ivory","Midnight Navy","Terracotta Rose"],"price":2499000}
]

You must respond with ONLY valid JSON in the following shape (no markdown, no prose outside JSON):
{
  "recommendations": [
    {
      "name": "<outfit name>",
      "product_ids": ["<id from catalog above>", "<id from catalog above>"],
      "colour_guidance": "<specific colour advice for this outfit>",
      "why_it_works": "<1-2 sentences referencing their photo attributes>"
    }
  ],
  "colour_guidance": "<overall palette recommendation for this user>"
}

Return exactly 3 outfit recommendations using ONLY product_ids from the catalog above.
Copy each product_id exactly as it appears in the catalog above — do not retype, abbreviate, or modify the UUID characters.
If you cannot determine appropriate styles, default to the best-seller items: c2000000-0000-0000-0000-000000000013, c2000000-0000-0000-0000-000000000002, c2000000-0000-0000-0000-000000000004.
`;

  interface Recommendation {
    name: string;
    product_ids: string[];
    colour_guidance: string;
    why_it_works: string;
  }

  interface AiResponse {
    recommendations: Recommendation[];
    colour_guidance: string;
  }

  let aiResult: AiResponse;

  if (NVIDIA_API_KEY) {
    // Build user message — include photo if provided (D-04: already resized by client)
    type ContentPart =
      | { type: "text"; text: string }
      | { type: "image_url"; image_url: { url: string } };

    const userContent: ContentPart[] = [];

    if (body.photo_url) {
      let photoUrl = body.photo_url;

      // If signed URL, fetch and convert to base64 data URI for inline delivery
      if (body.photo_url.startsWith("https://")) {
        try {
          const controller = new AbortController();
          const fetchTimeout = setTimeout(() => controller.abort(), 10_000);
          const imgResponse = await fetch(body.photo_url, { signal: controller.signal });
          clearTimeout(fetchTimeout);
          if (imgResponse.ok) {
            const imgBuffer = await imgResponse.arrayBuffer();
            const contentType = imgResponse.headers.get("content-type") ?? "image/jpeg";
            // Chunked base64 — avoids call-stack overflow from spread on large arrays
            const bytes = new Uint8Array(imgBuffer);
            let binary = "";
            const CHUNK = 8192;
            for (let i = 0; i < bytes.length; i += CHUNK) {
              binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK));
            }
            photoUrl = `data:${contentType.split(";")[0]};base64,${btoa(binary)}`;
          } else {
            console.warn("Failed to fetch photo from signed URL:", imgResponse.status);
            photoUrl = "";
          }
        } catch (fetchErr) {
          console.warn("Error fetching photo, proceeding without image:", fetchErr);
          photoUrl = "";
        }
      }

      if (photoUrl) {
        userContent.push({ type: "image_url", image_url: { url: photoUrl } });
      }
    }

    userContent.push({
      type: "text",
      text: "Analyze the user photo above (if provided) and recommend 3 Elvora outfits. Follow the JSON format in your instructions exactly.",
    });

    const nvidiaPayload = {
      model: "minimaxai/minimax-m3",
      messages: [
        { role: "system", content: CATALOG_CONTEXT },
        { role: "user", content: userContent.length === 1 ? userContent[0].text : userContent },
      ],
      max_tokens: 1024,
      temperature: 0.7,
    };

    const nvidiaController = new AbortController();
    const nvidiaTimeout = setTimeout(() => nvidiaController.abort(), 30_000);
    const nvidiaResponse = await fetch(
      "https://integrate.api.nvidia.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${NVIDIA_API_KEY}`,
        },
        body: JSON.stringify(nvidiaPayload),
        signal: nvidiaController.signal,
      }
    );
    clearTimeout(nvidiaTimeout);

    if (!nvidiaResponse.ok) {
      const errText = await nvidiaResponse.text();
      console.error("NVIDIA NIM error:", nvidiaResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "AI service temporarily unavailable", detail: `${nvidiaResponse.status}` }),
        {
          status: 502,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        }
      );
    }

    const nvidiaData = await nvidiaResponse.json();
    const rawText: string = nvidiaData?.choices?.[0]?.message?.content ?? "{}";

    // Strip markdown code fences if model wraps JSON in ```json ... ```
    const cleaned = rawText.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "").trim();

    try {
      aiResult = JSON.parse(cleaned) as AiResponse;
    } catch {
      console.error("Failed to parse MiniMax-M3 response as JSON:", rawText);
      return new Response(
        JSON.stringify({ error: "AI returned an unexpected format" }),
        {
          status: 502,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        }
      );
    }
  } else {
    // Development fallback — NVIDIA_API_KEY not configured
    console.log("NVIDIA_API_KEY not set — returning mock response");
    aiResult = {
      recommendations: [
        {
          name: "Court Ready Set",
          product_ids: [
            "c2000000-0000-0000-0000-000000000004",
            "c2000000-0000-0000-0000-000000000002",
          ],
          colour_guidance: "Earthy, muted tones complement your natural colouring — lean into sage and ivory.",
          why_it_works: "The relaxed crop tee and supportive racerback bra align with your preference for versatile activewear.",
        },
        {
          name: "Pace Setter Look",
          product_ids: [
            "c2000000-0000-0000-0000-000000000010",
            "c2000000-0000-0000-0000-000000000006",
          ],
          colour_guidance: "Cool, fresh tones anchor your look with effortless confidence.",
          why_it_works: "Your preference for structured, technical fits makes this pairing ideal for running or court sports.",
        },
        {
          name: "Editorial Court Dress",
          product_ids: [
            "c2000000-0000-0000-0000-000000000013",
          ],
          colour_guidance: "Cream and white tones highlight your warm undertones beautifully.",
          why_it_works: "An editorial edge that matches your stated aesthetic — elevated and wearable.",
        },
      ],
      colour_guidance: "Your palette is naturally suited to warm neutrals — sage, ivory, blush — with occasional navy for contrast.",
    };
  }

  // ─── Session persistence for authenticated users (D-06 / F-035) ──────────
  // Extract user from JWT using Supabase client (service role bypasses RLS for writes here;
  // we rely on the anon key + auth header to get the correct user context).
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

  if (SUPABASE_URL && SUPABASE_ANON_KEY) {
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get the authenticated user — null if token is invalid/expired
    const { data: { user } } = await supabase.auth.getUser();

    if (user?.id) {
      // Insert session — failure is non-fatal (result still returned to user)
      const { error: insertError } = await supabase
        .from("ai_style_sessions")
        .insert({
          user_id: user.id,
          preferences: body.preferences ?? {},
          recommendations: aiResult.recommendations,
          colour_guidance: aiResult.colour_guidance ?? null,
        });

      if (insertError) {
        // Log but do not block the response — session save failure is non-fatal
        console.error("Failed to save AI session:", insertError.message);
      } else {
        console.log("AI session saved for user:", user.id);
      }
    }
    // If user is null or guest, session is not persisted (D-06)
  }

  return new Response(JSON.stringify(aiResult), {
    status: 200,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
