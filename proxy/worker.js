// MenteViva Jev proxy — forwards POST /jev to the TypeSafe Jev API,
// adding the Bearer key server-side (env binding TYPESAFE_AI_KEY).
// No request rewriting, no body logging, no state.
// Reference implementation for docs/jev-integration.md §Server-side proxy requirement.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/jev" || request.method !== "POST") {
      return new Response("Not found", { status: 404 });
    }
    const upstream = await fetch("https://api.typesafe.ai/v1/systemone", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.TYPESAFE_AI_KEY}`,
      },
      body: request.body, // streamed verbatim
    });
    return new Response(upstream.body, {
      status: upstream.status,
      headers: { "Content-Type": upstream.headers.get("Content-Type") ?? "application/json" },
    });
  },
};
