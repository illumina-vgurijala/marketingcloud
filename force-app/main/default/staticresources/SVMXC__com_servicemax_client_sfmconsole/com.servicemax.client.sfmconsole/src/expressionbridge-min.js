(function(){var a=SVMX.Package("com.servicemax.client.sfmconsole.expressionbridge");a.init=function(){if(window.$EXPR==undefined||window.$EXPR==null){window.$EXPR={};}$EXPR.SVMXEvalExpression=function(e,c,b,d){setTimeout(function(){var f={callbackHandler:b,callBackContext:d,handler:function(h){this.callbackHandler.call(this.callBackContext,h);}};try{$EXPR.executeExpression(e,c,f.handler,f,true);}catch(g){$EXPR.Logger.error("Error while performing EVAL! Please check for syntax error in the JS snippet! =>"+g);f.handler(c);}},0);};$EXPR.showMessage=function(b){SVMX.getCurrentApplication().getApplicationMessageUIHandler().showMessage(b);};};})();