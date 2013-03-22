// Socket object
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
      case 'lock'     : this.handler.lock(obj); break;
    }
  }

  Socket.prototype.close = function() {
    this.send({ action: 'bye' });   
    this.connection.close();
  }

  return Socket;
})();

////////////////////////////////////////////////////////////////////////////////////// 

// Editor object
//    Editor                        open socket connection and register events handlers
//    Editor#apply_*                methods that apply remote changes, called by socket#onmessage event handler
//        Editor#apply_load(obj)    load remote file into the editor
//        Editor#apply_insert(obj)  apply remote insert
//        Editor#apply_delete(obj)  apply remote delete
//    Editor#send_*                 send local changes
//        Editor#send_insert(evt)   send insert
//        Editor#send_delete(key)   send delete, key is event.keyCode (needed for delete direction)
//        Editor#send_relocate(evt) send cursor relocation
//    Editor#get_location           utility, return current node and offset
//    Editor#lock(obj)              manage remote locks
//    Editor#enable                 utility, enable editor (if called with argument '?' return editor status as bool)
//    Editor#disable                utility, opposite of enable

Editor = (function() {

  function Editor(username, filename) {          
    this.editor = $('#editor');
    this.root_id = 'usergenerated'; // using id string because the element is not available in the dom at this point
    this.document_version = 0;
    this.username = username;    
    this.filename = filename;
    url = 'ws://' + window.location.host + '/client/'+ filename;    

    var _this = this;
    
    this.socket = new Socket(url, _this);
    this.socket.connection.onopen = function() {
      _this.socket.send({ action: 'join', user: username });
    }

    // events handlers
    this.editor.on('click', function() { _this.send_relocate() });
    this.editor.on('keypress', function(evt) { _this.send_insert(evt) });
    this.editor.on('keyup', function(evt) {  
      key = evt.keyCode;
      if(key == 37 || key == 38 || key == 39 || key == 40) { _this.send_relocate() } // arrows keys
      if(key == 8 || key == 46) { _this.send_delete(key) } // backspace and canc
    });
    this.editor.on('keydown', function(evt) {
      key = evt.keyCode;
      if(key == 13) { return false } // disable enter key
    });

    $('#channel form').submit(function(event) {
      event.preventDefault();
      var input = $(this).find(':input');
      var msg = input.val();
      _this.socket.connection.send($.toJSON({ action: 'message', message: msg }));
      input.val('');
    });

  }
  

  Editor.prototype.chat_message = function(obj) {
        var container = $('div#msgs');
        var struct = container.find('li.' + 'message' + ':first');
        var msg = struct.clone();
        msg.find('.time').text((new Date()).toString("HH:mm:ss"));
        var matches;
        if (matches = obj['message'].match(/^\s*[\/\\]me\s(.*)/)) {
          msg.find('.user').text(obj['user'] + ' ' + matches[1]);
          msg.find('.user').css('font-weight', 'bold');
        } else {
          msg.find('.user').text(obj['user']);
          msg.find('.message').text(': ' + obj['message']);
        }
        if (obj['user'] == this.username) msg.find('.user').addClass('self');
        container.find('ul').append(msg.show());
        container.scrollTop(container.find('ul').innerHeight());
  }


  Editor.prototype.chat_control = function(obj) {
            var container = $('div#msgs');
        var struct = container.find('li.' + 'control' + ':first');
        var msg = struct.clone();
        msg.find('.time').text((new Date()).toString("HH:mm:ss"));
        msg.find('.user').text(obj['user']);
        msg.find('.message').text(obj['message']);
        msg.addClass('control');
        if (obj['user'] == this.username) msg.find('.user').addClass('self');
        container.find('ul').append(msg.show());
        container.scrollTop(container.find('ul').innerHeight());
  }

  Editor.prototype.apply_load = function(obj) {
    this.editor.html(obj['content']);
    this.documentVersion = obj['version'];
  } 

  Editor.prototype.apply_insert = function(obj) {
    var remote_username = obj['user'];
    if (remote_username != this.username) {
      var edit = obj['changes'];
      var offset = parseInt(obj['y']);
      var node = XPathHelper.get_node_from_XPath(obj['node'], this.root_id);
      //if (edit == '\n') {
      //  edit = document.createElement('br');
      //  suffix = document.createTextNode(node.nodeValue.substr(offset));                                  
      //  parent = node.parentNode
      //  node.nodeValue = node.nodeValue.substring(0, offset)
      //  parent.insertBefore(edit, node.nextSibling)
      //  parent.insertBefore(suffix, edit.nextSibling)
      //} else {
        node.nodeValue = node.nodeValue.substring(0, offset) + edit + node.nodeValue.substr(offset);
      //}
    }
    this.document_version = obj['version'];          
  }

  Editor.prototype.apply_delete = function(obj) {
    var remote_username = obj['user'];
    if (remote_username != this.username){
      var offset = parseInt(obj['y']);
      var direction = obj['direction'];
      var length = obj['length'];
      var node = XPathHelper.get_node_from_XPath(obj['node'], this.root_id);
      if(direction == 'left') {
        node.nodeValue = node.nodeValue.substring(0, offset - length) + node.nodeValue.substr(offset);
      } else {
        node.nodeValue = node.nodeValue.substring(0, offset) + node.nodeValue.substr(offset + length);
      }
    }
    this.document_version = obj['version']; 
  }

  Editor.prototype.send_insert = function(evt) {
    var position = this.get_position();
    var edit = String.fromCharCode(evt.charCode);
    var json = {"action":"insert", "node": position['node'], "y": position['offset'], "version": this.document_version, "changes": edit};
    this.socket.send(json);
  }

  Editor.prototype.send_delete = function(key) {
    var position = this.get_position();
    var length = 1;
    var json; 
    if(key == 8) { // backspace, left-delete 
      json = {"action":"delete", "node": position['node'], "y": position['offset'] + 1, "version": this.document_version, "direction": "left", "length": length};
    }
    if (key == 46) { // canc, righ-delete
      var json = {"action":"delete", "node": position['node'], "y": position['offset'], "version": this.document_version, "direction": "right", "length": length};
    }              
    this.socket.send(json);
  }

  Editor.prototype.send_relocate = function(evt) {
    if (this.disable('?')) { return false }
    position = this.get_position();
    var json = {"action":"relocate", "node": position['node'], "y": position['offset'], "version": this.document_version };
    this.socket.send(json);
    this.disable();
  }

  Editor.prototype.get_position = function() {
    var selection = rangy.getSelection();
    var node = XPathHelper.get_XPath_from_node(selection.anchorNode, this.root_id);
    var offset = selection.anchorOffset;
    return { node: node, offset: offset }          
  }

  Editor.prototype.lock = function(obj) {
    about = obj['about'];
    granted = obj['granted'];
    if (about == 'relocate' && granted) { this.enable() }
    if (about == 'relocate' && !granted) { this.disable(); window.alert("conflict position! please choose another position") }
  }
 
  Editor.prototype.enable = function(q) {
    if(q == '?') {
      return this.editor.attr("contenteditable");
    } else {
      this.editor.attr("contenteditable",true);
    }
  }

  Editor.prototype.disable = function(q) {
    if(q == '?') { 
      return !this.editor.attr("contenteditable");
    } else { 
      this.editor.attr("contenteditable",false);
    }
  }

  return Editor;

})();

