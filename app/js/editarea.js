////////////////////////////////////////////////////////////////////////////////////// 
// Editarea object
////////////////////////////////////////////////////////////////////////////////////// 

Editarea = (function() {

	function Editarea(element_id) {
		this.element = $('#'+element_id);
		this.root_id = 'usergenerated'; // using id string because the element is not available in the dom at this point
		this.caret   = false;
		console.log("[editarea.js] init");
	}

  	Editarea.prototype.enable = function(q) {
    	if(q == '?') {
    	  	return this.element.attr("contenteditable")  == 'true';
    	} else {
    		console.log("[editarea.js] enable editarea");
      		return this.element.attr("contenteditable",true);
    	}
  	}

	Editarea.prototype.disable = function(q) {
	    if(q == '?') { 
      		return this.element.attr("contenteditable")  == 'false';
    	} else {
    		console.log("[editarea.js] disable editarea");
      		this.element.attr("contenteditable",false);
    	}
  	}

  	Editarea.prototype.save_position = function() {
    	this.caret = this.get_position();
		console.log("[editarea.js] save_position: " + this.caret.node + ", " + this.caret.offset);
  	}


	Editarea.prototype.restore_position = function(delta) {
		if (!this.caret.node) { return true; }
		console.log("[editarea.js] restore_position: " + this.caret.node + ", " + this.caret.offset);
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

	Editarea.prototype.refresh = function(doc, obj) {
		this.save_position();
		if(obj){
		  console.log("refresh ", obj);
			if(obj.action=='insertion'){
				if (obj.node == this.caret.node && obj.offset <= this.caret.offset){
					this.caret.offset += obj.changes.length;
				}
			} else if (obj.action=='deletion'){
				if (obj.node == this.caret.node && obj.offset <= this.caret.offset && obj.direction=='left'){
					this.caret.offset -= obj.length;
				} else if (obj.node == this.caret.node && obj.offset < this.caret.offset && obj.direction=='right'){
					this.caret.offset -= obj.length;
				}
			}
		}
		this.element.html(doc.content.clone());
		this.restore_position();
  	}  	

	return Editarea;
})();
