import { supabase } from './supabase';
// Supabase caps individual responses. Paging prevents silently truncated reports.
export async function readRecords<T>(table:string,columns='*'):Promise<T[]> {
 const rows:T[]=[];
 for(let offset=0;;offset+=500){
  let query=supabase().from(table).select(columns).order(table==='audit_logs'?'id':table==='attendance'?'session_id':table==='enrollments'?'course_id':'id');
  if(table==='attendance'||table==='enrollments')query=query.order('student_id');
  const {data,error}=await query.range(offset,offset+499);
  if(error)throw new Error('Records could not be loaded. Please refresh.');
  rows.push(...(data??[]) as unknown as T[]);
  if(!data||data.length<500)break;
 }
 return rows;
}
