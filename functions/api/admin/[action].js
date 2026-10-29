// POST /api/admin/invite | /api/admin/status | /api/admin/resend
//
// Opérations qui exigent la clé de service Supabase. Elle vit dans les
// variables d'environnement Cloudflare et n'est jamais envoyée au navigateur.
//
// Écrit sans dépendance : le site est un simple fichier HTML, sans étape de
// construction. Tout passe par l'API REST de Supabase via fetch.

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const clean = v => (typeof v === "string" ? v.trim() : "");
const BAN_FOREVER = "876000h";           // ~100 ans : bloque un compte désactivé
const ROLES = ["collaborateur", "officer", "proprietaire", "admin"];

/* Appel REST authentifié avec la clé de service. */
function svc(env, path, init = {}) {
  return fetch(env.SUPABASE_URL + path, {
    ...init,
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: "Bearer " + env.SUPABASE_SERVICE_ROLE_KEY,
      "Content-Type": "application/json",
      ...(init.headers || {})
    }
  });
}

/* Identifie l'appelant à partir de son jeton de session, puis lit son profil.
   Renvoie le profil, ou une réponse d'erreur. */
async function caller(env, request) {
  const token = (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Non authentifié" }, 401);

  const r = await fetch(env.SUPABASE_URL + "/auth/v1/user", {
    headers: { apikey: env.SUPABASE_SERVICE_ROLE_KEY, Authorization: "Bearer " + token }
  });
  if (!r.ok) return json({ error: "Session invalide" }, 401);
  const user = await r.json();

  const p = await svc(env, "/rest/v1/pds_profiles?select=id,role,hotel_id,status&id=eq." + user.id);
  const rows = p.ok ? await p.json() : [];
  const profile = rows[0];
  if (!profile || profile.status === "desactive") return json({ error: "Compte inactif" }, 403);
  if (profile.role !== "admin" && profile.role !== "officer") {
    return json({ error: "Action réservée à l’administrateur" }, 403);
  }
  return profile;
}

export const onRequestPost = async ({ request, env, params }) => {
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    return json({ error: "Serveur non configuré" }, 500);
  }

  const me = await caller(env, request);
  if (me instanceof Response) return me;
  const isAdmin = me.role === "admin";

  const body = await request.json().catch(() => ({}));
  const origin = env.SITE_URL || new URL(request.url).origin;
  const redirectTo = encodeURIComponent(origin + "/#/mot-de-passe");

  switch (params.action) {
    /* ---------------------------------------------------------- invite ---- */
    case "invite": {
      const email = clean(body.email).toLowerCase();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return json({ error: "Adresse e-mail invalide." }, 400);

      let role = ROLES.includes(body.role) ? body.role : "collaborateur";
      let hotel_id = clean(body.hotel_id) || null;

      // L'Officer / buddy ne peut inviter qu'un collaborateur, sur son hôtel.
      if (!isAdmin) {
        role = "collaborateur";
        hotel_id = me.hotel_id;
      }
      if (role !== "admin" && !hotel_id) return json({ error: "Rattachez ce compte à un hôtel." }, 400);

      const inv = await svc(env, "/auth/v1/invite?redirect_to=" + redirectTo, {
        method: "POST",
        body: JSON.stringify({ email })
      });
      const invBody = await inv.json().catch(() => ({}));
      if (!inv.ok) {
        const msg = invBody.msg || invBody.error_description || invBody.message || "Invitation refusée.";
        const exists = /already|registered|exists/i.test(msg);
        return json(
          { error: exists ? "Un compte existe déjà avec cette adresse." : msg },
          exists ? 409 : 400
        );
      }

      const up = await svc(env, "/rest/v1/pds_profiles", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates,return=representation" },
        body: JSON.stringify({
          id: invBody.id,
          email,
          nom: clean(body.nom),
          role,
          hotel_id,
          status: "invite"
        })
      });
      if (!up.ok) return json({ error: await up.text() }, 500);
      return json({ ok: true, id: invBody.id, email, role, hotel_id });
    }

    /* ---------------------------------------------------------- status ---- */
    case "status": {
      if (!isAdmin) return json({ error: "Action réservée à l’administrateur" }, 403);
      const id = clean(body.user_id);
      const target = body.status === "desactive" ? "desactive" : "actif";
      if (id === me.id && target === "desactive") {
        return json({ error: "Impossible de désactiver son propre compte." }, 400);
      }

      const p = await svc(env, "/rest/v1/pds_profiles?select=activated_at&id=eq." + id);
      const rows = p.ok ? await p.json() : [];
      if (!rows[0]) return json({ error: "Compte introuvable." }, 404);

      const ban = await svc(env, "/auth/v1/admin/users/" + id, {
        method: "PUT",
        body: JSON.stringify({ ban_duration: target === "desactive" ? BAN_FOREVER : "none" })
      });
      if (!ban.ok) return json({ error: await ban.text() }, 400);

      const status = target === "desactive" ? "desactive" : rows[0].activated_at ? "actif" : "invite";
      const upd = await svc(env, "/rest/v1/pds_profiles?id=eq." + id, {
        method: "PATCH",
        body: JSON.stringify({ status })
      });
      if (!upd.ok) return json({ error: await upd.text() }, 500);
      return json({ ok: true, status });
    }

    /* ---------------------------------------------------------- resend ---- */
    case "resend": {
      if (!isAdmin) return json({ error: "Action réservée à l’administrateur" }, 403);
      const id = clean(body.user_id);
      const p = await svc(env, "/rest/v1/pds_profiles?select=email,status&id=eq." + id);
      const rows = p.ok ? await p.json() : [];
      if (!rows[0]) return json({ error: "Compte introuvable." }, 404);
      if (rows[0].status !== "invite") return json({ error: "Ce compte est déjà activé." }, 400);

      const inv = await svc(env, "/auth/v1/invite?redirect_to=" + redirectTo, {
        method: "POST",
        body: JSON.stringify({ email: rows[0].email })
      });
      if (!inv.ok) {
        // Invitation déjà consommée : on envoie un lien de choix de mot de passe.
        const rec = await svc(env, "/auth/v1/recover?redirect_to=" + redirectTo, {
          method: "POST",
          body: JSON.stringify({ email: rows[0].email })
        });
        if (!rec.ok) return json({ error: await rec.text() }, 400);
      }
      return json({ ok: true });
    }

    default:
      return json({ error: "Action inconnue" }, 404);
  }
};
