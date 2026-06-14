// ============================================================
// TOMMY LC — Edge Function: admin-student
// Akkount YARATISH va parol TIKLASH (service_role server tomonda).
// ============================================================
// DEPLOY (terminal SHART EMAS, dashboard'dan):
//   1) Supabase > Edge Functions > "Create a function" > nomi: admin-student
//   2) Shu fayl ichidagi kodni to'liq joylashtiring > Deploy
//   3) Secrets (Edge Functions > Manage secrets) — odatda avtomatik:
//        SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//      (agar yo'q bo'lsa qo'shing — service_role'ni Settings > API dan oling)
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const URL = Deno.env.get('SUPABASE_URL')!
const ANON = Deno.env.get('SUPABASE_ANON_KEY')!
const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const DOMAIN = 'students.tommy.uz'   // yashirin email domeni

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

// 2 harf + 4 raqam: masalan Tk4829
function tempPassword() {
  const U = 'ABCDEFGHJKLMNPQRSTUVWXYZ', l = 'abcdefghijkmnpqrstuvwxyz', D = '0123456789'
  const r = (s: string) => s[Math.floor(Math.random() * s.length)]
  return r(U) + r(l) + r(D) + r(D) + r(D) + r(D)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const body = await req.json()
    // Token body ichida (preflight'siz, CORS-safe so'rov uchun)
    const authToken = body._token || (req.headers.get('Authorization') || '').replace('Bearer ', '')
    // Chaqiruvchi haqiqatan adminmi? (uning JWT si bilan tekshiramiz)
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: 'Bearer ' + authToken } } })
    const { data: isAdmin } = await caller.rpc('is_admin')
    if (isAdmin !== true) return json({ error: 'Faqat admin bajara oladi' }, 403)

    const admin = createClient(URL, SERVICE)

    // ---------- AKKOUNT YARATISH ----------
    if (body.action === 'create') {
      const { full_name, phone, group_name, course_name, start_date } = body
      if (!full_name || !group_name) return json({ error: 'Ism va guruh shart' }, 400)

      // Guruh (yo'q bo'lsa yaratamiz)
      let { data: grp } = await admin.from('groups').select('id').eq('name', group_name).maybeSingle()
      if (!grp) { const r = await admin.from('groups').insert({ name: group_name }).select('id').single(); grp = r.data }

      const { data: sid } = await admin.rpc('next_student_id')
      const studentId = sid as string
      const temp = tempPassword()
      const email = studentId.toLowerCase() + '@' + DOMAIN

      const { data: created, error: ce } = await admin.auth.admin.createUser({
        email, password: temp, email_confirm: true,
        user_metadata: { full_name, role: 'student' },
      })
      if (ce) return json({ error: ce.message }, 400)
      const uid = created.user!.id

      const { data: st, error: se } = await admin.from('students').insert({
        name: full_name, phone: phone || '', group_id: grp!.id, group_name,
        course_name: course_name || '', start_date: start_date || null,
        student_id: studentId, status: 'ACTIVE', password_changed: false,
      }).select('id').single()
      if (se) return json({ error: se.message }, 400)

      const { error: pe } = await admin.from('profiles').insert({
        id: uid, full_name, role: 'student', group_id: grp!.id, student_id: st!.id, approved: true,
      })
      if (pe) {
        await admin.auth.admin.deleteUser(uid)
        return json({ error: 'Profil yaratilmadi: ' + pe.message }, 400)
      }
      return json({ ok: true, student_id: studentId, temp_password: temp, full_name })
    }

    // ---------- PAROL TIKLASH ----------
    if (body.action === 'reset') {
      const { student_pk } = body   // students.id
      const { data: prof } = await admin.from('profiles')
        .select('id').eq('student_id', student_pk).eq('role', 'student').limit(1).maybeSingle()
      if (!prof) return json({ error: 'Akkount topilmadi' }, 404)
      const temp = tempPassword()
      const { error } = await admin.auth.admin.updateUserById(prof.id, { password: temp })
      if (error) return json({ error: error.message }, 400)
      await admin.from('students').update({ password_changed: false }).eq('id', student_pk)
      return json({ ok: true, temp_password: temp })
    }

    // ---------- OTA-ONA AKKOUNTI YARATISH ----------
    if (body.action === 'create_parent') {
      const { student_pk } = body   // students.id
      const { data: st } = await admin.from('students')
        .select('id,name,student_id,group_id').eq('id', student_pk).maybeSingle()
      if (!st) return json({ error: "O'quvchi topilmadi" }, 404)
      // mavjud ota-ona bormi?
      const { data: existing } = await admin.from('parent_links')
        .select('parent_uid').eq('student_id', student_pk).limit(1).maybeSingle()
      if (existing) {
        const { data: pp } = await admin.from('profiles')
          .select('parent_login_id').eq('id', existing.parent_uid).maybeSingle()
        return json({ error: "Bu o'quvchining ota-onasi allaqachon bor", parent_id: pp?.parent_login_id || '' }, 400)
      }
      const parentId = (st.student_id || '') + 'P'
      const email = parentId.toLowerCase() + '@' + DOMAIN
      const temp = tempPassword()
      const { data: created, error: ce } = await admin.auth.admin.createUser({
        email, password: temp, email_confirm: true,
        user_metadata: { full_name: st.name + ' ota-onasi', role: 'parent' },
      })
      if (ce) return json({ error: ce.message }, 400)
      const uid = created.user!.id
      const { error: pe } = await admin.from('profiles').insert({
        id: uid, full_name: st.name + ' ota-onasi', role: 'parent',
        group_id: st.group_id, student_id: st.id, parent_login_id: parentId,
        child_name: st.name, approved: true,
      })
      if (pe) {
        // Profil yaratilmadi -> orfan auth-userni tozalab, ANIQ xato qaytaramiz (jimgina yiqilmasin)
        await admin.auth.admin.deleteUser(uid)
        return json({ error: 'Profil yaratilmadi: ' + pe.message }, 400)
      }
      const { error: le } = await admin.from('parent_links').insert({ parent_uid: uid, student_id: st.id })
      if (le) return json({ error: "Bog'lash xatosi: " + le.message }, 400)
      return json({ ok: true, parent_id: parentId, temp_password: temp, child_name: st.name })
    }

    // ---------- OTA-ONAGA YANA FARZAND BOG'LASH ----------
    if (body.action === 'link_parent') {
      const { student_pk, parent_id } = body
      if (!parent_id) return json({ error: 'Parent ID kiriting' }, 400)
      const { data: pp } = await admin.from('profiles')
        .select('id').eq('parent_login_id', parent_id).eq('role', 'parent').maybeSingle()
      if (!pp) return json({ error: 'Bunday Parent ID topilmadi' }, 404)
      const { data: ex } = await admin.from('parent_links')
        .select('student_id').eq('parent_uid', pp.id).eq('student_id', student_pk).maybeSingle()
      if (ex) return json({ error: 'Bu farzand allaqachon bog\'langan' }, 400)
      await admin.from('parent_links').insert({ parent_uid: pp.id, student_id: student_pk })
      return json({ ok: true, parent_id })
    }

    // ---------- OTA-ONA PAROLINI TIKLASH ----------
    if (body.action === 'reset_parent') {
      const { parent_id } = body
      const { data: pp } = await admin.from('profiles')
        .select('id').eq('parent_login_id', parent_id).eq('role', 'parent').maybeSingle()
      if (!pp) return json({ error: 'Ota-ona topilmadi' }, 404)
      const temp = tempPassword()
      const { error } = await admin.auth.admin.updateUserById(pp.id, { password: temp })
      if (error) return json({ error: error.message }, 400)
      return json({ ok: true, temp_password: temp })
    }

    return json({ error: 'Noma\'lum amal' }, 400)
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500)
  }
})
