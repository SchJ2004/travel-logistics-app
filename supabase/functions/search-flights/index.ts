// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "@supabase/functions-js/edge-runtime.d.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. We now expect "departureDate" in the payload from Flutter!
    const { origin, destination, departureDate } = await req.json()
    const duffelKey = Deno.env.get('DUFFEL_API_KEY')

    // 2. Pass that exact date directly to Duffel
    const duffelResponse = await fetch('https://api.duffel.com/air/offer_requests', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${duffelKey}`,
        'Duffel-Version': 'v2',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        data: {
          slices: [{ origin: origin, destination: destination, departure_date: departureDate }],
          passengers: [{ type: "adult" }],
          cabin_class: "economy"
        }
      })
    });

    const flightData = await duffelResponse.json();

    if (flightData.errors) {
        throw new Error(flightData.errors[0].message);
    }

    const offers = flightData.data.offers.map((offer: any) => ({
        id: offer.id,
        airline: offer.owner.name,
        price: offer.total_amount,
        currency: offer.total_currency,
    })).slice(0, 5);

    return new Response(
      JSON.stringify({ flights: offers }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    )
  }
})