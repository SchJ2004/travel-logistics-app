import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Standard CORS headers so your Linux/Web app isn't blocked from talking to the server
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { location, term } = await req.json()
    const YELP_API_KEY = Deno.env.get('YELP_API_KEY')

    // Ask Yelp for the top 15 highest-rated spots at that specific airport and terminal
    const response = await fetch(`https://api.yelp.com/v3/businesses/search?location=${encodeURIComponent(location)}&term=${encodeURIComponent(term)}&sort_by=rating&limit=15`, {
      headers: {
        Authorization: `Bearer ${YELP_API_KEY}`,
      },
    })

    const data = await response.json()

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})