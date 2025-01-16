$(function(){
    var filterDialog = null;
    
    jQuery(".clearFilters").click(function(){
        if(confirm($Label.messageConfirmClearFilters)) {
            jQuery(".filtersTable>tbody").empty();
            jQuery(".filtersTable").hide();
            jQuery(".filtersData>input[type=hidden]").val("[]");
        }
        
        return false;
    });
    
    function refreshFiltersTable() {
        var filtersData = getFiltersData();
        
        if(filtersData && filtersData.length > 0) {
            buildFiltersTable(filtersData);
            jQuery(".filtersTable").show();
        } else {
            jQuery(".filtersTable").hide();
        }
    }
    
    refreshFiltersTable();
    
    function getFiltersData () {        
        var filtersDataStr = jQuery(".filtersData>input[type=hidden]").val();
        var filtersData;
        if(filtersDataStr) {         
            return JSON.parse(filtersDataStr);   
        }
        
        return [];
    }
    
    jQuery(".editFilters").click(function(){
        if(!filterDialog) {
            filterDialog = openSeismicDialog($Label.filterLabelEdit, 'seismicFilterDialog');
        } else {
            filterDialog.show();            
        }
                    
        var $seismicDialogMain = jQuery(filterDialog.dialog).css({top: 180}).find(".SeismicDialogMain").empty();
        
        var filtersData = getFiltersData();
        
        if(filtersData.length == 0) filtersData = [[]];
        
        if(filtersData && filtersData.length > 0) {
            buildFilterForm(filtersData, $seismicDialogMain);
        }
            
        $seismicDialogMain.on("change", ".sfField", function(){
            var $seismicField = jQuery(this).parents(".row").find(".seismicField");
            if(!$seismicField.val()) {
                $seismicField.val(jQuery(this).find("option:selected").text());                    
            }
        });
            
        var $errorMsg = jQuery("<div class=warningMessage>").appendTo($seismicDialogMain);
        
        $seismicDialogMain.append(jQuery("<button class='btn okbtn'>").text($Label.commonOk).click(function(){
            $errorMsg.html("");
            if(!checkValid($seismicDialogMain)) {
                return false;
            }
            
            if(!checkDuplicate($seismicDialogMain)) {
                $errorMsg.html("Doesn't support duplicate mapping.");
                return false;
            }
            
            var result = $seismicDialogMain.find(".row").map(function(k, v){
                var seismicField = jQuery(v).find("input.seismicField").val();
                var operator = jQuery(v).find("select.operator").val();
                var sfField = jQuery(v).find("select.sfField").val();
                var sfFieldLabel = jQuery(v).find("select.sfField option:selected:first").text();
                
                if(seismicField) {
                    return [[seismicField, operator, sfField, sfFieldLabel]];
                }
            });
            jQuery(".filtersData>input[type=hidden]").val(String.prototype.toJSON?([].slice.call(result)).toJSON():JSON.stringify([].slice.call(result)));
            refreshFiltersTable();
            filterDialog.hide();
                    
        	return false;
        }));
        
        retriveFields(getCurrentObjectName(), function(result){
            jQuery(".sfFieldBusy").hide();
            initSelect(jQuery(".sfField"), result);
            
            jQuery("button").attr("disabled", false);
        });        
        
        return false;
    });
});

function checkDuplicate($seismicDialogMain) {    
    $seismicDialogMain.find("input, select").each(function(){
        jQuery(this).removeClass("invalidField");
    });
    
    var result = true;
    
    if(!_checkDuplicate($seismicDialogMain.find("input.seismicField"))) {
        result = false;
    }
    
    if(!_checkDuplicate($seismicDialogMain.find("select.sfField"))) {
        result = false;
    }
    
    return result;
}

