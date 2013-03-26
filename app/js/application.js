////////////////////////////////////////////////////////////////////////////////////// 
// Collaborative Editor Client
////////////////////////////////////////////////////////////////////////////////////// 
// This file will load all the required components and start the client,
// initializing an object of the Client class.


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

 '/chat.js',
 '/editarea.js',
 '/document.js',
 '/editor.js',
 '/xpathhelper.js',
 '/client.js'];

console.log("[application.js] Init Collaborative Editor Client ");
components.forEach(loadExternalJS);

document.addEventListener('DOMContentLoaded',function(){

    // Show login if browser support WebSocket
    if (typeof(WebSocket) != 'undefined' || typeof(MozWebSocket)) {
      $('#nowebsocket').hide();
      $('#login').show();
    }

    // On click on "join!" start the client
    $('#login form').submit(function() {
      event.preventDefault();
      var username = $('#username').val();
      var filename = $('#filename').val();
      if (username == "" || filename == "") {
          window.alert("Please enter the username and filename !!");
      } else {
          $('#login').hide();
          $('#application').show();
          $('input#message').focus(); 
          client = new Client(username, filename);
      }
      return false;
    });

});