import { test } from "node:test";
import assert from "node:assert/strict";
import { infoBilibili } from "../src/index.js";

const respuesta = {
  code: 0,
  data: {
    bvid: "BV1GJ411x7h7",
    title: "Canción bonita",
    pic: "http://i0.hdslb.com/bfs/archive/x.jpg",
    duration: 213,
    pages: [{ page: 1, part: "P1", duration: 213 }],
  },
};

test("trae nombre, portada y partes de un BV", async () => {
  const pedidos = [];
  const res = await infoBilibili(
    new URL("https://w.dev/bilibili?bvid=BV1GJ411x7h7"),
    async (u) => {
      pedidos.push(u);
      return new Response(JSON.stringify(respuesta));
    },
  );
  assert.equal(res.status, 200);
  const j = await res.json();
  assert.equal(j.title, "Canción bonita");
  assert.equal(j.pages[0].duration, 213);
  assert.match(pedidos[0], /bvid=BV1GJ411x7h7$/);
  assert.equal(res.headers.get("Access-Control-Allow-Origin"), "*");
});

test("abre un link corto b23.tv", async () => {
  const res = await infoBilibili(
    new URL("https://w.dev/bilibili?u=" + encodeURIComponent("https://b23.tv/abc123")),
    async (u) =>
      u.startsWith("https://b23.tv/")
        ? new Response(null, {
            status: 302,
            headers: { Location: "https://www.bilibili.com/video/BV1GJ411x7h7?share=1" },
          })
        : new Response(JSON.stringify(respuesta)),
  );
  assert.equal(res.status, 200);
  assert.equal((await res.json()).bvid, "BV1GJ411x7h7");
});

test("no abre links que no son de Bilibili", async () => {
  let llamado = false;
  const res = await infoBilibili(
    new URL("https://w.dev/bilibili?u=" + encodeURIComponent("https://evil.example/x")),
    async () => {
      llamado = true;
      return new Response("{}");
    },
  );
  assert.equal(res.status, 400);
  assert.equal(llamado, false);
});

test("BV inválido", async () => {
  const res = await infoBilibili(new URL("https://w.dev/bilibili?bvid=hola"), async () => {
    throw new Error("no debería");
  });
  assert.equal(res.status, 400);
});
