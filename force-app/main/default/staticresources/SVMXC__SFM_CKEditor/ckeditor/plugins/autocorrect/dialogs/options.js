﻿/*
 Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 For licensing, see LICENSE.md or http://ckeditor.com/license
*/
(function(){function b(){this.setValue(f.getOption(this.option))}function c(){f.setOption(this.option,this.getValue())}var f=CKEDITOR.plugins.autocorrect;CKEDITOR.dialog.add("autocorrectOptions",function(a){a=a.lang.autocorrect;return{title:a.autocorrect,resizable:CKEDITOR.DIALOG_RESIZE_NONE,minWidth:350,minHeight:170,onOk:function(){this.commitContent()},contents:[{id:"autocorrect",label:a.autocorrect,title:a.autocorrect,accessKey:"",elements:[{type:"vbox",padding:0,children:[{type:"checkbox",id:"useReplacementTableCheckbox",
option:"useReplacementTable",setup:b,commit:c,isChanged:!1,label:a.replaceTextAsYouType},{type:"html",html:'\x3cdiv style\x3d"height: 150px;overflow-y: scroll;border: 1px solid #afafaf"\x3e\x3c/div\x3e',setup:function(){this.getElement().setHtml("");var a=f.getOption("replacementTable"),b=document.createElement("table");b.style.width="100%";b.style.tableLayout="fixed";var c=b.appendChild(document.createElement("tbody")),g;for(g in a){var h=document.createElement("tr"),d=document.createElement("td");
d.appendChild(document.createTextNode(g));d.style.borderBottom="1px solid #afafaf";d.style.padding="0 5px";var e=document.createElement("td");h.appendChild(d);e.appendChild(document.createTextNode(a[g]));e.style.borderBottom="1px solid #afafaf";e.style.padding="0 5px";h.appendChild(e);c.appendChild(h)}this.getElement().append(new CKEDITOR.dom.element(b))}}]}]},{id:"autoformatAsYouType",label:a.autoformatAsYouType,title:a.autoformatAsYouType,accessKey:"",elements:[{type:"fieldset",label:CKEDITOR.tools.htmlEncode(a.replaceAsYouType),
children:[{type:"vbox",padding:0,children:[{type:"checkbox",id:"smartQuotesCheckbox",option:"smartQuotesAsYouType",setup:b,commit:c,isChanged:!1,label:a.smartQuotesOption},{type:"checkbox",id:"formatOrdinalsCheckbox",option:"formatOrdinalsAsYouType",setup:b,commit:c,isChanged:!1,label:a.formatOrdinalsOption},{type:"checkbox",id:"replaceHyphensCheckbox",option:"replaceHyphensAsYouType",setup:b,commit:c,isChanged:!1,label:a.replaceHyphensOption},{type:"checkbox",id:"recognizeUrlsCheckbox",option:"recognizeUrlsAsYouType",
setup:b,commit:c,isChanged:!1,label:a.recognizeUrlsOption}]}]},{type:"fieldset",label:CKEDITOR.tools.htmlEncode(a.applyAsYouType),children:[{type:"vbox",padding:0,children:[{type:"checkbox",id:"formatBulletedListsCheckbox",option:"formatBulletedListsAsYouType",setup:b,commit:c,isChanged:!1,label:a.formatBulletedListsOption},{type:"checkbox",id:"formatNumberedListsCheckbox",option:"formatNumberedListsAsYouType",setup:b,commit:c,isChanged:!1,label:a.formatNumberedListsOption},{type:"checkbox",id:"createHorizontalRulesCheckbox",
option:"createHorizontalRulesAsYouType",setup:b,commit:c,isChanged:!1,label:a.createHorizontalRulesOption}]}]}]},{id:"replace",label:a.autoformat,accessKey:"",elements:[{type:"fieldset",label:CKEDITOR.tools.htmlEncode(a.replace),children:[{type:"vbox",padding:0,children:[{type:"checkbox",id:"smartQuotesCheckbox",option:"smartQuotes",setup:b,commit:c,isChanged:!1,label:a.smartQuotesOption},{type:"checkbox",id:"formatOrdinalsCheckbox",option:"formatOrdinals",setup:b,commit:c,isChanged:!1,label:a.formatOrdinalsOption},
{type:"checkbox",id:"replaceHyphensCheckbox",option:"replaceHyphens",setup:b,commit:c,isChanged:!1,label:a.replaceHyphensOption},{type:"checkbox",id:"recognizeUrlsCheckbox",option:"recognizeUrls",setup:b,commit:c,isChanged:!1,label:a.recognizeUrlsOption}]}]},{type:"fieldset",label:CKEDITOR.tools.htmlEncode(a.apply),children:[{type:"vbox",padding:0,children:[{type:"checkbox",id:"formatBulletedListsCheckbox",option:"formatBulletedLists",setup:b,commit:c,isChanged:!1,label:a.formatBulletedListsOption},
{type:"checkbox",id:"formatNumberedListsCheckbox",option:"formatNumberedLists",setup:b,commit:c,isChanged:!1,label:a.formatNumberedListsOption},{type:"checkbox",id:"createHorizontalRulesCheckbox",option:"createHorizontalRules",setup:b,commit:c,isChanged:!1,label:a.createHorizontalRulesOption}]}]}]}],onShow:function(){this.setupContent()}}})})();