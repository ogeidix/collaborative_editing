//////////////////////////////////////////////////////////////////////////////////////
// XPathHelper module
//////////////////////////////////////////////////////////////////////////////////////
//  XpathHelper.get_XPath_from_node(node, root_id)    return XPath for node up to root_id
//  XpathHelper.get_node_from_XPath(xpath, root_id)   return node from XPath 


XPathHelper = {

  get_XPath_from_node: function(node, root_id) {
    if (node.id == root_id) { return '/' }
    if (node.parentNode == null) return false
    var sibling_index = 0;
    var siblings = node.parentNode.childNodes;
    for (var i= 0; i<siblings.length; i++) {
      var sibling = siblings[i];
      if (sibling === node){
        var parent = this.get_XPath_from_node(node.parentNode, root_id);
        if (parent) {
          return parent +'/'+ node.nodeName.toLowerCase() +'['+ (sibling_index+1) +']';
        } else {
          return false;
        }
      } else if ((sibling.nodeType === 1 || sibling.nodeType === 3) && sibling.nodeName === node.nodeName) {
          sibling_index++;
      }
    }
  },

  get_node_from_XPath: function(xpath, parent) {
    var element = parent;
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