// ============================================================
// TOMMY LC — Telegram yuboruvchi
// O'qituvchi/admin chaqiradi: o'quvchining ota-onasiga Telegram xabari.
// Auth: faqat o'qituvchi yoki admin.
// Deploy: npx supabase functions deploy tg-send --no-verify-jwt
// Secrets kerak: TELEGRAM_BOT_TOKEN
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const URL = Deno.env.get('SUPABASE_URL')!
const ANON = Deno.env.get('SUPABASE_ANON_KEY')!
const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')!

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

async function tg(method: string, payload: unknown) {
  try {
    await fetch(`https://api.telegram.org/bot${TOKEN}/${method}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
    })
  } catch (_e) { /* ignore */ }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const body = await req.json()
    const authToken = body._token || (req.headers.get('Authorization') || '').replace('Bearer ', '')
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: 'Bearer ' + authToken } } })
    const { data: isAdmin } = await caller.rpc('is_admin')
    const { data: isTeacher } = await caller.rpc('is_teacher')
    if (isAdmin !== true && isTeacher !== true) return json({ error: 'Ruxsat yo\'q' }, 403)

    const admin = createClient(URL, SERVICE)
    const { student_pk, kind, text } = body
    if (!student_pk) return json({ error: 'student_pk kerak' }, 400)

    const { data: st } = await admin.from('students').select('id,name').eq('id', student_pk).maybeSingle()
    if (!st) return json({ error: 'O\'quvchi topilmadi' }, 404)

    // Ota-ona(lar) chat_id
    const { data: links } = await admin.from('parent_links').select('parent_uid').eq('student_id', student_pk)
    const uids = (links || []).map((l: { parent_uid: string }) => l.parent_uid)
    let chatIds: string[] = []
    if (uids.length) {
      const { data: profs } = await admin.from('profiles').select('telegram_chat_id').in('id', uids)
      chatIds = (profs || []).map((p: { telegram_chat_id: string | null }) => p.telegram_chat_id).filter(Boolean) as string[]
    }

    const message = text ||
      (kind === 'absent' ? `Assalomu alaykum! Bugun farzandingiz ${st.name} darsga kelmadi.` : '')
    if (!message) return json({ error: 'Xabar matni yo\'q' }, 400)

    let sent = 0
    for (const cid of chatIds) { await tg('sendMessage', { chat_id: cid, text: message }); sent++ }
    return json({ ok: true, sent, total_parents: uids.length })
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500)
  }
})
