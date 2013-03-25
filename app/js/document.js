////////////////////////////////////////////////////////////////////////////////////// 
// Document object
////////////////////////////////////////////////////////////////////////////////////// 

Document = (function() {

	function Document(content, version) {
		console.log("[document.js] init");
		this.content = $(content);
		this.version = version;
		this.root_id = 'usergenerated'; // using id string because the element is not available in the dom at this point
	}

  	Document.prototype.apply_insert = function(obj) {
	    var edit = obj['changes'];
	    var offset = parseInt(obj['offset']);
	    var node = XPathHelper.get_node_from_XPath(obj['node'], $(this.content[0]));
	    node.nodeValue = node.nodeValue.substring(0, offset) + edit + node.nodeValue.substr(offset);
	    this.version = obj['version']+1;
	}

	Document.prototype.apply_delete = function(obj) {
	    var offset = parseInt(obj['offset']);
	    var direction = obj['direction'];
	    var length = obj['length'];
	    var node = XPathHelper.get_node_from_XPath(obj['node'], $(this.content[0]));
	    if(direction == 'left') {
	    	node.nodeValue = node.nodeValue.substring(0, offset - length) + node.nodeValue.substr(offset);
	    } else {
	    	node.nodeValue = node.nodeValue.substring(0, offset) + node.nodeValue.substr(offset + length);
	    }
	    this.version = obj['version']+1; 
	}

	return Document;
})();
