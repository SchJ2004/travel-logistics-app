import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'

// Initialize Stripe
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2022-11-15',
  httpClient: Stripe.createFetchHttpClient(),
});

// Initialize Supabase Admin Client (Bypasses Row Level Security to safely update DB)
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

serve(async (req) => {
  const signature = req.headers.get('Stripe-Signature');
  const body = await req.text();
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

  let event;

  try {
    // 1. Verify the request is legitimately from Stripe
    event = stripe.webhooks.constructEvent(body, signature!, webhookSecret!);
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 });
  }

  // 2. Handle the Subscription Event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    
    // We pass the Supabase User ID through Stripe's 'client_reference_id' when checking out
    const userId = session.client_reference_id; 
    const stripeCustomerId = session.customer;

    if (userId) {
      // 3. Upgrade the User in the Database
      const { error } = await supabaseAdmin
        .from('profiles')
        .update({ 
          is_pro: true, 
          stripe_customer_id: stripeCustomerId 
        })
        .eq('id', userId);

      if (error) console.error("DB Update Error:", error);
    }
  }

  // Handle cancellations
  if (event.type === 'customer.subscription.deleted') {
     const subscription = event.data.object;
     await supabaseAdmin
        .from('profiles')
        .update({ is_pro: false })
        .eq('stripe_customer_id', subscription.customer);
  }

  // Tell Stripe we received the event successfully
  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
