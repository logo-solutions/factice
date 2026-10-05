'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createServer, parseTokens } = require('../server');

const TOKENS = [
  'tp:pipeline:read,create,link,close',
  'ta:alice:read,approve',
  'ts:solo:read,create,approve,link,close',
].join(';');

async function demarrer(dataDir) {
  const dir = dataDir || fs.mkdtempSync(path.join(os.tmpdir(), 'itsm-'));
  const server = createServer({ tokens: parseTokens(TOKENS), dataDir: dir });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const api = async (methode, chemin, jeton, corps) => {
    const res = await fetch(base + chemin, {
      method: methode,
      headers: {
        ...(jeton ? { Authorization: `Bearer ${jeton}` } : {}),
        ...(corps ? { 'Content-Type': 'application/json' } : {}),
      },
      body: corps ? JSON.stringify(corps) : undefined,
    });
    return { status: res.status, body: await res.json() };
  };
  return { api, base, dir, arreter: () => new Promise((r) => server.close(r)) };
}

test('santé sans jeton, le reste exige un jeton valide', async () => {
  const s = await demarrer();
  assert.equal((await s.api('GET', '/health')).status, 200);
  assert.equal((await s.api('GET', '/changes')).status, 401);
  assert.equal((await s.api('GET', '/changes', 'mauvais')).status, 401);
  await s.arreter();
});

test('changement standard : pré-approuvé dès la création', async () => {
  const s = await demarrer();
  const r = await s.api('POST', '/changes', 'tp', { type: 'standard', titre: 'Mise à jour factice' });
  assert.equal(r.status, 201);
  assert.match(r.body.id, /^CHG-\d{4}-0001$/);
  assert.equal(r.body.etat, 'approuve');
  assert.equal(r.body.demandeur, 'pipeline');
  await s.arreter();
});

test('changement normal : approbation par un autre, déploiement, clôture', async () => {
  const s = await demarrer();
  const c = await s.api('POST', '/changes', 'tp', { type: 'normal', titre: 'Prod', environnement: 'production' });
  assert.equal(c.body.etat, 'brouillon');
  const id = c.body.id;

  const avant = await s.api('POST', `/changes/${id}/link`, 'tp', { empreinte: 'sha256:abcdef1234' });
  assert.equal(avant.status, 409);

  assert.equal((await s.api('POST', `/changes/${id}/approve`, 'tp', {})).status, 403);

  const ok = await s.api('POST', `/changes/${id}/approve`, 'ta', {});
  assert.equal(ok.status, 200);
  assert.equal(ok.body.etat, 'approuve');
  assert.equal(ok.body.approbateur, 'alice');

  const lie = await s.api('POST', `/changes/${id}/link`, 'tp', {
    empreinte: 'sha256:abcdef1234',
    run_url: 'https://example.invalid/run/1',
    ci: 'http://cmdb.invalid/ipam/services/1/',
  });
  assert.equal(lie.body.etat, 'en_cours');
  assert.equal(lie.body.deploiements[0].ci, 'http://cmdb.invalid/ipam/services/1/');
  assert.equal(lie.body.deploiements.length, 1);
  assert.equal(lie.body.deploiements[0].environnement, 'production');

  const clos = await s.api('POST', `/changes/${id}/close`, 'tp', { resultat: 'succes' });
  assert.equal(clos.body.etat, 'clos');
  assert.equal(clos.body.resultat, 'succes');
  assert.deepEqual(
    clos.body.historique.map((h) => h.action),
    ['creation', 'approbation', 'deploiement', 'cloture']
  );
  assert.equal((await s.api('GET', `/changes/${id}`, 'ta')).body.etat, 'clos');
  await s.arreter();
});

test('ACC-04 séparation des tâches : un même compte ne peut pas approuver sa demande', async () => {
  const s = await demarrer();
  const c = await s.api('POST', '/changes', 'ts', { type: 'normal', titre: 'Auto-approbation' });
  const r = await s.api('POST', `/changes/${c.body.id}/approve`, 'ts', {});
  assert.equal(r.status, 403);
  assert.match(r.body.erreur, /propre demande/);
  await s.arreter();
});

test('refus : motif obligatoire, déploiement ensuite impossible', async () => {
  const s = await demarrer();
  const c = await s.api('POST', '/changes', 'tp', { type: 'normal', titre: 'À refuser' });
  assert.equal((await s.api('POST', `/changes/${c.body.id}/reject`, 'ta', {})).status, 400);
  const r = await s.api('POST', `/changes/${c.body.id}/reject`, 'ta', { motif: 'risque trop élevé' });
  assert.equal(r.body.etat, 'refuse');
  const l = await s.api('POST', `/changes/${c.body.id}/link`, 'tp', { empreinte: 'sha256:abcdef1234' });
  assert.equal(l.status, 409);
  await s.arreter();
});

test('ACC-07 droits : le jeton du pipeline ne peut pas approuver, l\'approbateur ne peut pas créer', async () => {
  const s = await demarrer();
  const c = await s.api('POST', '/changes', 'tp', { type: 'normal', titre: 'X' });
  assert.equal((await s.api('POST', `/changes/${c.body.id}/approve`, 'tp', {})).status, 403);
  assert.equal((await s.api('POST', '/changes', 'ta', { type: 'normal', titre: 'Y' })).status, 403);
  await s.arreter();
});

