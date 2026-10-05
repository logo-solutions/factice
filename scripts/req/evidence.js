#!/usr/bin/env node
'use strict';
// Flux 6 : preuves de tests rattachées aux exigences.
// Exécute les suites de tests, retient les tests dont le nom cite un identifiant d'exigence
// (ex. « ACC-04 séparation des tâches ») et écrit un rapport Markdown.
// Usage : node scripts/req/evidence.js [fichier de sortie]   (défaut : preuves/preuves-exigences.md)
// Code de sortie 1 si un test rattaché à une exigence échoue.
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const racine = path.resolve(__dirname, '..', '..');
const sortie = path.resolve(process.argv[2] || path.join(racine, 'preuves', 'preuves-exigences.md'));
const suites = [
  { nom: 'app', dossier: 'app', args: ['--test', 'tests/'] },
  { nom: 'itsm-mock', dossier: 'itsm-mock', args: ['--test'] },
];

const titres = new Map();
for (const f of fs.readdirSync(path.join(racine, 'Docs', 'exigences'))) {
  if (!f.endsWith('.md')) continue;
  const texte = fs.readFileSync(path.join(racine, 'Docs', 'exigences', f), 'utf8');
  for (const m of texte.matchAll(/^### ([A-Z]{3,4}-\d{2}) — (.+)$/gm)) titres.set(m[1], m[2]);
}

const lignes = [];
let echecs = 0;
let execs = 0;
for (const s of suites) {
  const r = spawnSync(process.execPath, [...s.args.slice(0, 1), '--test-reporter=tap', ...s.args.slice(1)],
    { cwd: path.join(racine, s.dossier), encoding: 'utf8' });
  for (const l of (r.stdout || '').split('\n')) {
    const m = /^(not ok|ok) \d+ - (.+?)(?: # .*)?$/.exec(l);
    if (!m) continue;
    execs += 1;
    const ids = [...new Set(m[2].match(/\b[A-Z]{3,4}-\d{2}\b/g) || [])].filter((i) => titres.has(i));
    if (!ids.length) continue;
    const ok = m[1] === 'ok';
    if (!ok) echecs += 1;
    for (const id of ids) lignes.push({ id, test: m[2], suite: s.nom, ok });
  }
}

lignes.sort((a, b) => a.id.localeCompare(b.id) || a.test.localeCompare(b.test));
const couvertes = new Set(lignes.map((l) => l.id));
const out = [
  '# Preuves de tests par exigence',
  '',
  `${execs} test(s) exécuté(s), ${lignes.length} rattaché(s) à ${couvertes.size} exigence(s), ${echecs} en échec.`,
  '',
  '| Exigence | Titre | Test | Suite | Résultat |',
  '|---|---|---|---|---|',
  ...lignes.map((l) => `| ${l.id} | ${titres.get(l.id)} | ${l.test.replaceAll('|', '/')} | ${l.suite} | ${l.ok ? 'réussi' : '**ÉCHEC**'} |`),
  '',
];
fs.mkdirSync(path.dirname(sortie), { recursive: true });
fs.writeFileSync(sortie, out.join('\n'));
console.log(out.slice(2, 3).join(''));
process.exit(echecs ? 1 : 0);
