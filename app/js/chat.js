////////////////////////////////////////////////////////////////////////////////////// 
// Chat object
////////////////////////////////////////////////////////////////////////////////////// 
//    Chat                         add the event handler for the chat input box
//    Chat#receive_*               methods that receive remote messages, called by client#onmessage event handler
//      Chat#receive_message(obj)  receive a chat message from another user
//      Chat#receive_control(obj)  receive a chat "control" from the server

Chat = (function() {

	function Chat(username, client) {
		this.socket   = client;
		this.username = username;
		this.container = $('div#msgs');

		$('#channel form').submit(function(event) {
	      event.preventDefault();
	      var input = $(this).find(':input');
	      var msg = input.val();
	      this.socket.send($.toJSON({ action: 'message', message: msg }));
	      input.val('');
    	});
	}


	 Chat.prototype.receive_message = function(obj) {
	        var struct = this.container.find('li.' + 'message' + ':first');
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
	        this.container.find('ul').append(msg.show());
	        this.container.scrollTop(this.container.find('ul').innerHeight());
	  }


	  Chat.prototype.receive_control = function(obj) {
	        var struct = this.container.find('li.' + 'control' + ':first');
	        var msg = struct.clone();
	        msg.find('.time').text((new Date()).toString("HH:mm:ss"));
	        msg.find('.user').text(obj['user']);
	        msg.find('.message').text(obj['message']);
	        msg.addClass('control');
	        if (obj['user'] == this.username) msg.find('.user').addClass('self');
	        this.container.find('ul').append(msg.show());
	        this.container.scrollTop(this.container.find('ul').innerHeight());
	  }

	return Chat;
})();