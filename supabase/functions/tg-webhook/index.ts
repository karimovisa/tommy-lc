// ============================================================
// TOMMY LC — Telegram webhook
// Ota-ona/o'quvchi botni "Start" qilganda chat_id ni saqlaydi.
// PUBLIC (Telegram chaqiradi) — JWT yo'q, secret_token bilan himoyalangan.
// Deploy: npx supabase functions deploy tg-webhook --no-verify-jwt
// Secrets kerak: TELEGRAM_BOT_TOKEN, (ixtiyoriy) TELEGRAM_WEBHOOK_SECRET
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const URL = Deno.env.get('SUPABASE_URL')!
const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')!
const SECRET = Deno.env.get('TELEGRAM_WEBHOOK_SECRET') || ''

async function tg(method: string, payload: unknown) {
  try {
    await fetch(`https://api.telegram.org/bot${TOKEN}/${method}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
  } catch (_e) { /* ignore */ }
}

Deno.serve(async (req) => {
  // Telegram secret tekshirish (faqat Telegram POST qila olsin)
  if (SECRET && req.headers.get('x-telegram-bot-api-secret-token') !== SECRET) {
    return new Response('forbidden', { status: 403 })
  }
  try {
    const u = await req.json()
    const msg = u.message || u.edited_message
    if (!msg || !msg.text) return new Response('ok')
    const chatId = msg.chat.id
    const text = String(msg.text).trim()

    if (text.startsWith('/start')) {
      const param = text.split(/\s+/)[1] || ''   // saytdan kelgan: foydalanuvchi auth uid
      if (param) {
        const admin = createClient(URL, SERVICE)
        const { error } = await admin.from('profiles')
          .update({ telegram_chat_id: String(chatId) })
          .eq('id', param)
        if (!error) {
          await tg('sendMessage', {
            chat_id: chatId,
            text: '✅ Telegram ulandi!\nEndi muhim bildirishnomalar (darsga kelmaslik, test natijasi, uy ishi va h.k.) shu yerga keladi.',
          })
          // Ulangan zahoti — bugungi holat (agar farzand bugun kelmagan bo'lsa, darrov bildiramiz)
          try {
            const uzDate = new Date(Date.now() + 5 * 3600 * 1000).toISOString().slice(0, 10) // O'zbekiston (UTC+5)
            const { data: links } = await admin.from('parent_links').select('student_id').eq('parent_uid', param)
            const sids = (links || []).map((l: { student_id: string }) => l.student_id)
            if (sids.length) {
              const { data: checks } = await admin.from('daily_checks').select('student_id,absent').eq('date', uzDate).in('student_id', sids)
              const absentSids = (checks || []).filter((c: { absent: boolean }) => c.absent).map((c: { student_id: string }) => c.student_id)
              if (absentSids.length) {
                const { data: studs } = await admin.from('students').select('name').in('id', absentSids)
                const names = (studs || []).map((s: { name: string }) => s.name).join(', ')
                await tg('sendMessage', { chat_id: chatId, text: `⚠️ Bugun farzandingiz ${names} darsga kelmadi.` })
              }
            }
          } catch (_e) { /* ignore */ }
        } else {
          await tg('sendMessage', { chat_id: chatId, text: '❌ Ulashda xato. Saytdagi havoladan qaytadan urinib ko\'ring.' })
        }
      } else {
        await tg('sendMessage', {
          chat_id: chatId,
          text: 'Salom! Bu — TOMMY LC bildirishnoma boti. Ulanish uchun saytdagi "Telegramga ulanish" tugmasini bosing.',
        })
      }
    }
    return new Response('ok')
  } catch (_e) {
    return new Response('ok')
  }
})
