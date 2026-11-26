/// JavaScript del reproductor de YouTube (API de iframes) que comparten
/// Android (dentro de un WebView) y la web (dentro de la página).
///
/// `ttCrear(elemento, avisar)` arma un reproductor sin los controles de
/// YouTube (los botones son los de Taotao, así cada toque se comparte con la
/// pareja) y avisa con textos cortos: `listo`, `estado:N`, `error:N` y
/// `titulo:<id>|<nombre>` y `lista:<id>|<id1,id2,…>`.
///
/// Bilibili no tiene una API para manejar su reproductor desde afuera: con
/// `cargarBili` se pone su reproductor incrustado en el segundo que toca, y
/// cada play, pausa o salto lo vuelve a abrir en el segundo justo. El tiempo
/// lo lleva este mismo código con un reloj (Bilibili no lo cuenta), y con la
/// duración avisa `estado:0` cuando la canción termina.
const motorJs = r'''
(function () {
  if (window.ttCrear) return;
  var esperan = [];
  var cargando = false;
  function conApi(f) {
    if (window.YT && window.YT.Player) { f(); return; }
    esperan.push(f);
    if (cargando) return;
    cargando = true;
    var antes = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = function () {
      if (antes) { try { antes(); } catch (e) {} }
      var fs = esperan; esperan = [];
      fs.forEach(function (g) { g(); });
    };
    var s = document.createElement('script');
    s.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(s);
  }
  // Pide los ids de una lista de YouTube con un reproductor escondido.
  window.ttLista = function (lista, avisar) {
    conApi(function () {
      var d = document.createElement('div');
      var c = document.createElement('div');
      c.style.cssText = 'position:fixed;left:-10000px;top:0;width:200px;height:120px';
      c.appendChild(d);
      document.body.appendChild(c);
      var listo = false, vueltas = 0, t = null, p = null;
      function fin(ids) {
        if (listo) return;
        listo = true;
        clearInterval(t);
        avisar('lista:' + lista + '|' + (ids || []).join(','));
        try { p.destroy(); } catch (e) {}
        c.remove();
      }
      p = new YT.Player(d, {
        width: 200, height: 120,
        playerVars: { listType: 'playlist', list: lista, origin: window.location.origin },
        events: {
          onReady: function () {
            t = setInterval(function () {
              var ids = null;
              try { ids = p.getPlaylist(); } catch (e) {}
              if (ids && ids.length) fin(ids);
              else if (++vueltas > 20) fin([]);
            }, 400);
          },
          onError: function () { fin([]); }
        }
      });
    });
  };
  window.ttCrear = function (el, avisar) {
    var o = { listo: false, pend: null, p: null, id: null };
    // Reproductor de Bilibili (un iframe encima del de YouTube).
    var b = { on: false, bv: null, parte: 1, dur: 0, base: 0, desde: 0,
              suena: false, abrir: null, fin: false };
    var bf = document.createElement('iframe');
    bf.setAttribute('allow', 'autoplay; encrypted-media; fullscreen');
    bf.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
    bf.setAttribute('scrolling', 'no');
    bf.setAttribute('frameborder', '0');
    bf.style.cssText = 'position:absolute;left:0;top:0;width:100%;height:100%;border:0;display:none;background:#000';
    (el.parentNode || document.body).appendChild(bf);
    function bTiempo() {
      var t = b.suena ? b.base + (Date.now() - b.desde) / 1000 : b.base;
      if (t < b.base && b.suena) t = b.base;
      return b.dur > 0 && t > b.dur ? b.dur : t;
    }
    function yt(visible) {
      try { o.p.getIframe().style.visibility = visible ? 'visible' : 'hidden'; } catch (e) {}
    }
    // Abre el reproductor de Bilibili en el segundo que toca. Se junta en
    // un solo paso lo que pase en el mismo momento (pausa + ir, etc.).
    function bAbrir() {
      clearTimeout(b.abrir);
      b.abrir = setTimeout(function () {
        if (!b.on) return;
        // Tarda un poquito en cargar: se abre un segundo más adelante y el
        // reloj espera ese segundo.
        var seg = Math.max(0, Math.floor(bTiempo() + (b.suena ? 1 : 0)));
        if (b.suena) { b.base = seg; b.desde = Date.now() + 1000; }
        bf.src = 'https://player.bilibili.com/player.html?bvid=' + b.bv +
          '&p=' + b.parte + '&page=' + b.parte + '&t=' + seg +
          '&autoplay=' + (b.suena ? 1 : 0) +
          '&danmaku=0&high_quality=1&as_wide=1';
      }, 0);
    }
    setInterval(function () {
      if (b.on && b.suena && b.dur > 0 && !b.fin && bTiempo() >= b.dur) {
        b.fin = true;
        b.base = b.dur;
        b.suena = false;
        avisar('estado:0');
      }
    }, 500);
    function bApagar() {
      if (!b.on) return;
      b.on = false;
      clearTimeout(b.abrir);
      bf.style.display = 'none';
      bf.src = 'about:blank';
      yt(true);
    }
    o.cargarBili = function (bv, parte, seg, dur, tocar) {
      if (o.listo) { try { o.p.stopVideo(); } catch (e) {} }
      o.pend = null;
      yt(false);
      b.on = true; b.bv = bv; b.parte = parte || 1; b.dur = dur || 0;
      b.base = seg; b.desde = Date.now(); b.suena = !!tocar; b.fin = false;
      o.id = 'bili:' + bv + ':' + b.parte;
      bf.style.display = 'block';
      bAbrir();
    };
    function titulo() {
      try {
        var d = o.p.getVideoData();
        if (d && d.title) avisar('titulo:' + d.video_id + '|' + d.title);
      } catch (e) {}
    }
    conApi(function () {
      o.p = new YT.Player(el, {
        width: '100%', height: '100%',
        playerVars: {
          controls: 0, playsinline: 1, rel: 0, modestbranding: 1,
          disablekb: 1, fs: 0, iv_load_policy: 3,
          origin: window.location.origin
        },
        events: {
          onReady: function () {
            o.listo = true;
            avisar('listo');
            if (b.on) yt(false);
            if (o.pend) { var x = o.pend; o.pend = null; o.cargar(x[0], x[1], x[2]); }
          },
          onStateChange: function (e) {
            if (b.on) return;
            avisar('estado:' + e.data);
            if (e.data === 1) titulo();
          },
          onError: function (e) { if (!b.on) avisar('error:' + e.data); }
        }
      });
    });
    o.cargar = function (id, seg, tocar) {
      bApagar();
      if (!o.listo) { o.pend = [id, seg, tocar]; return; }
      o.id = id;
      if (tocar) o.p.loadVideoById({ videoId: id, startSeconds: seg });
      else o.p.cueVideoById({ videoId: id, startSeconds: seg });
    };
    o.tocar = function () {
      if (b.on) {
        if (b.suena) return;
        b.desde = Date.now(); b.suena = true; b.fin = false; bAbrir();
        return;
      }
      if (o.listo) o.p.playVideo();
    };
    o.pausar = function () {
      if (b.on) {
        if (!b.suena) return;
        b.base = bTiempo(); b.suena = false; bAbrir();
        return;
      }
      if (o.listo) o.p.pauseVideo();
    };
    o.ir = function (s) {
      if (b.on) {
        if (Math.abs(bTiempo() - s) < 1.5) return;
        b.base = s; b.desde = Date.now(); b.fin = false; bAbrir();
        return;
      }
      if (o.listo) o.p.seekTo(s, true);
    };
    // Vuelve a abrir Bilibili (por si el navegador no lo dejó sonar).
    o.recargar = function () { if (b.on) bAbrir(); };
    o.tiempo = function () {
      if (b.on) return bTiempo();
      return o.listo && o.p.getCurrentTime ? o.p.getCurrentTime() : -1;
    };
    o.estado = function () {
      if (b.on) return b.fin ? 0 : (b.suena ? 1 : 2);
      return o.listo && o.p.getPlayerState ? o.p.getPlayerState() : -2;
    };
    o.cerrar = function () {
      bApagar();
      try { o.p.destroy(); } catch (e) {}
      bf.remove();
    };
    return o;
  };
})();
''';
