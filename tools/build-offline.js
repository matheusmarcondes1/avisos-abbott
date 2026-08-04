#!/usr/bin/env node
/* ============================================================
   Gera offline.html a partir de index.html.

   A versão offline é um único arquivo, sem NENHUMA requisição externa:
   funciona com o HTML salvo em qualquer pasta (pen drive, rede, disco),
   aberto direto no navegador, sem internet e sem servidor.

   O que é removido: tudo entre os marcadores ONLINE-ONLY (favicon da CDN,
   integração de andon/Supabase e sua seção de configurações). A flag
   OFFLINE passa a true, fazendo a logo usar só o wordmark vetorial embutido.

   Uso:  node tools/build-offline.js
   ============================================================ */
const fs = require('fs');
const path = require('path');

const raiz = path.join(__dirname, '..');
const origem = path.join(raiz, 'index.html');
const destino = path.join(raiz, 'offline.html');

let html = fs.readFileSync(origem, 'utf8');

// 1) remove os blocos marcados (comentário HTML e comentário CSS/JS)
const antes = html.length;
html = html.replace(/[ \t]*(?:<!--|\/\*) ?ONLINE-ONLY:START[\s\S]*?ONLINE-ONLY:END ?(?:-->|\*\/)\n?/g, '');
const removidos = antes - html.length;

if (/ONLINE-ONLY/.test(html)) {
  console.error('ERRO: sobraram marcadores ONLINE-ONLY — verifique os pares START/END.');
  process.exit(1);
}

// 2) ativa o modo offline (logo sem CDN)
if (!/const OFFLINE = false;/.test(html)) {
  console.error('ERRO: não encontrei a flag "const OFFLINE = false;" em index.html.');
  process.exit(1);
}
html = html.replace('const OFFLINE = false;', 'const OFFLINE = true;');

// 3) título próprio, para diferenciar a aba
html = html.replace(
  '<title>Painel de Avisos — Abbott BR-SH-M</title>',
  '<title>Painel de Avisos (offline) — Abbott BR-SH-M</title>'
);

// 4) cabeçalho explicativo
html = html.replace(
  '<!DOCTYPE html>',
  '<!DOCTYPE html>\n<!-- GERADO AUTOMATICAMENTE por tools/build-offline.js a partir de index.html.\n' +
  '     Não edite este arquivo à mão: altere index.html e rode o script de novo.\n' +
  '     Versão 100% offline: um único arquivo, sem requisições externas. -->'
);

fs.writeFileSync(destino, html);

// 5) confere que não sobrou nenhuma referência externa
const externas = [...html.matchAll(/(?:src|href)\s*=\s*["']https?:\/\/[^"']+/gi)].map(m => m[0]);
const imports = [...html.matchAll(/import\(['"]https?:\/\/[^'"]+/gi)].map(m => m[0]);
const pendentes = [...externas, ...imports];

console.log('offline.html gerado (' + (html.length / 1024).toFixed(1) + ' KB, ' +
  (removidos / 1024).toFixed(1) + ' KB removidos).');
if (pendentes.length) {
  console.error('ATENÇÃO: ainda há referências externas:\n  ' + pendentes.join('\n  '));
  process.exit(1);
}
console.log('Nenhuma requisição externa: OK.');
