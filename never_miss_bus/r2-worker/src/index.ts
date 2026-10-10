import { importJWK, jwtVerify, SignJWT } from 'jose';

interface Env {
  DOCUMENTS: R2Bucket;
  FIREBASE_PROJECT_ID: string;
  ADMIN_UIDS: string;
  PUBLIC_WORKER_URL: string;
  CAPABILITY_SECRET: string;
}

interface Claims {
  user_id?: string;
  email?: string;
  [key: string]: unknown;
}

type FirebaseJwk = JsonWebKey & { kid?: string; alg?: string };

const firebaseJwks = fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
  .then((response) => response.json<{ keys: FirebaseJwk[] }>());

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });
}

function cors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set('access-control-allow-origin', '*');
  headers.set('access-control-allow-headers', 'authorization, content-type');
  headers.set('access-control-allow-methods', 'GET, POST, OPTIONS');
  return new Response(response.body, { status: response.status, headers });
}

async function verifyFirebaseToken(request: Request, env: Env): Promise<Claims> {
  const header = request.headers.get('authorization') ?? '';
  if (!header.startsWith('Bearer ')) throw new Error('missing-auth');
  const token = header.substring(7);
  const { keys } = await firebaseJwks;
  const result = await jwtVerify<Claims>(token, async (protectedHeader) => {
    const jwk = keys.find((key) => key.kid === protectedHeader.kid);
    if (!jwk) throw new Error('unknown-key');
    return importJWK(jwk, protectedHeader.alg ?? 'RS256');
  }, {
    issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
    audience: env.FIREBASE_PROJECT_ID,
  });
  return result.payload;
}

function uidFromClaims(claims: Claims): string {
  return String(claims.user_id ?? claims.sub ?? '');
}

function isAdmin(uid: string, env: Env): boolean {
  return env.ADMIN_UIDS.split(',').map((value) => value.trim()).includes(uid);
}

function safeSegment(value: string): string {
  return value.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 120);
}

async function capabilityUrl(env: Env, objectKey: string, studentUid: string): Promise<string> {
  const token = await new SignJWT({ objectKey, studentUid })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(new TextEncoder().encode(env.CAPABILITY_SECRET));
  return `${env.PUBLIC_WORKER_URL}/documents/download?token=${encodeURIComponent(token)}`;
}

async function handle(request: Request, env: Env): Promise<Response> {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204 });
  const url = new URL(request.url);

  if (url.pathname === '/health') return json({ ok: true, bucket: 'srbs-school-documents' });

  let claims: Claims;
  try {
    claims = await verifyFirebaseToken(request, env);
  } catch (_) {
    return json({ error: 'unauthorized' }, 401);
  }
  const uid = uidFromClaims(claims);
  const admin = isAdmin(uid, env);

  if (url.pathname === '/documents/upload' && request.method === 'POST') {
    if (!admin) return json({ error: 'admin-only' }, 403);
    const form = await request.formData();
    const file = form.get('file');
    const studentUid = String(form.get('studentUid') ?? '');
    const label = String(form.get('label') ?? '').trim();
    const contentType = String(form.get('contentType') ?? 'application/octet-stream');
    if (!(file instanceof File) || !studentUid || !label) return json({ error: 'invalid-upload' }, 400);
    if (file.size > 20 * 1024 * 1024) return json({ error: 'file-too-large' }, 413);
    if (!['application/pdf', 'image/jpeg', 'image/png', 'image/webp'].includes(contentType)) return json({ error: 'unsupported-type' }, 415);
    const objectKey = `studentDocuments/${safeSegment(studentUid)}/${Date.now()}_${safeSegment(file.name || 'document')}`;
    await env.DOCUMENTS.put(objectKey, file.stream(), {
      httpMetadata: { contentType, contentDisposition: `inline; filename="${safeSegment(file.name || 'document')}"` },
      customMetadata: { studentUid, label, uploadedBy: uid },
    });
    return json({ objectKey, fileName: file.name, sizeBytes: file.size, contentType });
  }

  if (url.pathname === '/documents/view-url' && request.method === 'POST') {
    const body = await request.json<{ objectKey?: string; studentUid?: string }>();
    if (!body.objectKey || !body.studentUid) return json({ error: 'invalid-request' }, 400);
    if (!admin && body.studentUid !== uid) return json({ error: 'forbidden' }, 403);
    const object = await env.DOCUMENTS.head(body.objectKey);
    if (!object) return json({ error: 'not-found' }, 404);
    return json({ url: await capabilityUrl(env, body.objectKey, body.studentUid), expiresInSeconds: 900 });
  }

  if (url.pathname === '/documents/download' && request.method === 'GET') {
    try {
      const { payload } = await jwtVerify<{ objectKey: string; studentUid: string }>(url.searchParams.get('token') ?? '', new TextEncoder().encode(env.CAPABILITY_SECRET));
      const object = await env.DOCUMENTS.get(payload.objectKey);
      if (!object) return new Response('Not found', { status: 404 });
      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('cache-control', 'private, max-age=900');
      return new Response(object.body, { headers });
    } catch (_) {
      return new Response('Invalid or expired link', { status: 401 });
    }
  }

  return json({ error: 'not-found' }, 404);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return cors(await handle(request, env));
    } catch (error) {
      console.error(error);
      return cors(json({ error: 'internal-error' }, 500));
    }
  },
};
