(function(b){var a=SVMX.Package("com.servicemax.client.lib.api");a.Class("Object",{__constructor:function(){},getClassName:function(){return this.constructor.__className||"unknown";},toString:function(c){var d=this.getClassName().replace(/^com\.servicemax\.client\./,"client.");c=c?" "+c:"";return d+(c?" ("+c+")":"");}},{});a.Class("Event",com.servicemax.client.lib.api.Object,{type:null,target:null,data:null,__constructor:function(c,e,d){this.type=c;this.target=e;this.data=d;}},{});a.Class("EventDispatcher",a.Object,{eventHandlers:[],__constructor:function(){this.eventHandlers=[];},bind:function(e,d,c){this.eventHandlers[this.eventHandlers.length]={type:e,handler:d,context:c};},unbind:function(f,e,d){for(var c=0;c<this.eventHandlers.length;c++){if(this.eventHandlers[c].handler===e&&this.eventHandlers[c].type===f&&this.eventHandlers[c].context===d){this.eventHandlers.splice(c,1);}}},unbindContext:function(c){this.eventHandlers=SVMX.array.filter(this.eventHandlers,function(d){return d.context!=c;});},triggerEvent:function(g){var d=SVMX.array.filter(this.eventHandlers,function(e){return e.type==g.type;});for(var c=0;c<d.length;c++){if(d[c].context){try{d[c].handler&&d[c].handler.call(d[c].context,g);}catch(f){console.error(f);}finally{}}else{d[c].handler(g);}}}},{});a.Class("ModuleActivator",a.Object,{_logger:null,_module:null,__constructor:function(){},beforeInitialize:function(){},initialize:function(){},afterInitialize:function(){},setModule:function(c){this._module=c;},getModule:function(){return this._module;},getLogger:function(){return this._logger;},getResourceUrl:function(c){return this._module.getResourceUrl(c);}},{});a.Class("AbstractApplication",a.EventDispatcher,{__constructor:function(){this.__base();},beforeRun:function(c){c.handler.call(c.context);},run:function(){}},{currentApp:null});a.Class("AbstractCommand",a.Object,{__constructor:function(){},executeAsync:function(d,c){}},{});a.Class("AbstractOperation",a.Object,{__constructor:function(){},performAsync:function(d,c){}},{});a.Class("AbstractResponder",a.Object,{__constructor:function(){},result:function(c){},fault:function(c){}},{});a.Class("AbstractExtension",com.servicemax.client.lib.api.Object,{perform:function(c){}},{});a.Class("ExtensionRunner",com.servicemax.client.lib.api.Object,{__caller:null,__extensionName:null,__constructor:function(c,d){this.__caller=c;this.__extensionName=d;},perform:function(f){var p=SVMX.getLoggingService().getLogger("EXTENSION-RUNNER");var h=function(){var e=new b.Deferred();e.resolve();return e;};var g=SVMX.getClient();var d=g.getDeclaration("com.servicemax.client.extension");if(!d){return h();}var o=g.getDefinitionsFor(d);var n=this.__extensionName;o=SVMX.array.filter(o,function(e){return e.config.event===n;});p.info("Running "+n+" with "+o.length+" extensions");if(o.length===0){return h();}var r=[];if(f&&f.extensionClassName&&f.extensionClassName!=""){var m=SVMX.create(f.extensionClassName);try{r.push(m.perform(this.__caller,f));}catch(l){}}else{for(var j=0;j<o.length;j++){var c=o[j];var k=c.config["class-name"];var m=SVMX.create(k);try{r.push(m.perform(this.__caller,f));}catch(l){}}}var q=SVMX.when(r);q.done(function(){p.info("Running "+n+" completed");});q.fail(function(){p.error("Running "+n+" failed");});return q;}},{run:function(g,e,c){if(SVMX.TEST){console.log("skipping extension runner");var h=SVMX.Deferred();h.resolve();return h;}var f=new com.servicemax.client.lib.api.ExtensionRunner(g,e);return f.perform(c);}});})(jQuery);