// Scolia — fonctions communes à toutes les pages web
const API = localStorage.getItem('api_url') || 'https://votre-domaine.com/api';

function getToken() { return localStorage.getItem('token'); }
function getUser()  { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } }

function authHeader() {
  return { 'Authorization': 'Bearer ' + getToken(), 'Content-Type': 'application/json' };
}

async function apiFetch(path, options = {}) {
  if (!getToken()) { window.location.href = 'index.html'; return; }
  options.headers = { ...authHeader(), ...(options.headers || {}) };
  const r = await fetch(API + path, options);
  if (r.status === 401) { localStorage.clear(); window.location.href = 'index.html'; return; }
  const data = await r.json();
  if (!r.ok) throw new Error(data.erreur || 'Erreur ' + r.status);
  return data;
}

function apiGet(path, params = {}) {
  const qs = new URLSearchParams(params).toString();
  return apiFetch(path + (qs ? '?' + qs : ''));
}

function apiPost(path, body)   { return apiFetch(path, { method: 'POST',   body: JSON.stringify(body) }); }
function apiPut(path, body)    { return apiFetch(path, { method: 'PUT',    body: JSON.stringify(body) }); }
function apiDelete(path)       { return apiFetch(path, { method: 'DELETE' }); }

function formatFCFA(n) {
  return new Intl.NumberFormat('fr-FR').format(Math.round(n || 0)) + ' FCFA';
}

function formatDate(str) {
  if (!str) return '—';
  return new Date(str).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
}

function badge(statut) {
  const cfg = { paye: ['Payé','#059669'], partiel: ['Partiel','#F97316'], non_paye: ['Non payé','#DC2626'] };
  const [label, color] = cfg[statut] || ['—', '#8E99B4'];
  return `<span style="background:${color}22;color:${color};border:1px solid ${color}44;padding:2px 8px;border-radius:5px;font-size:12px;font-weight:600;">${label}</span>`;
}

function showAlert(msg, type = 'success') {
  const el = document.getElementById('alert');
  if (!el) return;
  el.textContent = msg;
  el.style.display = 'block';
  el.style.background = type === 'success' ? '#059669' : '#DC2626';
  el.style.color = '#fff';
  setTimeout(() => { el.style.display = 'none'; }, 3500);
}

function deconnexion() {
  apiPost('/auth/deconnexion').finally(() => { localStorage.clear(); window.location.href = 'index.html'; });
}

// Afficher le nom de l'utilisateur dans la nav
document.addEventListener('DOMContentLoaded', () => {
  const u = getUser();
  const el = document.getElementById('user-name');
  if (el && u) el.textContent = (u.prenom || '') + ' ' + (u.nom || '');
  if (!getToken()) window.location.href = 'index.html';
});
