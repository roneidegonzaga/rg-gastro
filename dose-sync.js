// ============================================================
// RG GASTRO | Camada de isolamento e sincronizacao do D.O.S.E.
// Roda dentro de cada ferramenta aberta pelo painel.
// Se a URL tiver ?cli=ID, todos os dados da ferramenta ficam
// isolados naquele cliente (prefixo cli:ID: no localStorage)
// e o painel salva na nuvem na tabela rg_dose daquele cliente.
// ============================================================
(function(){
  if (window.self === window.top) {
    try { window.location.replace('../index.html'); } catch(e){}
    return;
  }
  var cli = null;
  try { cli = new URLSearchParams(window.location.search).get('cli'); } catch(e){}
  var PREFIX = cli ? 'cli:' + cli + ':' : '';

  function mapKey(key){
    key = String(key);
    // isola qualquer chave da ferramenta no cliente aberto (D.O.S.E., PEC e futuras)
    if (PREFIX && key.indexOf('cli:') !== 0 && key.indexOf('rgdemo-') !== 0) return PREFIX + key;
    return key;
  }
  function notify(action, key, value){
    try { window.parent.postMessage({ type: 'dose-sync', cli: cli, action: action, key: key, value: value }, '*'); } catch(e){}
  }
  var _set = Storage.prototype.setItem;
  var _get = Storage.prototype.getItem;
  var _remove = Storage.prototype.removeItem;
  Storage.prototype.getItem = function(key){
    if (this === window.localStorage) return _get.call(this, mapKey(key));
    return _get.call(this, key);
  };
  Storage.prototype.setItem = function(key, value){
    if (this === window.localStorage) {
      var mk = mapKey(key);
      _set.call(this, mk, value);
      notify('set', mk, String(value));
    } else { _set.call(this, key, value); }
  };
  Storage.prototype.removeItem = function(key){
    if (this === window.localStorage) {
      var mk = mapKey(key);
      _remove.call(this, mk);
      notify('remove', mk);
    } else { _remove.call(this, key); }
  };
})();
