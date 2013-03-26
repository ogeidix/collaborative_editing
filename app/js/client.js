////////////////////////////////////////////////////////////////////////////////////// 
// Client object
////////////////////////////////////////////////////////////////////////////////////// 
//    Client                open connection and register events handlers
//    Client#send(json)     stringify json and send
//    Client#receive(evt)   incoming messages router
//    Client#close()        send bye and close connection

Client = (function() {

  function Client(username, filename) {
    console.log("[client.js] init");
    var url = 'ws://' + window.location.host + '/client/'+ filename;
    var socketClass = 'MozWebSocket' in window ? MozWebSocket : WebSocket;
    this.connection = new socketClass(url);

    this.editor = new Editor(username, filename, this); 
    this.chat   = new Chat(username, this);
    
    _this = this;         
    $(window).on('beforeunload', function() { _this.close() });    
    this.connection.onmessage = function(evt) { _this.receive(evt) }
    this.connection.onopen = function() {
      _this.send({ action: 'join', user: username });
    }
  }

  Client.prototype.send = function(json) {
    var string = JSON.stringify(json);
    console.log("[client.js] send: ", string);
    this.connection.send(string);
  }

  Client.prototype.receive = function(evt) {
    console.log("[client.js] receive: ", evt.data);
    var obj = $.evalJSON(evt.data);
    if (typeof(obj) != 'object') { return }
    switch(obj['action']) {
      case 'message'   : this.chat.receive_message(obj); break;
      case 'control'   : this.chat.receive_control(obj); break;
      case 'loadfile'  : this.editor.apply_load(obj); break;
      case 'insertion' : this.editor.apply_insert(obj); break;
      case 'deletion'  : this.editor.apply_delete(obj); break;
      case 'lock'      : this.editor.apply_lock(obj); break;
    }
  }

  Client.prototype.close = function() {
    this.send({ action: 'bye' });   
    this.connection.close();
  }

  return Client;
})();
