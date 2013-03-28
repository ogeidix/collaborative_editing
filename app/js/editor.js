////////////////////////////////////////////////////////////////////////////////////// 
// Editor object
////////////////////////////////////////////////////////////////////////////////////// 
// This object take care of the logic of the client managing the
// user input and the messages coming from the server.
//
//    Editor                        register events handlers
//    Editor#apply_*                methods that apply remote changes, called by client#onmessage event handler
//        Editor#apply_load(obj)    load remote file into the editor
//        Editor#apply_insert(obj)  apply remote insert
//        Editor#apply_delete(obj)  apply remote delete
//        Editor#apply_lock(obj)    apply (un)lock messages
//    Editor#send_*                 send local changes
//        Editor#send_insert(evt)   send insert
//        Editor#send_delete(key)   send delete, key is event.keyCode (needed for delete direction)
//        Editor#send_relocate(evt) send cursor relocation
//    Editor#lock(reason)              lock the editor for 'reason'


Editor = (function() {

  function Editor(username, filename, client) {
    
    this.socket   = client;
    this.username = username;    
    this.filename = filename;

    this.lock_about    = ''
    this.ignore_events = false;
    this.doc           = false;
    this.editarea      = new Editarea('editor');

    // ----------------- Event Handlers -----------------
    var _this = this;
    this.editor = $('#editor');

    // ___ MOUSE ___
    this.editor.on('mousedown', function() {      
      if(_this.editarea.disable('?')) { return false }
      _this.ignore_events = true;
      _this.editarea.save_position();
    });

    this.editor.on('mouseup', function() { _this.send_relocate(); });

    // ___ ASCII CHARACTERS ___
    this.editor.on('keypress', function(evt) { _this.send_insert(evt) });

    // ___ SPECIAL KEYS ___
    this.editor.on('keydown', function(evt) {
      if(_this.editarea.disable('?') || _this.ignore_events==true) { return false }
      _this.ignore_events = true;
      var key = evt.keyCode;
      // ___ Space ___ ignore if the previous or follow char is a space
      if(key == 32) {   // TODO handle multiple space
        var pos = _this.editarea.get_position();
        var node = (XPathHelper.get_node_from_XPath(pos.node, $('#usergenerated')));
        if ( pos.offset == 0 ||
             node.nodeValue.substring(pos.offset-1, pos.offset)==' ' ||
             node.nodeValue.substring(pos.offset, pos.offset+1)==' '){
          return false;
        }
        if (pos.offset < node.nodeValue.l && node.nodeValue.substring(pos.offset-1, pos.offset)==' '){
          return false;
        }
      }
      // ___ New Line ___ ignore it. TODO handle new line
      if(key == 13) {
        return false
      }
      // ___ Arrows ___ handle like a "mouseDOWN"
      if(key == 37 || key == 38 || key == 39 || key == 40) {
        _this.editarea.save_position();
      }
      // ___ Delete and backspace ___
      if(key == 8 || key == 46) {
        return _this.send_delete(key)
      }
    });

    // ___ Arrows ___ handle like a "mouseUP"
    this.editor.on('keyup', function(evt){
      var key = evt.keyCode;
      if(key == 37 || key == 38 || key == 39 || key == 40) {
        _this.send_relocate();
      }
    }); 

  }
  
  Editor.prototype.apply_load = function(obj) {
    this.doc = new Document(obj['content'], obj['version']);
    this.editarea.refresh(this.doc);
  } 

  Editor.prototype.apply_insert = function(obj) {
    this.doc.apply_insert(obj);
    this.editarea.refresh(this.doc, obj);
  }

  Editor.prototype.apply_delete = function(obj) {
    this.doc.apply_delete(obj);
    this.editarea.refresh(this.doc, obj);
  }

  Editor.prototype.apply_lock = function(obj) {    
    if (obj['granted']) {
      if (obj['about'] == 'relocate') { this.editarea.restore_position(); }
    }else{
      window.alert("Conflict during: " + obj['about'] + "!\nChoose another position");
    }
    this.editarea.enable();
    this.ignore_events = false;
  }

  Editor.prototype.send_insert = function(evt) {
    this.editarea.save_position();
    var position = this.editarea.get_position();
    this.lock('insertion');
    var edit = String.fromCharCode(evt.charCode);
    var json = {"action":"insertion", "node": position['node'], "offset": position['offset'], "version": this.doc.version, "content": edit};
    this.socket.send(json);
    return false;
  }

  Editor.prototype.send_delete = function(key) {
    console.log("[editor] send deletion");
    var position = this.editarea.get_position();
    var length = 1;
    var direction; 
    if(key == 8) { // backspace, left-delete 
      direction = "left";      
    } else if (key == 46) { // canc, righ-delete
      direction = "right"
    }
    var node = (XPathHelper.get_node_from_XPath(position.node, $('#usergenerated')));
    // Ignore deletion which will cause a change in the structure. TODO: handle deletion in case of changes in the structure.
    if((direction == "left" && position.offset == 0) || (direction == "right" && position.offset == node.nodeValue.length)){
      return false; 
    }
    this.editarea.save_position();
    this.lock('deletion');
    var json = json = {"action":"deletion", "node": position['node'], "offset": position['offset'], "version": this.doc.version, "direction": direction, "length": length};
    this.socket.send(json);
    return false;
  }

  Editor.prototype.send_relocate = function(evt) {
    console.log("[editor] send relocate");
    position = this.editarea.get_position();
    this.editarea.save_position();
    this.editarea.restore_position('old');
    this.lock('relocate');
    var json = {"action":"relocate", "node": position['node'], "offset": position['offset'], "version": this.doc.version };
    this.socket.send(json);
  }

  Editor.prototype.lock = function(reason) {
    this.lock_about = reason;
    this.editarea.disable();
    this.ignore_events = true;
  }

  return Editor;
})();

