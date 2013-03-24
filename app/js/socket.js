////////////////////////////////////////////////////////////////////////////////////// 
// Socket object
////////////////////////////////////////////////////////////////////////////////////// 
//    Socket                open connection and register events handlers
//    Socket#send(json)     stringify json and send
//    Socket#receive(evt)   incoming messages handler
//    Socket#close()        send bye and close connection

Socket = (function() {

  function Socket(url, handler) {
    var socketClass = 'MozWebSocket' in window ? MozWebSocket : WebSocket;
    this.connection = new socketClass(url);
    this.handler = handler; 
    _this = this;         
    this.connection.onmessage = function(evt) { _this.receive(evt) }
    $(window).on('beforeunload', function() { _this.close() });
  }

  Socket.prototype.send = function(json) {
    var string = JSON.stringify(json);
    console.log(string)
    this.connection.send(string);
  }

  Socket.prototype.receive = function(evt) {
    var obj = $.evalJSON(evt.data);
    if (typeof(obj) != 'object') { return }
    switch(obj['action']) {
      case 'message'  : this.handler.chat_message(obj); break;
      case 'control'  : this.handler.chat_control(obj); break;
      case 'loadfile' : this.handler.apply_load(obj); break;
      case 'insert'   : this.handler.apply_insert(obj); break;
      case 'delete'   : this.handler.apply_delete(obj); break;
      case 'lock'     : this.handler.unlock(obj); break;
    }
  }

  Socket.prototype.close = function() {
    this.send({ action: 'bye' });   
    this.connection.close();
  }

  return Socket;
})();
