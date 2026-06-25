// Phase 5 — AI Style Match Edge Function
// Calls NVIDIA NIM (MiniMax-M3) via OpenAI-compatible API and persists results for authenticated users.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers — origin locked to known domains per D-09/D-15
// Wildcard (*) is explicitly prohibited by T-05-02 (threat model)
const ALLOWED_ORIGINS = [
  "https://elvorastudio.vercel.app",    // production — update if Vercel URL differs
  "http://localhost:3999",              // local dev
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

  // Catalog context: 22 hero products with real Supabase UUIDs (D-02)
  const CATALOG_CONTEXT = `
You are Elvy, the premium personal stylist for ELVORA activewear. Your goal is to make the
user feel confident and understood. Use a sophisticated yet encouraging tone. Reference their
photo directly (e.g., "Based on your cool skin tone...", "Since you have an athletic build...").

The user's style preferences:
- Activities: ${(body.preferences?.activity ?? []).join(", ") || "general activewear"}
- Fit preference: ${body.preferences?.fit ?? "relaxed"}
- Aesthetic: ${body.preferences?.aesthetic ?? "minimal"}
- Colour preference: ${body.preferences?.colour ?? "neutral"}

ELVORA CATALOG (22 products — use ONLY these product_ids in your recommendations):
[
  {"id":"c1000000-0000-0000-0000-000000000001","name":"Serenity Ribbed Legging","category":"leggings","tags":["studio","athleisure","versatile"],"colours":["sage","chalk"],"price":85},
  {"id":"c1000000-0000-0000-0000-000000000002","name":"Aerial High-Rise Legging","category":"leggings","tags":["training","gym","high-impact"],"colours":["multiple"],"price":89},
  {"id":"c1000000-0000-0000-0000-000000000003","name":"Studio 7/8 Legging","category":"leggings","tags":["pilates","barre","yoga","cropped"],"colours":["multiple"],"price":79},
  {"id":"c1000000-0000-0000-0000-000000000004","name":"Flow Seamless Legging","category":"leggings","tags":["yoga","pilates","seamless","technical"],"colours":["multiple"],"price":95},
  {"id":"c1000000-0000-0000-0000-000000000005","name":"Contour Pocket Legging","category":"leggings","tags":["running","gym","pockets"],"colours":["multiple"],"price":92},
  {"id":"c1000000-0000-0000-0000-000000000006","name":"Luminary Longline Bra","category":"sports-bra","tags":["pilates","yoga","low-impact","longline"],"colours":["multiple"],"price":68},
  {"id":"c1000000-0000-0000-0000-000000000007","name":"Sculpt Medium Support Bra","category":"sports-bra","tags":["cycling","HIIT","medium-support"],"colours":["multiple"],"price":65},
  {"id":"c1000000-0000-0000-0000-000000000008","name":"Equilibrium Sports Bra","category":"sports-bra","tags":["studio","low-impact","minimal","triangle"],"colours":["multiple"],"price":72},
  {"id":"c1000000-0000-0000-0000-000000000009","name":"Aura High Support Bra","category":"sports-bra","tags":["running","high-impact","high-support"],"colours":["multiple"],"price":78},
  {"id":"c1000000-0000-0000-0000-000000000010","name":"Courtside Pleated Skirt","category":"skirt","tags":["padel","tennis","court","pleated"],"colours":["multiple"],"price":85},
  {"id":"c1000000-0000-0000-0000-000000000011","name":"Match Point Tennis Skirt","category":"skirt","tags":["tennis","court","structured"],"colours":["multiple"],"price":88},
  {"id":"c1000000-0000-0000-0000-000000000012","name":"Rally Wrap Skirt","category":"skirt","tags":["padel","court","wrap","versatile"],"colours":["multiple"],"price":82},
  {"id":"c1000000-0000-0000-0000-000000000013","name":"Elevate Tank Top","category":"top","tags":["training","gym","racerback","versatile"],"colours":["multiple"],"price":55},
  {"id":"c1000000-0000-0000-0000-000000000014","name":"Serenity Ribbed Tank","category":"top","tags":["studio","athleisure","ribbed","tonal"],"colours":["sage","chalk"],"price":58},
  {"id":"c1000000-0000-0000-0000-000000000015","name":"Vital Long Sleeve Top","category":"top","tags":["running","outdoor","thumbhole","cold-weather"],"colours":["multiple"],"price":72},
  {"id":"c1000000-0000-0000-0000-000000000016","name":"Altitude Zip Jacket","category":"jacket","tags":["training","outdoor","packable","full-zip"],"colours":["multiple"],"price":125},
  {"id":"c1000000-0000-0000-0000-000000000017","name":"Motion Track Jacket","category":"jacket","tags":["studio","versatile","track","boxy"],"colours":["multiple"],"price":138},
  {"id":"c1000000-0000-0000-0000-000000000018","name":"Restore Hoodie","category":"jacket","tags":["recovery","casual","cozy","rest-day"],"colours":["multiple"],"price":115},
  {"id":"c1000000-0000-0000-0000-000000000019","name":"Padel Power Set","category":"set","tags":["padel","court","complete-look"],"colours":["multiple"],"price":145},
  {"id":"c1000000-0000-0000-0000-000000000020","name":"Pilates Harmony Set","category":"set","tags":["pilates","studio","matched-set"],"colours":["multiple"],"price":138},
  {"id":"c1000000-0000-0000-0000-000000000021","name":"Studio Duo Set","category":"set","tags":["studio","athleisure","tonal","ribbed"],"colours":["sage","chalk"],"price":132},
  {"id":"c1000000-0000-0000-0000-000000000022","name":"Flow Practice Set","category":"set","tags":["yoga","meditation","seamless","minimal"],"colours":["multiple"],"price":128}
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
If you cannot determine appropriate styles, default to the best-seller items: c1000000-0000-0000-0000-000000000001, c1000000-0000-0000-0000-000000000006, c1000000-0000-0000-0000-000000000010.
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
          const imgResponse = await fetch(body.photo_url);
          if (imgResponse.ok) {
            const imgBuffer = await imgResponse.arrayBuffer();
            const contentType = imgResponse.headers.get("content-type") ?? "image/jpeg";
            const base64 = btoa(String.fromCharCode(...new Uint8Array(imgBuffer)));
            photoUrl = `data:${contentType.split(";")[0]};base64,${base64}`;
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

    const nvidiaResponse = await fetch(
      "https://integrate.api.nvidia.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${NVIDIA_API_KEY}`,
        },
        body: JSON.stringify(nvidiaPayload),
      }
    );

    if (!nvidiaResponse.ok) {
      const errText = await nvidiaResponse.text();
      console.error("NVIDIA NIM error:", nvidiaResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "AI service temporarily unavailable" }),
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
          name: "Sage Studio Set",
          product_ids: [
            "c1000000-0000-0000-0000-000000000001",
            "c1000000-0000-0000-0000-000000000006",
          ],
          colour_guidance: "Earthy tones complement your natural colouring — lean into sage and ivory.",
          why_it_works: "The relaxed fit and muted palette align perfectly with your aesthetic preference for minimal activewear.",
        },
        {
          name: "Court Ready Look",
          product_ids: [
            "c1000000-0000-0000-0000-000000000010",
            "c1000000-0000-0000-0000-000000000009",
          ],
          colour_guidance: "Classic monochrome anchors your look with effortless confidence.",
          why_it_works: "Your preference for structured fits makes this pairing ideal for padel or tennis.",
        },
        {
          name: "Ivory Editorial Set",
          product_ids: [
            "c1000000-0000-0000-0000-000000000020",
            "c1000000-0000-0000-0000-000000000017",
          ],
          colour_guidance: "Cream and white tones highlight your warm undertones beautifully.",
          why_it_works: "An editorial edge that matches your stated aesthetic — elevated and wearable.",
        },
      ],
      colour_guidance: "Your palette is naturally suited to warm neutrals — sage, ivory, camel — with occasional slate blue for contrast.",
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
