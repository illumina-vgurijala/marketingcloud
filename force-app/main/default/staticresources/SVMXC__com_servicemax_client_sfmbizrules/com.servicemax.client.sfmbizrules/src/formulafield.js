/**
 * This file needs a description
 * @class com.servicemax.client.sfmbizrules.jsel
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var ffImpl = SVMX.Package("com.servicemax.client.sfmbizrules.formulafield");
	var datetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;

	ffImpl.Class("FormulaFieldEngine", com.servicemax.client.lib.api.Object, {
		__constructor : function() {},

		initialize : function(params){
			var me = this;

			// set up the context roots
			var props = {};
			var i = 0, cr = params.contextRoots, l = cr.length;
			for(i = 0; i < l; i++){
				eval("var " + cr[i] + " = {};");
			}

			this.addContext = function(context, root){
				var r = eval(root);
				for(var name in context){
					var value = context[name];
					r[name] = value;
				}
			};

			this.updateValue = function(alias, field, value){
				if($D[alias] && field in $D[alias]){
					$D[alias][field] = value;
				}
			}

			this.getContext = function(alias){
				return $D[alias];
			}

			this.setProperty = function(key, value) {
				props[key] = value;
			};

			this.getProperty = function(key) {
				return props[key];
			};

			this.resolveFormula = function(expr, params){

				// Math Operators
				function $ADD(val1, val2){
					return $FLOAT(val1) + $FLOAT(val2);
				}

				function $SUBTRACT(val1, val2){
					return $FLOAT(val1) - $FLOAT(val2);
				}

				function $MULTIPLY(val1, val2){
					return $FLOAT(val1) * $FLOAT(val2);
				}

				function $DIVIDE(val1, val2){
					return $FLOAT(val1) / $FLOAT(val2);
				}

				function $FLOAT(value){
					var parsedValue = parseFloat(value);
					if(isNaN(parsedValue)) parsedValue = 0;
					return parsedValue;
				}

				function isDate( d ){
					var regExpr = /((?:(?:[1]{1}\d{1}\d{1}\d{1})|(?:[2]{1}\d{3}))[-:\/.](?:[0]?[1-9]|[1][012])[-:\/.](?:(?:[0-2]?\d{1})|(?:[3][01]{1})))(?![\d])/;
					return regExpr.test( d.toString() );
				}

				function isNumber( n ) {
					if(!n) return false;
					if( isDate(n) ) return false;
					var regExpr = /^-?(\d+\.?\d*)$|(\d*\.?\d+)$/;
					return regExpr.test( n.toString() );
				}

				// Logical Operators

				function $EQUAL(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) === $FLOAT(val2);
					}
					if(typeof val1 === typeof val2)
						return val1 === val2;
					else if (typeof val1 === "boolean" || typeof val2 === "boolean") {
						val2 = Boolean(val2);
						val1 = Boolean(val1);
						return val1 === val2;
					}else {
						return val1 === val2;
					}
				}

				function $NOTEQUAL(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) !== $FLOAT(val2);
					}
					return val1 !== val2;
				}

				function $LESSTHAN(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) < $FLOAT(val2);
					}
					return val1 < val2;
				}

				function $GREATERTHAN(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) > $FLOAT(val2);
					}
					return val1 > val2;
				}

				function $LESSTHANEQUAL(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) <= $FLOAT(val2);
					}
					return val1 <= val2;
				}

				function $GREATERTHANEQUAL(val1, val2){
					if(isNumber(val1) && isNumber(val2)){
						return $FLOAT(val1) >= $FLOAT(val2);
					}
					return val1 >= val2;
				}

				//Date Functions

				function $DATE(year, month, day){
					if(!year || !month || !day) return "";
					var expression = ("0000" + year).slice(-4) + "-" + ("00" + month).slice(-2) + "-" + ("00" + day).slice(-2);
					return datetimeUtils.getFormattedDatetime(expression, datetimeUtils.getSaveFormat("date"));
				}

				function $DATEVALUE(expression){
					if(!expression) return "";
					return datetimeUtils.getFormattedDatetime(expression, datetimeUtils.getSaveFormat("date"));
				}

				function $DATETIMEVALUE(expression){
					if(!expression) return "";
					return datetimeUtils.getFormattedDatetime(expression, datetimeUtils.getSaveFormat("datetime"));
				}

				function $DAY(date){
					if(!date) return "";
					date = datetimeUtils.getFormattedDatetime(date, datetimeUtils.getSaveFormat("date"));
					return datetimeUtils.parseDate(date).getDate();
				}

				function $MONTH(date){
					if(!date) return "";
					date = datetimeUtils.getFormattedDatetime(date, datetimeUtils.getSaveFormat("date"));
					return datetimeUtils.parseDate(date).getMonth() + 1;
				}

				function $YEAR(date){
					if(!date) return "";
					date = datetimeUtils.getFormattedDatetime(date, datetimeUtils.getSaveFormat("date"));
					return datetimeUtils.parseDate(date).getFullYear();
				}

				function $TODAY(){
					var res = datetimeUtils.macroDrivenDatetime('Today', "YYYY-MM-DD", "HH:mm:ss");
					res = datetimeUtils.getFormattedDatetime(res, datetimeUtils.getSaveFormat("date"));
					return res;
				}

				function $NOW(){
					var res = datetimeUtils.getCurrentDatetime(datetimeUtils.getSaveFormat("datetime"));
					res = datetimeUtils.getFormattedDatetime(res, datetimeUtils.getSaveFormat("datetime"));
					return res;
				}

				function $DATEDIFF(d1, d2, options){
		    		var diff = datetimeUtils.getDurationBetween(d1, d2);
		    		switch(options){
		    			case "INDAYS":
		    				return diff.asDays();
		    			case "INWEEKS":
		    				return diff.asWeeks();
		    			case "INMONTHS":
		    				return diff.asMonths();
		    			case "INYEARS":
		    				return diff.asYears();
		    			default:
		    				return 0;
		    		}
				}

				//Logical Functions

				function $AND(){
					var i = 0, l = arguments.length;
					for(i = 0; i < l; i++){
						if(arguments[i] !== true){
							return false;
						}
					}
					return true;
				}

				function $OR(){
					var i = 0, l = arguments.length;
					for(i = 0; i < l; i++){
						if(arguments[i] === true){
							return true;
						}
					}
					return false;
				}

				function $NOT(condition){
					if(condition){
						return false;
					}else{
						return true;
					}
				}

				function $IF(condition, truthy, falsey){
					if(condition){
						return truthy;
					}else{
						return falsey;
					}
				}

				// Rollup Functions

				function $SUMOF(list, fieldName){
					list = list || [];
					var total = 0;
					for(i = 0; i < list.length; i++){
						total += $FLOAT(list[i][fieldName]);
					}
					return total;
				}

				function $AVGOF(list, fieldName){
					list = list || [];
					return $SUMOF(list, fieldName)/list.length;
				}

				function $MAXOF(list, fieldName){
					list = list || [];
					var i, l = list.length, max = 0, val;
					for(i = 0; i < list.length; i++){
						val = $FLOAT(list[i][fieldName]);
						if(val > max){
							max = val;
						}
					}
					return max;
				}

				function $MINOF(list, fieldName){
					list = list || [];
					var i, l = list.length, min = l ? list[0][fieldName] : 0, val;
					for(i = 0; i < list.length; i++){
						val = $FLOAT(list[i][fieldName]);
						if(val < min){
							min = val;
						}
					}
					return min;
				}

				var $F = {
					ADD: $ADD, SUBTRACT: $SUBTRACT, MULTIPLY: $MULTIPLY, DIVIDE: $DIVIDE,
					EQUAL: $EQUAL, NOTEQUAL: $NOTEQUAL, LESSTHAN: $LESSTHAN, GREATERTHAN: $GREATERTHAN, LESSTHANEQUAL: $LESSTHANEQUAL, GREATERTHANEQUAL: $GREATERTHANEQUAL,
					DATE: $DATE, DATEVALUE: $DATEVALUE, DATETIMEVALUE: $DATETIMEVALUE,
					DAY: $DAY, MONTH: $MONTH, YEAR: $YEAR,
					TODAY: $TODAY, NOW: $NOW, DATEDIFF: $DATEDIFF,
					AND: $AND, OR: $OR, NOT: $NOT, IF: $IF,
					SUMOF: $SUMOF, AVGOF: $AVGOF, MAXOF: $MAXOF , MINOF: $MINOF
				};

				try {
					return eval(expr);
				} catch(e) {
					return {error: "Warning: Error found in configured formula."};
				}
			};
		}

	}, {});
})();

// end of file
