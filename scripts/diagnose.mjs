// Create staff accounts via direct SQL using rpc/exec
// Uses the Supabase Management API to run raw SQL
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
const db  = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });

const deptId = '2d738020-e825-4be3-b38b-df7c4f0b49b2'; // CS department

// Try creating via direct auth admin API with different approach
// Use fetch directly against the admin endpoint
const projectRef = 'mfikbalqckbzqqsuexxf';

async function createUserViaFetch(email, password, role, name) {
  const res = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      'apikey': key,
      'Authorization': `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      app_metadata: { portal_role: role },
      user_metadata: { full_name: name, department_id: deptId },
    }),
  });
  const json = await res.json();
  return { ok: res.ok, status: res.status, data: json };
}

const accounts = [
  { email: 'admin@usindh.edu.pk',   role: 'admin',   name: 'Demo Administrator', password: 'Admin@Demo2026!' },
  { email: 'teacher@usindh.edu.pk', role: 'teacher', name: 'Demo Teacher',        password: 'Teacher@Demo2026!' },
];

for (const a of accounts) {
  console.log(`\nCreating ${a.role} (${a.email})...`);
  const result = await createUserViaFetch(a.email, a.password, a.role, a.name);
  console.log(`  Status: ${result.status}`);
  if (result.ok) {
    const userId = result.data.id;
    console.log(`  Created user: ${userId}`);
    // Manually insert profile in case trigger failed
    const { error } = await db.from('profiles').upsert({
      id: userId,
      email: a.email,
      full_name: a.name,
      role: a.role,
      department_id: deptId,
      verification: 'approved',
    }, { onConflict: 'id' });
    if (error) console.log(`  Profile upsert error: ${error.message}`);
    else console.log(`  Profile created/updated ✅`);
  } else {
    console.log(`  Error:`, JSON.stringify(result.data, null, 2));
    
    // If user exists, try to find and update
    if (result.data?.msg?.includes('already') || result.status === 422) {
      console.log('  Trying to find existing user...');
      const { data: users } = await db.auth.admin.listUsers();
      const existing = users?.users?.find(u => u.email === a.email);
      if (existing) {
        console.log(`  Found existing user: ${existing.id}`);
        await db.auth.admin.updateUserById(existing.id, { password: a.password, email_confirm: true, app_metadata: { portal_role: a.role } });
        await db.from('profiles').upsert({ id: existing.id, email: a.email, full_name: a.name, role: a.role, department_id: deptId, verification: 'approved' }, { onConflict: 'id' });
        console.log(`  Updated ✅`);
      }
    }
  }
}
