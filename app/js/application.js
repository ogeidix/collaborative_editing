////////////////////////////////////////////////////////////////////////////////////// 
// Collaborative Editor Client
////////////////////////////////////////////////////////////////////////////////////// 

function loadExternalJS(file) {
    console.log("[application.js] loading " + file);
    // Use of document.writeln and not DOM function to enforce order of execution
    document.writeln("<script type='text/javascript' src='/js"+file+"'></script>");
}

var components = 
['/lib/date.js',
 '/lib/jquery-1.9.1.min.js',
 '/lib/jquery.json-2.2.min.js',
 '/lib/rangy-core.js',

 '/socket.js',
 '/chat.js',
 '/editarea.js',
 '/document.js',
 '/editor.js',
 '/xpathhelper.js'];

console.log("[application.js] Init Collaborative Editor Client ");
components.forEach(loadExternalJS);
document.addEventListener('DOMContentLoaded',function(){

    // Show login if browser support WebSocket
    if (typeof(WebSocket) != 'undefined' || typeof(MozWebSocket)) {
      $('#nowebsocket').hide();
      $('#login').show();
    }

    // join on click
    $('#login form').submit(function() {
      if ($('#username').val() == "" || $('#filename').val() == "") {
          window.alert("Please enter the username and filename !!");
      } else {
          $('#login').hide();
          $('#application').show();
          $('input#message').focus();
          username = $('#username').val();
          filename = $('#filename').val();
          editor = new Editor(username, filename);
      }
      return false;
    });

});