//////////////////////////////////////////////////////////////////////////////////////

// XPathHelper module
//  XpathHelper.get_XPath_from_node(node, root_id)    return XPath for node up to root_id
//  XpathHelper.get_node_from_XPath(xpath, root_id)   return node from XPath 


XPathHelper = {

  get_XPath_from_node: function(node, root_id) {
    if (node.id == root_id) { return '/' }
    var sibling_index = 0;
    var siblings = node.parentNode.childNodes;
    for (var i= 0; i<siblings.length; i++) {
      var sibling = siblings[i];
      if (sibling === node){
        return this.get_XPath_from_node(node.parentNode, root_id)+'/'+ node.nodeName.toLowerCase() +'['+ (sibling_index+1) +']';
      } else if ((sibling.nodeType === 1 || sibling.nodeType === 3) && sibling.nodeName === node.nodeName) {
          sibling_index++;
      }
    }
  },

  get_node_from_XPath: function(xpath, root_id) {
    var element = $('#' + root_id);
    if (xpath == '') { return element[0] }

    xpath = xpath.split('/');
    xpath.splice(0,2); // remove double-slash at the beginning
    
    for(i=0; i<xpath.length; i++) {
      var token = xpath[i].split('[');
      var node = token[0];
      index = parseInt(token[1].substring(0, token[1].length)) - 1; // stupid XPath indexes begins at 1
      if(i != xpath.length - 1) { // first n-1 nodes are just tags, it's easy to build the tree
        element = element.children(node).eq(index); 
      } else { // last node is the text node 
        element = element.contents().filter(function() { return this.nodeName == node }).eq(index);
        return element[0]; // return js object unwrapped from jquery container
      }
    }
  }

}