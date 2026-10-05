'use strict';

// Faux ITSM : simule le contrat d'un ITSM (changements, incidents) pour câbler et
// tester le pipeline avant de disposer d'un vrai outil. Aucune dépendance.

const http = require('node:http');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const TYPES = ['standard', 'normal', 'incident'];
const DROITS = ['read', 'create', 'approve', 'link', 'close'];
const UI_DIR = path.join(__dirname, 'ui');
const UI_FILES = {
  '/': ['index.html', 'text/html; charset=utf-8'],
  '/ui.css': ['ui.css', 'text/css; charset=utf-8'],
  '/ui.js': ['ui.js', 'text/javascript; charset=utf-8'],
};
const MAX_BODY = 64 * 1024;
const ID_RE = /^(CHG|INC)-\d{4}-\d{4}$/;
const EMPREINTE_RE = /^[A-Za-z0-9:._-]{7,200}$/;

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const sha = (s) => crypto.createHash('sha256').update(String(s)).digest();

// Format : jeton:identité:droit,droit;jeton:identité:droit,...
function parseTokens(raw) {
  const out = [];
  for (const part of String(raw || '').split(';').map((s) => s.trim()).filter(Boolean)) {
    const [token, identite, droits] = part.split(':');
    if (!token || !identite || !droits) {
      throw new Error('entrée de jeton invalide (attendu jeton:identité:droits)');
    }
    const liste = droits.split(',').map((d) => d.trim()).filter(Boolean);
    for (const d of liste) {
      if (!DROITS.includes(d)) throw new Error(`droit inconnu : ${d}`);
    }
    out.push({ digest: sha(token), identite, droits: new Set(liste) });
  }
  if (out.length === 0) throw new Error('aucun jeton configuré (ITSM_TOKENS)');
  return out;
}

function authenticate(tokens, header) {
  const m = /^Bearer (\S+)$/.exec(header || '');
  if (!m) return null;
  const digest = sha(m[1]);
  let found = null;
  for (const t of tokens) {
    if (crypto.timingSafeEqual(digest, t.digest)) found = t;
  }
  return found;
}

class Store {
  constructor(dir) {
    fs.mkdirSync(dir, { recursive: true });
    this.file = path.join(dir, 'changes.json');
    this.items = new Map();
    if (fs.existsSync(this.file)) {
      for (const it of JSON.parse(fs.readFileSync(this.file, 'utf8'))) this.items.set(it.id, it);
    }
  }