function _checkDuplicate($seismicFields) {
    var result = true;
    $seismicFields.each(function(k, v){
        for(var i = k + 1; i < $seismicFields.length; i++) {
            if($seismicFields.eq(i).val() == jQuery(v).val()) {
                $seismicFields.eq(i).addClass("invalidField");
                jQuery(v).addClass("invalidField");
                result = false;
            }
        }
    });
    
    return result;
}

function checkValid ($seismicDialogMain){
    var valid = true;
    $seismicDialogMain.find("input, select").each(function(){
        jQuery(this).removeClass("invalidField");
        if(!jQuery(this).val()) {
            jQuery(this).addClass("invalidField");
            valid = false;
        }
    });
    
    return valid;
}

function buildFiltersTable (data) {
    var $tbody = jQuery(".filtersTable>tbody").empty();
    
    for(var i = 0; i < data.length; i ++) {
        var item = data[i];
        var seismicField = item[0],
            operator = item[1],
            sfField = item[2],
            sfFieldLabel = item[3];        
        
        $tbody.append(jQuery("<tr class=dataRow>").append(
            jQuery("<td class=dataCell>").text(seismicField),
            jQuery("<td class=dataCell>").text(operatorsMapping[operator]),
            jQuery("<td class=dataCell>").text(sfFieldLabel)
        ));
    }
}

function buildFilterForm(data, $container){
    var $tbody = jQuery("<tbody>");
    jQuery("<table>").append(
        jQuery("<thead class=rich-table-thead>").append(
            jQuery("<tr class=headerRow>").append(
                jQuery("<th class=headerRow>").text($Label.filterLabelProperty),
                jQuery("<th class=headerRow>").text($Label.filterLabelOperator),
                jQuery("<th class=headerRow>").text($Label.filterLabelField),
                jQuery("<th class=headerRow>")
            )
        ),
        $tbody
    ).appendTo($container);
    
    for(var i = 0; i < data.length; i ++) {
        var item = data[i];
        var seismicField = item[0],
            operator = item[1],
            sfField = item[2];
        
        $tbody.append(jQuery("<tr class='dataRow row'>").append(
            jQuery("<td class=dataCell>").html(jQuery("<input class=seismicField>").val(seismicField)),
            jQuery("<td class=dataCell>").html(jQuery("<select class=operator>").data("val", operator)),
            jQuery("<td class=dataCell>").html(jQuery("<select class=sfField>").data("val", sfField).hide().append(jQuery("<span class=sfFieldBusy>").text("Loading..."))),
            jQuery("<td class=dataCell>").append(jQuery("<button class=removeRowButton>").text("-"), jQuery("<button class=addRowButton>").text("+"))
        ));
    }
    
    $tbody.on("click", ".addRowButton", function(){
        var $row = jQuery(this).parents(".row");
        var $clone = $row.clone().insertAfter($row);
        $clone.find("input").val("");
        $clone.find("select option").attr("selected", false);
        setAddOrRemoveRowButtons();
    });
    
    $tbody.on("click", ".removeRowButton", function(){
        var $row = jQuery(this).parents(".row");
                
        $row.remove();
        setAddOrRemoveRowButtons();
    });
        
    setAddOrRemoveRowButtons();

    initSelect(jQuery(".operator"), [
        {label: $Label.operatorEquals, name: "=="},
        {label: $Label.operatorDiffers, name: "<>"},
        {label: $Label.operatorGreaterOrEqual, name: ">="},
        {label: $Label.operatorGreater, name: ">"},
        {label: $Label.operatorLessOrEqual, name: "<="},
        {label: $Label.operatorLess, name: "<"},
        {label: $Label.operatorStartsWith, name: "ST"},
        {label: $Label.operatorEndsWith, name: "ED"},
        {label: $Label.operatorContains, name: "CT"},
		{label: $Label.operatorDoesNotContain, name: "NCT"},
        {label: $Label.operatorContainsAll, name: "CTALL"},
        {label: $Label.operatorContainsAny, name: "CTANY"}
    ]);
    
    jQuery("button").attr("disabled", true);
}

