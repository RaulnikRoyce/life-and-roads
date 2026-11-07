import { after, test, type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import type { ResultSetHeader } from 'mysql2';
import app from '../../src/app';
import { getPool, fecharPool, pingBanco } from '../../src/shared/database/pool';
import { migrar } from '../../src/shared/database/migrar';
import { getJwtSecret, JWT_ALGORITHM, JWT_AUDIENCE, JWT_ISSUER } from '../../src/shared/config/jwt';

after(fecharPool);
async function ambiente(t: TestContext) {
  try { await pingBanco(); await migrar(); }
  catch (e) { if (process.env.CI === 'true') throw e; t.skip('MySQL indisponível neste ambiente'); return null; }
  const [row] = await getPool().execute<ResultSetHeader>('INSERT INTO usuarios(email,senha) VALUES (?,?)', [`sync.${crypto.randomUUID()}@teste.local`, 'sem-login']);
  const id=row.insertId;
  const token=jwt.sign({id,typ:'access'},getJwtSecret(),{algorithm:JWT_ALGORITHM,audience:JWT_AUDIENCE,issuer:JWT_ISSUER,expiresIn:300});
  const server=app.listen(0); const address=server.address();
  const base=`http://127.0.0.1:${typeof address==='object' && address ? address.port : 0}`;
  t.after(async()=>{await new Promise<void>(r=>server.close(()=>r()));await getPool().execute('DELETE FROM usuarios WHERE id=?',[id]);});
  return async (method:string,path:string,body?:unknown,version?:string)=>{
    const r=await fetch(base+path,{method,headers:{'content-type':'application/json',authorization:'Bearer '+token,...(version===undefined?{}:{'X-Base-Atualizado-Em':version})},body:body===undefined?undefined:JSON.stringify(body)});
    return {status:r.status,body:await r.json() as Record<string,any>};
  };
}
const ficha={marca:'Honda',modelo:'Bros',ano:null,cilindrada:null,kmLitro:35,kmLitroAlcool:null,combustivel:'gasolina',kmAtual:1000,tanqueLitros:12,personalizacoes:''};
const agenda={oleoUltima:'2026-10-01',oleoProxima:'2027-01-01',revisaoUltima:null,pneusUltima:null,pneusProxima:null,ipvaProxima:null,seguroProxima:null,licenciamentoProxima:null};
for(const [rota,dados,campo,valores] of [
  ['/ficha',ficha,'kmAtual',[1001,1002]],
  ['/manutencao',agenda,'oleoUltima',['2026-10-02','2026-10-03']],
] as const){
 test(`${rota}: versao monotona mesmo com relogio parado; preserva clientes antigos`,async(t)=>{
  const pedir=await ambiente(t);if(!pedir)return;
  const fixed=Date.now();t.mock.method(Date,'now',()=>fixed);
  const a=await pedir('PUT',rota,dados);const b=await pedir('PUT',rota,dados);
  assert.equal(a.status,200);assert.equal(b.status,200);assert.equal(Date.parse(b.body.atualizadoEm)-Date.parse(a.body.atualizadoEm),1);
  assert.equal((await pedir('GET',rota)).body.atualizadoEm,b.body.atualizadoEm);
 });
 test(`${rota}: duas criacoes e duas atualizacoes com mesma base nao sobrescrevem a vencedora`,async(t)=>{
  const pedir=await ambiente(t);if(!pedir)return;
  const initial=await Promise.all(valores.map(v=>pedir('PUT',rota,{...dados,[campo]:v},'null')));
  assert.deepEqual(initial.map(r=>r.status).sort(),[200,409]);
  let read=await pedir('GET',rota);assert.equal(read.body[campo],valores[initial[0].status===200?0:1]);
  const base=read.body.atualizadoEm;
  const updates=await Promise.all(valores.map(v=>pedir('PUT',rota,{...dados,[campo]:v},base)));
  assert.deepEqual(updates.map(r=>r.status).sort(),[200,409]);
  read=await pedir('GET',rota);assert.equal(read.body[campo],valores[updates[0].status===200?0:1]);
  assert.equal(read.body.atualizadoEm,updates.find(r=>r.status===200)!.body.atualizadoEm);
  assert.equal((await pedir('PUT',rota,dados,base)).status,409);
  assert.equal((await pedir('GET',rota)).body.atualizadoEm,read.body.atualizadoEm);
 });
 test(`${rota}: versao invalida retorna 400 e nao altera registro`,async(t)=>{
  const pedir=await ambiente(t);if(!pedir)return;
  const created=await pedir('PUT',rota,dados,'null');assert.equal(created.status,200);
  for(const version of ['invalida','2026-02-30T00:00:00.000Z'])assert.equal((await pedir('PUT',rota,dados,version)).status,400);
  assert.deepEqual((await pedir('GET',rota)).body,created.body);
 });
}
test('consumo positivo aceito persiste para gasolina e alcool, incluindo extremos de number',async(t)=>{
 const pedir=await ambiente(t);if(!pedir)return;
 for(const consumo of [35.42,35.123456789,1000,1e100,Number.MAX_VALUE,Number.MIN_VALUE]){
  const saved=await pedir('PUT','/ficha',{...ficha,kmLitro:consumo,kmLitroAlcool:consumo});assert.equal(saved.status,200,`consumo ${consumo}`);
  const read=await pedir('GET','/ficha');assert.equal(read.body.kmLitro,consumo);assert.equal(read.body.kmLitroAlcool,consumo);
 }
});
