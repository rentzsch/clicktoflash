/*  sIFR Unofficial Rollback addon for sIFR 3
 Modified by Paul Hassinger - hassinger.paul@ipaul.com - http://www.ipaul.com
 (modified from sIFR 2.0.1 Official Add-ons 1.2)
 
 Copyright 2005 Mark Wubben
 
 This software is licensed under the CC-GNU LGPL <http://creativecommons.org/licenses/LGPL/2.1/>
 */

if(typeof sIFR == "object"){
    sIFR.rollback = function(){
        function rollback(sSelector){
            if(sSelector == null){
                sSelector = "";
            } else {
                sSelector += ">";
            };
			
            sIFR.removeFlashClass();
			
            if(doRollback(sSelector+"embed") == false){
                doRollback(sSelector+"object");
            };
        };
		
        function doRollback(sSelector){
            var node, nodeParent, nodeAlternate, nodeAlternateChild, nodeAlternateNextChild, indexNodeToRemove;
            var listNodes = parseSelector(sSelector);
            var i = listNodes.length - 1;
            var bHasRun = false;
			
            while(i >= 0){
                node = listNodes[i];
                listNodes.length--;
                nodeParent = node.parentNode;
				
                if(node.className == 'sIFR-flash'){
                    /*  Flash blockers may add other nodes as siblings to the Flash element. 
					 Thus, we remove all children of nodeParent, and look for nodeAlternate at the same time */
                    indexNodeToRemove = 0;
					
                    while(indexNodeToRemove < nodeParent.childNodes.length){
                        node = nodeParent.childNodes[indexNodeToRemove];
                        if(node.className == "sIFR-alternate"){
                            nodeAlternate = node;
                            indexNodeToRemove++;
                            continue;
                        };
                        nodeParent.removeChild(node);
                    };
					
                    if(nodeAlternate != null){
                        nodeAlternateChild = nodeAlternate.firstChild;
                        while(nodeAlternateChild != null){
                            nodeAlternateNextChild = nodeAlternateChild.nextSibling;
                            nodeParent.appendChild(nodeAlternate.removeChild(nodeAlternateChild));
                            nodeAlternateChild = nodeAlternateNextChild;
                        };
                        nodeParent.removeChild(nodeAlternate);
                    };
					
                    nodeParent.className = nodeParent.className.replace(/\bsIFR\-replaced\b/, "");
                    bHasRun = true;
                };
				
                i--;
            };
			
            return bHasRun;
        };
		
        return rollback;
    }();
};
