/*
dhtmlxScheduler v.4.2.0 Professional

This software is covered by DHTMLX Enterprise License. Usage without proper license is prohibited.

(c) Dinamenta, UAB.
*/
Scheduler.plugin(function(e){e.expand=function(){var t=e._obj;do t._position=t.style.position||"",t.style.position="static";while((t=t.parentNode)&&t.style);t=e._obj,t.style.position="absolute",t._width=t.style.width,t._height=t.style.height,t.style.width=t.style.height="100%",t.style.top=t.style.left="0px";var i=document.body;i.scrollTop=0,i=i.parentNode,i&&(i.scrollTop=0),document.body._overflow=document.body.style.overflow||"",document.body.style.overflow="hidden",e._maximize()},e.collapse=function(){var t=e._obj;
do t.style.position=t._position;while((t=t.parentNode)&&t.style);t=e._obj,t.style.width=t._width,t.style.height=t._height,document.body.style.overflow=document.body._overflow,e._maximize()},e.attachEvent("onTemplatesReady",function(){var t=document.createElement("DIV");t.className="dhx_expand_icon",e.toggleIcon=t,e._obj.appendChild(t),t.onclick=function(){e.expanded?e.collapse():e.expand()}}),e._maximize=function(){this.expanded=!this.expanded,this.toggleIcon.style.backgroundPosition="0 "+(this.expanded?"0":"18")+"px";
for(var t=["left","top"],i=0;i<t.length;i++){var n=(e.xy["margin_"+t[i]],e["_prev_margin_"+t[i]]);e.xy["margin_"+t[i]]?(e["_prev_margin_"+t[i]]=e.xy["margin_"+t[i]],e.xy["margin_"+t[i]]=0):n&&(e.xy["margin_"+t[i]]=e["_prev_margin_"+t[i]],delete e["_prev_margin_"+t[i]])}e.callEvent("onSchedulerResize",[])&&(e.update_view(),e.callEvent("onAfterSchedulerResize"))}});
//# sourceMappingURL=../sources/ext/dhtmlxscheduler_expand.js.map