  save() {
    const tmp = `${this.file}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify([...this.items.values()], null, 2));
    fs.renameSync(tmp, this.file);
  }

  nextId(prefix) {
    const year = new Date().getUTCFullYear();
    const head = `${prefix}-${year}-`;
    let max = 0;
    for (const id of this.items.keys()) {
      if (id.startsWith(head)) max = Math.max(max, Number(id.slice(head.length)));
    }
    return `${head}${String(max + 1).padStart(4, '0')}`;
  }
}

function send(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(data),
  });
  res.end(data);
}

function sendUi(res, [fichier, type]) {
  const data = fs.readFileSync(path.join(UI_DIR, fichier));
  res.writeHead(200, {
    'Content-Type': type,
    'Content-Length': data.length,
    'Cache-Control': 'no-store',
    'Content-Security-Policy':
      "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(data);
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => {
      size += c.length;
      if (size > MAX_BODY) {
        reject(new HttpError(413, 'corps trop volumineux'));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => {
      if (size === 0) return resolve({});
      try {
        const v = JSON.parse(Buffer.concat(chunks).toString('utf8'));
        if (v === null || typeof v !== 'object' || Array.isArray(v)) throw new Error();
        resolve(v);
      } catch {
        reject(new HttpError(400, 'JSON invalide (objet attendu)'));
      }
    });
    req.on('error', reject);
  });
}

function text(value, nom, { requis = false, max = 200 } = {}) {
  if (value === undefined || value === null || value === '') {
    if (requis) throw new HttpError(400, `${nom} obligatoire`);
    return '';
  }
  if (typeof value !== 'string') throw new HttpError(400, `${nom} doit être une chaîne`);
  if (value.length > max) throw new HttpError(400, `${nom} trop long (max ${max})`);
  return value;
}

function event(item, acteur, action, details = {}) {
  item.historique.push({ date: new Date().toISOString(), acteur, action, ...details });
  item.mis_a_jour = item.historique[item.historique.length - 1].date;
}

function need(who, droit) {
  if (!who.droits.has(droit)) throw new HttpError(403, `droit « ${droit} » requis`);
}

function getItem(store, id) {
  if (!ID_RE.test(id) || !store.items.has(id)) throw new HttpError(404, 'demande introuvable');
  return store.items.get(id);
}

function createServer({ tokens, dataDir, log = () => {} }) {
  const store = new Store(dataDir);

  async function route(req, res, who) {
    const url = new URL(req.url, 'http://itsm');
    const parts = url.pathname.split('/').filter(Boolean);

    if (parts[0] !== 'changes') throw new HttpError(404, 'route inconnue');

    if (parts.length === 1) {
      if (req.method === 'GET') {
        need(who, 'read');
        const etat = url.searchParams.get('etat');
        const type = url.searchParams.get('type');
        const liste = [...store.items.values()].filter(
          (i) => (!etat || i.etat === etat) && (!type || i.type === type)
        );
        return send(res, 200, liste);
      }
      if (req.method === 'POST') {
        need(who, 'create');
        const body = await readJson(req);
        const type = text(body.type, 'type', { requis: true });
        if (!TYPES.includes(type)) throw new HttpError(400, `type invalide (${TYPES.join(', ')})`);
        const now = new Date().toISOString();
        const item = {
          id: store.nextId(type === 'incident' ? 'INC' : 'CHG'),
          type,
          titre: text(body.titre, 'titre', { requis: true }),
          description: text(body.description, 'description', { max: 2000 }),
          environnement: text(body.environnement, 'environnement', { max: 50 }),
          demandeur: who.identite,
          etat: type === 'normal' ? 'brouillon' : type === 'standard' ? 'approuve' : 'ouvert',
          cree: now,
          mis_a_jour: now,
          approbateur: null,
          deploiements: [],
          resultat: null,
          historique: [],
        };
        event(item, who.identite, 'creation', { etat: item.etat });
        if (type === 'standard') {
          item.approbateur = 'pre-approuve';
          event(item, 'systeme', 'approbation', { motif: 'changement standard pré-approuvé' });
        }
        store.items.set(item.id, item);
        store.save();
        return send(res, 201, item);
      }
      throw new HttpError(405, 'méthode non autorisée');
    }

    const item = getItem(store, parts[1]);

    if (parts.length === 2) {
      if (req.method !== 'GET') throw new HttpError(405, 'méthode non autorisée');
      need(who, 'read');
      return send(res, 200, item);
    }

    if (parts.length !== 3 || req.method !== 'POST') throw new HttpError(404, 'route inconnue');
    const action = parts[2];
    const body = await readJson(req);

    if (action === 'approve' || action === 'reject') {
      need(who, 'approve');
      if (item.type !== 'normal') throw new HttpError(409, 'seul un changement normal s\'approuve');
      if (item.etat !== 'brouillon') throw new HttpError(409, `état « ${item.etat} » : décision impossible`);
      if (action === 'approve' && who.identite === item.demandeur) {
        throw new HttpError(403, 'le demandeur ne peut pas approuver sa propre demande');
      }
      const motif = text(body.motif, 'motif', { requis: action === 'reject', max: 500 });
      item.etat = action === 'approve' ? 'approuve' : 'refuse';
      item.approbateur = who.identite;
      event(item, who.identite, action === 'approve' ? 'approbation' : 'refus', { motif });
    } else if (action === 'link') {
      need(who, 'link');
      if (item.type === 'incident') throw new HttpError(409, 'un incident ne porte pas de déploiement');
      if (item.etat !== 'approuve' && item.etat !== 'en_cours') {
        throw new HttpError(409, `état « ${item.etat} » : déploiement non autorisé`);
      }
      const empreinte = text(body.empreinte, 'empreinte', { requis: true });
      if (!EMPREINTE_RE.test(empreinte)) throw new HttpError(400, 'empreinte invalide');
      const dep = {
        empreinte,
        run_url: text(body.run_url, 'run_url', { max: 500 }),
        environnement: text(body.environnement, 'environnement', { max: 50 }) || item.environnement,
        ci: text(body.ci, 'ci', { max: 500 }),
        date: new Date().toISOString(),
      };
      item.deploiements.push(dep);
      item.etat = 'en_cours';
      event(item, who.identite, 'deploiement', { empreinte, environnement: dep.environnement });
    } else if (action === 'close') {
      need(who, 'close');
      if (item.etat !== 'en_cours' && item.etat !== 'ouvert') {
        throw new HttpError(409, `état « ${item.etat} » : clôture impossible`);
      }
      const resultat = text(body.resultat, 'resultat', { requis: true });
      if (!['succes', 'echec'].includes(resultat)) throw new HttpError(400, 'resultat : succes ou echec');
      item.etat = 'clos';
      item.resultat = resultat;
      event(item, who.identite, 'cloture', { resultat });
    } else {
      throw new HttpError(404, 'action inconnue');
    }

    store.save();
    return send(res, 200, item);
  }

  return http.createServer(async (req, res) => {
    let status = 500;
    let acteur = '-';
    const reply = res.writeHead.bind(res);
    res.writeHead = (s, ...a) => {
      status = s;
      return reply(s, ...a);
    };
    try {
      const path = new URL(req.url, 'http://itsm').pathname;
      if (req.method === 'GET' && path === '/health') return send(res, 200, { statut: 'ok' });
      if (req.method === 'GET' && Object.hasOwn(UI_FILES, path)) return sendUi(res, UI_FILES[path]);
      const who = authenticate(tokens, req.headers.authorization);
      if (!who) throw new HttpError(401, 'jeton absent ou invalide');
      acteur = who.identite;
      await route(req, res, who);
    } catch (e) {
      if (e instanceof HttpError) send(res, e.status, { erreur: e.message });
      else {
        log(`erreur interne : ${e.message}`);
        send(res, 500, { erreur: 'erreur interne' });
      }
    } finally {
      log(`${req.method} ${req.url.split('?')[0]} ${status} ${acteur}`);
    }
  });
}

if (require.main === module) {
  let tokens;
  try {
    tokens = parseTokens(process.env.ITSM_TOKENS);
  } catch (e) {
    console.error(`Démarrage impossible : ${e.message}`);
    process.exit(1);
  }
  const host = process.env.ITSM_HOST || '127.0.0.1';
  const port = Number(process.env.ITSM_PORT || 8095);
  const dataDir = process.env.ITSM_DATA_DIR || path.join(__dirname, 'data');
  createServer({ tokens, dataDir, log: (l) => console.log(`${new Date().toISOString()} ${l}`) }).listen(
    port,
    host,
    () => console.log(`Faux ITSM à l'écoute sur http://${host}:${port} (données : ${dataDir})`)
  );
}

module.exports = { createServer, parseTokens };
