import { createServerClient } from '@supabase/ssr';
import { createClient } from '@supabase/supabase-js';
import { cookies } from 'next/headers';

export async function POST(request: Request) {
  const headers = { 'Cache-Control': 'no-store' };
  const reply = (message: string, status: number) => Response.json({ message }, { status, headers });

  // Same-origin check
  if (request.headers.get('origin') !== new URL(request.url).origin) return reply('Request not allowed.', 403);

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !publishableKey || !serviceKey) return reply('Server configuration error.', 503);

  try {
    // Verify the requesting user is an approved admin
    const store = await cookies();
    const db = createServerClient(supabaseUrl, publishableKey, {
      cookies: {
        getAll: () => store.getAll(),
        setAll: items => items.forEach(({ name, value, options }) => store.set(name, value, options)),
      },
    });

    const { data: auth } = await db.auth.getUser();
    if (!auth.user) return reply('Please sign in again.', 401);

    const { data: profile } = await db.from('profiles').select('role,verification').eq('id', auth.user.id).single();
    if (profile?.role !== 'admin' || profile?.verification !== 'approved') return reply('Administrator access required.', 403);

    // Parse and validate request body
    if (Number(request.headers.get('content-length') ?? 0) > 2048) return reply('Request too large.', 413);
    const body = await request.json();
    const { email, full_name, department_id } = body as { email: string; full_name: string; department_id: string };

    if (!email || !full_name || !department_id) return reply('Email, full name, and department are required.', 400);
    if (typeof email !== 'string' || !email.toLowerCase().endsWith('@usindh.edu.pk')) return reply('A university email address (@usindh.edu.pk) is required.', 400);
    if (typeof full_name !== 'string' || full_name.trim().length < 2 || full_name.trim().length > 100) return reply('Full name must be 2–100 characters.', 400);
    if (typeof department_id !== 'string' || department_id.length < 10) return reply('A valid department is required.', 400);

    // Check the department exists
    const { data: dept } = await db.from('departments').select('id').eq('id', department_id).single();
    if (!dept) return reply('Department not found.', 400);

    // Use the service-role client to provision the teacher
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

    // Check if already exists
    const { data: existing } = await admin.from('profiles').select('id,role').eq('email', email.toLowerCase()).maybeSingle();
    if (existing) {
      if (existing.role === 'teacher') return reply('A teacher account with this email already exists.', 409);
      return reply('An account with this email already exists with a different role.', 409);
    }

    // Generate a random temporary password — teacher sets their own via recovery email
    const tempPassword = Array.from(crypto.getRandomValues(new Uint8Array(24))).map(b => b.toString(16).padStart(2, '0')).join('');

    const { data: created, error } = await admin.auth.admin.createUser({
      email: email.toLowerCase(),
      password: tempPassword,
      email_confirm: true,
      app_metadata: { portal_role: 'teacher' },
      user_metadata: { full_name: full_name.trim(), department_id },
    });

    if (error) return reply(`Could not create account: ${error.message}`, 500);

    // Ensure profile is approved (trigger should handle this, but upsert as fallback)
    await admin.from('profiles').upsert({
      id: created.user.id,
      email: email.toLowerCase(),
      full_name: full_name.trim(),
      role: 'teacher',
      department_id,
      verification: 'approved',
    }, { onConflict: 'id' });

    return reply(`Teacher account created for ${full_name.trim()}. Send a password-recovery email so they can set their own password.`, 201);
  } catch {
    return reply('Unable to provision teacher. Please try again.', 500);
  }
}
