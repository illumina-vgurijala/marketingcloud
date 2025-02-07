/**
 * This is the core implementation of the expression engine which is consumer neutral
 * 
 * @author Indresh MS
 */

(function(){
	if(window.$EXPR == undefined || window.$EXPR == null) window.$EXPR = {};
	
	// set up logging console
	try{
		if( !window.console ) {
			window.console = {
					log : function() {},
					error : function() {},
					info : function() {},
					warn : function() {}
			};
		}
	}catch(e) { }
	
	// IE !
	if( !window.console.debug ) window.console.debug = function(msg){
		window.console.info("DEBUG" + msg);
	}
	// end - set up logging console
	
	/**
	 * The expression engine implementation class
	 */
	var JSEE = function(){
		
		/**
		 * The core internal API method to evaluate the JS expression
		 * !!! Note the right now, this method works on single context. In future, it may 
		 * !!! support multiple contexts via context roots mechanism ($D for data for example) 
		 * 
		 * @param expr String the expression that needs to be evaluated
		 * @param context Object the contextual data that this expression works on
		 * @param callback Function the function to be invoked to present the result
		 * @param callbackContext Object the object on which the callback function exists
		 * @param async Boolean true if the expression results in an asynchronous behavior, false otherwise
		 */
		this.evalExpression = function(expr, context, callback, callbackContext, async){
			var result = null, bReturned = false;;
			(function (expr, context, callback, callbackContext, async){
				
				function $ADD(a, b){ return a + b; };
				function $SUB(a ,b){ return a - b; };
				function $ISNULL(a){ if(a) return true; else return false; };
				function $BOOL(a){ return !!a; };
				
				function $SORT(items, fieldOrFunc){
					// right now, only field name is supported
					if(typeof(fieldOrFunc) != 'string') return;
					
					var i, l = items.length;
					
					if(l < 2) return items;
					
					for(i = 0; i < (l - 1);){
						var k = 0;
						for(; k < (l - 1); k++){
							if(items[k][fieldOrFunc] > items[k+1][fieldOrFunc]){
								var temp   = items[k];
								items[k]   = items[k+1];
								items[k+1] = temp; 
							}
						}
						l--;
					}
					return items;
				};
				
				// always assumes that this is invoked as part of asynchronous calls
				function $RETURN(value){
					
					// it is not allowed to return twice in the same expression
					if(bReturned) throw new Error("Attempted to RETURN twice in the same expression!");
					
					bReturned = true;
					callback.call(callbackContext, value);
				}
				
				function $FORMAT(){
					if(arguments.length == 0 ) return "";
					
					var formatted = arguments[0];	// first parameter is the string to be formated
					
				    for (var i = 1; i < arguments.length; i++) {
				        var regexp = new RegExp('\\{'+ (i - 1) +'\\}', 'gi');
				        formatted = formatted.replace(regexp, arguments[i]);
				    }
				    return formatted;
				}
				
				context = $EXPR.toObject(context);
	
				result = eval(expr);
			})(expr, context, callback, callbackContext, async);
			
			// invoke the call back immediately if this is not an asynchronous call
			if(!async){
				callback.call(callbackContext, result);
			}		
			
			// return the result anyways
			return result;
		};
	};
	
	/**
	 * The external API method to be consumed by the respective bridges
	 */
	$EXPR.executeExpression = function(expr, context, callback, callbackContext, async){
		var jsel = new JSEE();;
		var ret = jsel.evalExpression(expr, context, callback, callbackContext, async);
		return ret;	
	};
	
	$EXPR.toJSON = function(data){
		if(data){
			return $.toJSON(data);
		}
		return null;
	};
	
	$EXPR.toObject = function(data){
		if(typeof(data) == 'string')
			return $.secureEvalJSON(data);
		else
			return data;
	};
	
	$EXPR.ajax = function(options){
		return $.ajax(options);
	};
	
	$EXPR.Logger = {
		log : function(msg){
			window.console.log(this.message(msg));
		},
		
		error : function(msg){
			window.console.error(this.message(msg));
		},
		
		warn : function(msg){
			window.console.warn(this.message(msg));
		},
		
		debug : function(msg){
			window.console.debug(this.message(msg));
		},
		
		info : function(msg){
			window.console.info(this.message(msg));
		},
		
		message : function(msg){
			return "SVMX JS BRIDGE: " + msg;
		}
	};
})();

// end of file