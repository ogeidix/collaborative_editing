////////////////////////////////////////////////////////////////////////////////////// 
// Editor object
////////////////////////////////////////////////////////////////////////////////////// 
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
    
    this.lock_about = ''
    this.username = username;    
    this.filename = filename;
    url = 'ws://' + window.location.host + '/client/'+ filename;

    this.doc      = false;
    this.editarea = new Editarea('editor');
    this.chat     = new Chat(username);
    this.socket   = new Socket(url, this, this.chat);

    var _this = this;
    this.socket.connection.onopen = function() {
      _this.socket.send({ action: 'join', user: username });
    }

    // events handlers
    this.editor = $('#editor');

    this.editor.on('mousedown', function() {      if(_this.editarea.disable('?')) { return false } });

    this.editor.on('click', function() { _this.send_relocate() });

    this.editor.on('keypress', function(evt) { _this.send_insert(evt) });

    this.editor.on('keydown', function(evt) {
      if(_this.editarea.disable('?')) { return false }
      key = evt.keyCode;
      if(key == 13) { return false } // disable enter key
      if(key == 37 || key == 38 || key == 39 || key == 40) { _this.send_relocate() } // arrows keys
      if(key == 8 || key == 46) { _this.send_delete(key) } // backspace and canc
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

  Editor.prototype.send_insert = function(evt) {
    var position = this.editarea.get_position();
    this.lock('insert');
    var edit = String.fromCharCode(evt.charCode);
    var json = {"action":"insertion", "node": position['node'], "offset": position['offset'], "version": this.doc.version, "changes": edit};
    this.socket.send(json);
    return false;
  }

  Editor.prototype.send_delete = function(key) {
    this.lock('delete');
    var position = this.editarea.get_position();
    var length = 1;
    var json; 
    if(key == 8) { // backspace, left-delete 
      json = {"action":"delete", "node": position['node'], "offset": position['offset'], "version": this.doc.version, "direction": "left", "length": length};
    }
    if (key == 46) { // canc, righ-delete
      var json = {"action":"delete", "node": position['node'], "offset": position['offset'], "version": this.doc.version, "direction": "right", "length": length};
    }              
    this.socket.send(json);
    return false;
  }

  Editor.prototype.send_relocate = function(evt) {
    if (this.editarea.disable('?')) { return false }
    position = this.editarea.get_position();
    var json = {"action":"relocate", "node": position['node'], "offset": position['offset'], "version": this.doc.version };
    this.socket.send(json);
    this.lock('relocate');
  }

  Editor.prototype.lock = function(reason) {
    this.editarea.save_position();
    this.lock_about = reason;
    this.editarea.disable();
  }

  Editor.prototype.unlock = function(obj) {    
    about = obj['about'];
    granted = obj['granted'];
    // if (about == 'change' && granted) {
    //   this.restore_position({offset: 1})
    // } else {
    this.editarea.restore_position()
    // }
    if (about == this.lock_about && granted) { this.editarea.enable() }
    if (about == this.lock_about && !granted) { this.editarea.disable(); window.alert("conflict position! please choose another position") }
  }

  return Editor;
})();