var operatorsMapping = {
    "==": $Label.operatorEquals,
    "<>": $Label.operatorDiffers,
    ">=": $Label.operatorGreaterOrEqual,
    ">": $Label.operatorGreater,
    "<=": $Label.operatorLessOrEqual,
    "<": $Label.operatorLess,
    "ST": $Label.operatorStartsWith,
    "ED": $Label.operatorEndsWith,
    "CT": $Label.operatorContains,
	"NCT": $Label.operatorDoesNotContain,
    "CTALL": $Label.operatorContainsAll,
    "CTANY": $Label.operatorContainsAny
};

function setAddOrRemoveRowButtons () {
    jQuery(".removeRowButton").show();
    if(jQuery(".removeRowButton").length == 1) {
        jQuery(".removeRowButton").hide();
    }
    
    jQuery(".addRowButton").hide().last().show();
}

function initSelect($select, data) {    
	$select.each(function(){
        for(var i = 0; i < data.length; i++) {
            var $o = jQuery("<option>").val(data[i].name).text(data[i].label);
            jQuery(this).append($o);
            
            if(jQuery(this).data("val") == data[i].name) {
                $o.attr("selected", "selected");                 
            }
        }
        
        jQuery(this).show();
    });   
}
    
function retriveFields(objectName, callback){
    sforce.connection.describeSObject(objectName, function(data){
        if(data.fields && data.fields.length > 0) {
            if(!jQuery.isArray(data.fields)) {
                data.fields = [data.fields];
            }
            
            data.fields.sort(function(a, b){
                return a.label > b.label ? 1 : (a.label == b.label ? 0 : -1);
            });
            
            var result = [{label:'', name: ''}];
            for(var i = 0; i < data.fields.length; i++) {
                var field = data.fields[i];
                if(!field || !field.label || !field.name) {
                    continue;
                }
                var name = field.name;
                if(field.type=='reference'){
                	name = field.relationshipName + '.Name';
                }
                result.push({
                    label: field.label,
                    name: name
                });
            }
        }
        
        callback(result);
    });
}

var DIALOG_WIDTH = 680;
var IFRAME_HEIGHT = 420;
var DIALOG_STYLE = "<style>html, body {overflow: hidden;} .SeismicDialogCloseButton {position: absolute;right: 10px;top: 6px;} #[!seismicDialogId].overlayDialog .middle{background: #ffffff} .SeismicButtonDialog {overflow: hidden; height: 420px; width: 514px;} .SeismicButtonDialog .miniRequester{overflow: hidden; border: none; width: 100%; height: " + IFRAME_HEIGHT + "px;}</style>";
var PARAMETER_SEISMIC_DIALOG_ID = "[!seismicDialogId]";
function openSeismicDialog(title, parentBoxName) {
	var dialog = new SimpleDialog(parentBoxName, true);
    
  //parent[parentBoxName] = dialog;
    dialog.setTitle(title || '');
    dialog.createDialog();
    dialog.setWidth(DIALOG_WIDTH);
    var dialogStyle = DIALOG_STYLE.replace(PARAMETER_SEISMIC_DIALOG_ID, parentBoxName);
    var html = dialogStyle + "<div class='SeismicDialogMain'></div>";
    dialog.setContentInnerHTML(html);
    dialog.setupDefaultButtons();
    dialog.show();
    
    var topRight = dialog.dialog.getElementsByClassName("topRight");
    if(topRight && topRight[0]){
        var b = document.createElement("button");
        b.className = "btn SeismicDialogCloseButton";
        b.onclick = function(){
            //parent[parentBoxName].hide();
            dialog.hide();		    	
            var root = dialog.getContentElement();
            if(typeof _findIframeRecursively != 'undefined')
            {		
	            var iframe = _findIframeRecursively(root);		
	            if(iframe) {
	                iframe.src = '';
	            }
            }
            return false;
        };
        
        b.innerHTML = 'X';
        topRight[0].appendChild(b);
    }
    
    return dialog;
}