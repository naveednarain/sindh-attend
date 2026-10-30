// Trusted one-time operation. Supply the service key securely in the environment.
// Never commit a service key or put it in NEXT_PUBLIC variables.
import { createClient } from '@supabase/supabase-js';
import { randomBytes } from 'node:crypto';
const url=process.env.SUPABASE_URL;
const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
if(!url||!key)throw new Error('Configure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY securely before provisioning.');
const db=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
const {data:department,error:departmentError}=await db.from('departments').select('id').eq('code','CS').single();
if(departmentError)throw new Error('Computer Science department is not configured.');
for(const staff of [{email:'admin@usindh.edu.pk',role:'admin',name:'Campus Administrator'},{email:'teacher@usindh.edu.pk',role:'teacher',name:'University Teacher'}]) {
 const {data:existing,error:lookupError}=await db.from('profiles').select('id,role').eq('email',staff.email).maybeSingle();
 if(lookupError)throw new Error('Could not check staff provisioning status.');
 if(existing){if(existing.role!==staff.role)throw new Error('Existing role does not match intended staff role. Review manually.');console.log(`${staff.role}: already provisioned`);continue;}
 const {error}=await db.auth.admin.createUser({email:staff.email,password:randomBytes(48).toString('base64url'),email_confirm:false,app_metadata:{portal_role:staff.role},user_metadata:{full_name:staff.name,department_id:department.id}});
 if(error)throw new Error(`Could not provision ${staff.role}: ${error.message}`);
 console.log(`${staff.role}: provisioned with an unknown random password. Use the university mailbox recovery flow to establish access.`);
}
