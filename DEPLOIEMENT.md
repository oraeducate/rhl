# Guide de Déploiement — GRH Ministère
## Supabase (base de données) + Vercel (hébergement)

---

## ÉTAPE 1 — Créer le projet Supabase

1. Allez sur [supabase.com](https://supabase.com) et connectez-vous
2. Cliquez **"New Project"**
3. Donnez un nom (ex: `grh-ministere`), choisissez un mot de passe fort, région **Europe (Frankfurt)** ou la plus proche
4. Attendez ~2 minutes que le projet démarre

---

## ÉTAPE 2 — Créer les tables (base de données)

1. Dans votre projet Supabase, allez dans **SQL Editor** (menu gauche)
2. Cliquez **"New Query"**
3. Copiez tout le contenu du fichier **`schema.sql`** et collez-le
4. Cliquez **"Run"** (▶️)
5. Vous devez voir : `Success. No rows returned`

---

## ÉTAPE 3 — Récupérer vos clés API Supabase

1. Dans Supabase, allez dans **Settings → API**
2. Copiez :
   - **Project URL** → ressemble à `https://xxxxxxxxxxxxxx.supabase.co`
   - **anon / public key** → longue chaîne commençant par `eyJ...`

---

## ÉTAPE 4 — Mettre vos clés dans le fichier HTML

Ouvrez `index.html` et repérez ces deux lignes au début du `<script>` :

```javascript
const SUPA_URL = 'VOTRE_SUPABASE_URL';
const SUPA_KEY = 'VOTRE_SUPABASE_ANON_KEY';
```

Remplacez par vos vraies valeurs :

```javascript
const SUPA_URL = 'https://xxxxxxxxxxxxxx.supabase.co';
const SUPA_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Sauvegardez le fichier.

---

## ÉTAPE 5 — Créer le premier utilisateur (Administrateur)

1. Dans Supabase, allez dans **Authentication → Users**
2. Cliquez **"Invite user"**
3. Entrez votre email et cliquez **Send invite**
4. Vous recevrez un email avec un lien — cliquez-le et définissez votre mot de passe

5. Maintenant, attribuez le rôle **admin** à ce premier compte :
   - Allez dans **SQL Editor** → **New Query**
   - Remplacez `votre@email.com` par votre email et exécutez :

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'votre@email.com';
```

---

## ÉTAPE 6 — Déployer sur Vercel

### Option A — Sans compte GitHub (le plus simple)

1. Installez Vercel CLI :
   ```
   npm install -g vercel
   ```
2. Dans le dossier contenant `index.html`, ouvrez un terminal et tapez :
   ```
   vercel
   ```
3. Suivez les instructions (créez un compte si besoin)
4. Vercel vous donne une URL publique du type `https://grh-ministere.vercel.app`

### Option B — Via GitHub (recommandé pour les mises à jour)

1. Créez un dépôt sur [github.com](https://github.com) et uploadez `index.html`
2. Allez sur [vercel.com](https://vercel.com) → **Add New Project**
3. Connectez votre dépôt GitHub
4. Cliquez **Deploy** — c'est tout !
5. Chaque modification du fichier sur GitHub se déploie automatiquement

---

## ÉTAPE 7 — Inviter d'autres utilisateurs

Une fois connecté en tant qu'**Admin** :

1. Allez dans **Paramètres → 👥 Utilisateurs**
2. Cliquez **"✉️ Inviter un utilisateur"** (vous renvoie sur Supabase Dashboard)
3. Ou directement dans Supabase : **Authentication → Users → Invite user**
4. L'utilisateur reçoit un email, clique le lien, définit son mot de passe
5. Revenez dans **Paramètres → Utilisateurs** pour assigner son rôle :
   - **Admin** : accès total + paramètres
   - **Gestionnaire** : saisie et modification de tout
   - **Chef de service** : lecture seule de sa direction (à définir dans la colonne Direction)

---

## SÉCURITÉ — Points importants

- ✅ La clé `anon` Supabase est **publique par conception** — elle ne donne accès qu'aux données autorisées par les politiques RLS
- ✅ Les politiques RLS (Row Level Security) sont déjà configurées dans `schema.sql`
- ✅ Les mots de passe sont gérés par Supabase (jamais stockés dans votre code)
- ⚠️ Ne partagez jamais votre clé **service_role** (elle est secrète)
- ⚠️ Activez la **vérification email** dans Supabase → Authentication → Settings si besoin

---

## PROBLÈMES FRÉQUENTS

| Problème | Solution |
|---|---|
| "Invalid API key" | Vérifiez SUPA_URL et SUPA_KEY dans index.html |
| Données non visibles pour un chef de service | Vérifiez que le champ "Direction" de son profil correspond exactement à la direction des agents |
| Erreur RLS | Vérifiez que le SQL schema a bien été exécuté entièrement |
| Email d'invitation non reçu | Vérifiez les spams ; ou désactivez la confirmation email dans Supabase → Auth → Settings |

---

## STRUCTURE DES FICHIERS À DÉPLOYER

```
/
├── index.html        ← L'application complète (un seul fichier)
└── schema.sql        ← Uniquement pour Supabase (ne pas déployer sur Vercel)
```

Seul `index.html` va sur Vercel. Le `schema.sql` ne sert qu'une fois dans Supabase.
