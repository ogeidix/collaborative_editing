////////////////////////////////////////////////////////////////////////////////////// 
// Document object
////////////////////////////////////////////////////////////////////////////////////// 

Document = (function() {

	function Document(content, version) {
		this.content = content;
		this.version = version;
	}

  	Document.prototype.apply_insert = function(obj) {
	    var edit = obj['changes'];
	    var offset = parseInt(obj['y']);
	    var node = XPathHelper.get_node_from_XPath(obj['node'], this.root_id);
	    node.nodeValue = node.nodeValue.substring(0, offset) + edit + node.nodeValue.substr(offset);
	    this.document_version = obj['version'];
	}

	Document.prototype.apply_delete = function(obj) {
	    var offset = parseInt(obj['y']);
	    var direction = obj['direction'];
	    var length = obj['length'];
	    var node = XPathHelper.get_node_from_XPath(obj['node'], this.root_id);
	    if(direction == 'left') {
	    	node.nodeValue = node.nodeValue.substring(0, offset - length) + node.nodeValue.substr(offset);
	    } else {
	    	node.nodeValue = node.nodeValue.substring(0, offset) + node.nodeValue.substr(offset + length);
	    }
	    this.document_version = obj['version']; 
	}

	return Document;
})();