test('incident : ouvert puis clos, sans déploiement', async () => {
  const s = await demarrer();
  const c = await s.api('POST', '/changes', 'tp', { type: 'incident', titre: 'Panne /health', ci: 'http://cmdb/ipam/services/7/' });
  assert.match(c.body.id, /^INC-/);
  assert.equal(c.body.etat, 'ouvert');
  assert.equal((await s.api('POST', `/changes/${c.body.id}/link`, 'tp', { empreinte: 'sha256:abcdef1234' })).status, 409);
  assert.equal((await s.api('GET', `/changes/${c.body.id}`, 'tp')).body.ci, 'http://cmdb/ipam/services/7/');
  assert.equal((await s.api('POST', `/changes/${c.body.id}/close`, 'tp', { resultat: 'succes' })).status, 409);
  assert.equal((await s.api('POST', `/changes/${c.body.id}/kb`, 'tp', { fiche: 'kb-2' })).status, 400);
  const k = await s.api('POST', `/changes/${c.body.id}/kb`, 'tp', { fiche: 'KB-002', url: 'https://example.org/kb' });
  assert.equal(k.body.kb[0].fiche, 'KB-002');
  assert.equal((await s.api('POST', `/changes/${c.body.id}/close`, 'tp', { resultat: 'succes' })).body.etat, 'clos');
  assert.equal((await s.api('POST', `/changes/${c.body.id}/kb`, 'tp', { fiche: 'KB-003' })).status, 409);
  await s.arreter();
});

test('incident en échec : clôture possible sans fiche ; un changement ne porte pas de fiche', async () => {
  const s = await demarrer();
  const i = await s.api('POST', '/changes', 'tp', { type: 'incident', titre: 'Déploiement échoué' });
  assert.equal((await s.api('POST', `/changes/${i.body.id}/close`, 'tp', { resultat: 'echec' })).body.etat, 'clos');
  const c = await s.api('POST', '/changes', 'tp', { type: 'standard', titre: 'X' });
  assert.equal((await s.api('POST', `/changes/${c.body.id}/kb`, 'tp', { fiche: 'KB-001' })).status, 409);
  await s.arreter();
});

test('validation des entrées', async () => {
  const s = await demarrer();
  assert.equal((await s.api('POST', '/changes', 'tp', { type: 'inconnu', titre: 'X' })).status, 400);
  assert.equal((await s.api('POST', '/changes', 'tp', { type: 'normal' })).status, 400);
  assert.equal((await s.api('POST', '/changes', 'tp', { type: 'normal', titre: 'x'.repeat(201) })).status, 400);
  assert.equal((await s.api('GET', '/changes/CHG-2026-9999', 'tp')).status, 404);
  assert.equal((await s.api('GET', '/changes/../etc', 'tp')).status, 404);
  const c = await s.api('POST', '/changes', 'tp', { type: 'standard', titre: 'S' });
  assert.equal((await s.api('POST', `/changes/${c.body.id}/link`, 'tp', { empreinte: 'a b' })).status, 400);
  assert.equal((await s.api('POST', `/changes/${c.body.id}/close`, 'tp', { resultat: 'x' })).status, 409);
  await s.arreter();
});

test('liste filtrée par état', async () => {
  const s = await demarrer();
  await s.api('POST', '/changes', 'tp', { type: 'normal', titre: 'A' });
  await s.api('POST', '/changes', 'tp', { type: 'standard', titre: 'B' });
  const l = await s.api('GET', '/changes?etat=brouillon', 'ta');
  assert.equal(l.body.length, 1);
  assert.equal(l.body[0].titre, 'A');
  await s.arreter();
});

test('persistance : les données survivent à un redémarrage, la numérotation continue', async () => {
  const s1 = await demarrer();
  await s1.api('POST', '/changes', 'tp', { type: 'normal', titre: 'Persistant' });
  await s1.arreter();
  const s2 = await demarrer(s1.dir);
  const l = await s2.api('GET', '/changes', 'ta');
  assert.equal(l.body.length, 1);
  const n = await s2.api('POST', '/changes', 'tp', { type: 'normal', titre: 'Suivant' });
  assert.match(n.body.id, /-0002$/);
  await s2.arreter();
});

test('ACC-07 configuration des jetons : refus des entrées invalides', () => {
  assert.throws(() => parseTokens(''), /aucun jeton/);
  assert.throws(() => parseTokens('seul'), /invalide/);
  assert.throws(() => parseTokens('t:u:inconnu'), /droit inconnu/);
});

test('interface web : pages publiques sans donnée, CSP stricte, données toujours protégées', async () => {
  const s = await demarrer();
  for (const [chemin, type] of [['/', 'text/html'], ['/ui.css', 'text/css'], ['/ui.js', 'text/javascript']]) {
    const res = await fetch(s.base + chemin);
    assert.equal(res.status, 200);
    assert.ok(res.headers.get('content-type').startsWith(type));
    assert.match(res.headers.get('content-security-policy'), /default-src 'none'/);
    assert.ok((await res.text()).length > 100);
  }
  assert.equal((await fetch(s.base + '/ui/../server.js')).status, 401);
  assert.equal((await fetch(s.base + '/ui.js', { method: 'POST' })).status, 401);
  assert.equal((await s.api('GET', '/changes')).status, 401);
  await s.arreter();
});
