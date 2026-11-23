/// JavaScript del reproductor de YouTube (API de iframes) que comparten
/// Android (dentro de un WebView) y la web (dentro de la página).
///
/// `ttCrear(elemento, avisar)` arma un reproductor sin los controles de
/// YouTube (los botones son los de Taotao, así cada toque se comparte con la
/// pareja) y avisa con textos cortos: `listo`, `estado:N`, `error:N` y
/// `titulo:<id>|<nombre>`.
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
  window.ttCrear = function (el, avisar) {
    var o = { listo: false, pend: null, p: null, id: null };
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
            if (o.pend) { var x = o.pend; o.pend = null; o.cargar(x[0], x[1], x[2]); }
          },
          onStateChange: function (e) {
            avisar('estado:' + e.data);
            if (e.data === 1) titulo();
          },
          onError: function (e) { avisar('error:' + e.data); }
        }
      });
    });
    o.cargar = function (id, seg, tocar) {
      if (!o.listo) { o.pend = [id, seg, tocar]; return; }
      o.id = id;
      if (tocar) o.p.loadVideoById({ videoId: id, startSeconds: seg });
      else o.p.cueVideoById({ videoId: id, startSeconds: seg });
    };
    o.tocar = function () { if (o.listo) o.p.playVideo(); };
    o.pausar = function () { if (o.listo) o.p.pauseVideo(); };
    o.ir = function (s) { if (o.listo) o.p.seekTo(s, true); };
    o.tiempo = function () {
      return o.listo && o.p.getCurrentTime ? o.p.getCurrentTime() : -1;
    };
    o.estado = function () {
      return o.listo && o.p.getPlayerState ? o.p.getPlayerState() : -2;
    };
    o.cerrar = function () { try { o.p.destroy(); } catch (e) {} };
    return o;
  };
})();
''';
