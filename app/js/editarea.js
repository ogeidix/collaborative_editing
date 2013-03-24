////////////////////////////////////////////////////////////////////////////////////// 
// Editarea object
////////////////////////////////////////////////////////////////////////////////////// 

Editarea = (function() {

	function Editarea(element_id) {
		this.element = $('#'+element_id);
		this.root_id = 'usergenerated'; // using id string because the element is not available in the dom at this point
		this.caret   = false;
	}

  	Editarea.prototype.enable = function(q) {
    	if(q == '?') {
    	  	return this.element.attr("contenteditable")  == 'true';
    	} else {
      		return this.element.attr("contenteditable",true);
    	}
  	}

	Editarea.prototype.disable = function(q) {
	    if(q == '?') { 
      		return this.element.attr("contenteditable")  == 'false';
    	} else {
      		this.element.attr("contenteditable",false);
    	}
  	}

  	Editarea.prototype.save_position = function() {
    	this.caret = this.get_position();
  	}


	Editarea.prototype.restore_position = function(delta) {
	    var sel   = rangy.getSelection();
	    var range = rangy.createRange();
	    var node = XPathHelper.get_node_from_XPath(this.caret.node, $('#'+this.root_id));
	    var offset = this.caret.offset;
	    if(delta && delta.offset){
	      offset = offset + delta.offset
	    }
	    range.setStart(node, offset);
	    range.collapse();
	    sel.setSingleRange(range);
	}

	Editarea.prototype.get_position = function() {
    	var selection = rangy.getSelection();
    	var node = XPathHelper.get_XPath_from_node(selection.anchorNode, this.root_id);
    	var offset = selection.anchorOffset;
    	return { node: node, offset: offset }          
  	}

	Editarea.prototype.refresh = function(doc) {
		this.element.html(doc.content.clone());
  	}  	

	return Editarea;
})();