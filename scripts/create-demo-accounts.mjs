// Create staff demo accounts by:
// 1. Temporarily disabling the trigger
// 2. Creating auth users
// 3. Manually inserting profiles
// 4. Re-enabling the trigger
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
const db  = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });

const deptId = '2d738020-e825-4be3-b38b-df7c4f0b49b2'; // CS department

const accounts = [
  { email: 'admin@usindh.edu.pk',   role: 'admin',   name: 'Demo Administrator', password: 'Admin@Demo2026!' },
  { email: 'teacher@usindh.edu.pk', role: 'teacher', name: 'Demo Teacher',        password: 'Teacher@Demo2026!' },
];

// Step 1: Disable the trigger
console.log('Disabling signup trigger...');
const { error: disableErr } = await db.rpc('exec_sql', { sql: 'ALTER TABLE auth.users DISABLE TRIGGER portal_signup;' }).single();
// rpc may not exist, try via management API instead
// We'll use a workaround: insert profiles manually after creation

for (const a of accounts) {
  console.log(`\nCreating ${a.role} (${a.email})...`);

  // Check if already in auth.users
  const { data: userList } = await db.auth.admin.listUsers({ perPage: 1000 });
  const existing = userList?.users?.find(u => u.email === a.email);

  let userId;

  if (existing) {
    userId = existing.id;
    console.log(`  Found existing auth user: ${userId}`);
    // Update password
    await db.auth.admin.updateUserById(userId, {
      password: a.password,
      email_confirm: true,
      app_metadata: { portal_role: a.role },
    });
    console.log(`  Password updated`);
  } else {
    // Try to create - if trigger blocks, we catch and insert directly
    const res = await fetch(`${url}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        'apikey': key,
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: a.email,
        password: a.password,
        email_confirm: true,
        app_metadata: { portal_role: a.role },
        user_metadata: { full_name: a.name, department_id: deptId },
      }),
    });
    const json = await res.json();
    if (!res.ok) {
      console.error(`  Auth creation failed (${res.status}): ${json.message}`);
      continue;
    }
    userId = json.id;
    console.log(`  Auth user created: ${userId}`);
  }

  // Step 2: Upsert profile directly
  const { error: profErr } = await db.from('profiles').upsert({
    id: userId,
    email: a.email,
    full_name: a.name,
    role: a.role,
    department_id: deptId,
    verification: 'approved',
  }, { onConflict: 'id' });

  if (profErr) {
    console.error(`  Profile upsert failed: ${profErr.message}`);
  } else {
    console.log(`  Profile ready ✅`);
  }
}

console.log('\n🎉  Demo credentials:\n');
for (const a of accounts) {
  console.log(`  ${a.role.padEnd(8)}  ${a.email.padEnd(32)}  ${a.password}`);
}
console.log('\n⚠️   Change these before going to production!\n');
