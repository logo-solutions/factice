'use strict';

const $ = (id) => document.getElementById(id);
let jeton = '';
try { jeton = sessionStorage.getItem('itsm-jeton') || ''; } catch { /* stockage indisponible */ }

function el(tag, props = {}, ...enfants) {
  const n = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === 'class') n.className = v;
    else n.setAttribute(k, v);
  }
  for (const e of enfants) n.append(e);
  return n;
}

function message(texte, erreur = false) {
  const m = $('message');
  m.textContent = texte;
  m.className = erreur ? 'erreur' : '';
}

async function api(chemin) {
  const r = await fetch(chemin, { headers: { Authorization: `Bearer ${jeton}` } });
  const corps = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(corps.erreur || `HTTP ${r.status}`);
  return corps;
}

const classeEtat = (i) => `etat etat-${i.etat}${i.etat === 'clos' ? `-${i.resultat}` : ''}`;
const libelleEtat = (i) => (i.etat === 'clos' && i.resultat ? `clos (${i.resultat})` : i.etat);
const date = (iso) => (iso ? new Date(iso).toLocaleString('fr-FR') : '-');

function lienSur(url) {
  if (/^https?:\/\//i.test(url)) return el('a', { href: url, target: '_blank', rel: 'noopener noreferrer' }, url);
  return document.createTextNode(url || '-');
}

function ligne(i) {
  const tr = el('tr', { tabindex: '0' },
    el('td', {}, el('code', {}, i.id)),
    el('td', {}, i.type),
    el('td', { class: classeEtat(i) }, libelleEtat(i)),
    el('td', {}, i.environnement || '-'),
    el('td', {}, i.titre),
    el('td', {}, i.demandeur),
    el('td', {}, date(i.mis_a_jour)));
  const ouvrir = () => detail(i.id);
  tr.addEventListener('click', ouvrir);
  tr.addEventListener('keydown', (e) => { if (e.key === 'Enter') ouvrir(); });
  return tr;
}

async function liste() {
  const params = new URLSearchParams();
  if ($('f-etat').value) params.set('etat', $('f-etat').value);
  if ($('f-type').value) params.set('type', $('f-type').value);
  const items = await api(`/changes?${params}`);
  items.sort((a, b) => b.cree.localeCompare(a.cree));
  const tbody = $('liste').querySelector('tbody');
  tbody.replaceChildren(...items.map(ligne));
  message(items.length ? `${items.length} demande(s)` : 'Aucune demande');
  $('liste').hidden = false;
  $('filtres').hidden = false;
}

async function detail(id) {
  const i = await api(`/changes/${encodeURIComponent(id)}`);
  const d = $('detail');
  const champs = [
    ['Identifiant', el('code', {}, i.id)],
    ['Titre', i.titre],
    ['Type', i.type],
    ['État', el('span', { class: classeEtat(i) }, libelleEtat(i))],
    ['Environnement', i.environnement || '-'],
    ['Description', i.description || '-'],
    ['Demandeur', i.demandeur],
    ['Approbateur', i.approbateur || '-'],
    ['Créé', date(i.cree)],
  ];
  const dl = el('dl');
  for (const [k, v] of champs) dl.append(el('dt', {}, k), el('dd', {}, v));

  const deps = el('ul');
  for (const p of i.deploiements) {
    deps.append(el('li', {},
      `${date(p.date)} · ${p.environnement || '-'} · `, el('code', {}, p.empreinte),
      ' · run ', lienSur(p.run_url), ' · élément CMDB ', lienSur(p.ci)));
  }
  const histo = el('ul');
  for (const h of i.historique) {
    const extra = h.motif ? ` — ${h.motif}` : h.resultat ? ` — ${h.resultat}` : '';
    histo.append(el('li', {}, `${date(h.date)} · ${h.acteur} · ${h.action}${extra}`));
  }
  d.replaceChildren(
    el('h2', {}, 'Détail'), dl,
    el('h2', {}, 'Déploiements'), i.deploiements.length ? deps : el('p', {}, 'Aucun'),
    el('h2', {}, 'Historique'), histo);
  d.hidden = false;
  d.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

async function charger() {
  try {
    await liste();
  } catch (e) {
    message(e.message, true);
    if (/jeton/.test(e.message)) deconnecter(false);
  }
}

function deconnecter(effacerMessage = true) {
  jeton = '';
  try { sessionStorage.removeItem('itsm-jeton'); } catch { /* ignoré */ }
  $('jeton').value = '';
  $('liste').hidden = true;
  $('filtres').hidden = true;
  $('detail').hidden = true;
  $('deconnexion').hidden = true;
  if (effacerMessage) message('');
}

function connecte() {
  $('deconnexion').hidden = false;
  charger();
}

for (const etat of ['brouillon', 'approuve', 'refuse', 'en_cours', 'ouvert', 'clos']) {
  $('f-etat').append(el('option', {}, etat));
}
$('connexion').addEventListener('submit', (e) => {
  e.preventDefault();
  jeton = $('jeton').value.trim();
  try { sessionStorage.setItem('itsm-jeton', jeton); } catch { /* ignoré */ }
  connecte();
});
$('deconnexion').addEventListener('click', () => deconnecter());
$('actualiser').addEventListener('click', charger);
$('f-etat').addEventListener('change', charger);
$('f-type').addEventListener('change', charger);
if (jeton) connecte();
