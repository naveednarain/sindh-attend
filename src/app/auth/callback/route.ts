import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
export async function GET(request:Request) {
 const url=new URL(request.url);const code=url.searchParams.get('code');const next=url.searchParams.get('next')==='/reset-password'?'/reset-password':'/';
 if(code&&process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY){
 const store=await cookies();const db=createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,{cookies:{getAll:()=>store.getAll(),setAll:(items)=>items.forEach(({name,value,options})=>store.set(name,value,options))}});
 const {error}=await db.auth.exchangeCodeForSession(code);if(!error)return NextResponse.redirect(new URL(next,url.origin));
 }
 return NextResponse.redirect(new URL('/?auth=expired',url.origin));
}
