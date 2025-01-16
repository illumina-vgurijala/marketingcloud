/**
 *JS contains all the functions used for the rendering of the Attribute Matrix Page
 *
 **/
var j$ = jQuery.noConflict();
var items;
var j$pagination ;
var perPage = 3;

var selectedAttributeMatrixEntryList = '';
j$(document).ready(function () {

    bindPageReLoadEvents();
    if(j$(".attributeSelect").length < 5) {
        addAttribute();
    }
    
});


var exportDownloadFileName = "data.csv";

function rerenderDropDown() {
    var selectedAttributeMatrix = selectedAttributeMatrixEntryList.split('##');
    var size = selectedAttributeMatrix.length;
    j$('.attributeMatrixEntryVal').each(function (index) {

        var value  = undefined;
        if(selectedAttributeMatrix != '' &&  size > index) {
            var entryObject = selectedAttributeMatrix[index].split(';;');
        
            if(entryObject && entryObject[1] === j$(this).next().attr('attrName')) {
                value = entryObject[2];
            }
        }
        
        if(value === undefined) {
            value = j$(this).next().val();
        }
        //
        var multiSelect = j$(this).next().attr("multiSelect");
        if (multiSelect === 'true') {
            j$(this).attr("multiple", true);
            j$(this).addClass("multipicklist");
        }
        j$(this).val(convertToMultiValue(value));

    });
}

function downloadCSV() {
    // innerText doesnt work in the FireFox browser and inner content doesnt preserve the <br> tag new line.
    var csv = j$('.exportDataDiv')[0].innerHTML.replace(/<br\s*[\/]?>/gi,'\n');
    var anchorSelector = document.createElement("a");
    var blob = new Blob([csv]);
    if(window.navigator.msSaveOrOpenBlob) {
        // this is for IE browsers for opening / saving the CSV data
       window.navigator.msSaveOrOpenBlob(blob, exportDownloadFileName);
    } else {
        // for other browsers
        var url = URL.createObjectURL(blob);
        anchorSelector.href = url;
        anchorSelector.download = exportDownloadFileName;
        document.body.appendChild(anchorSelector);
        anchorSelector.click();
        document.body.removeChild(anchorSelector);
    }

    
}

function convertToMultiValue(value) {
    return value.split(';');
}

var openingPopup = false;

function resizeIframe(obj) {
    if (openingPopup) {
        obj.style.height = .8 * j$(window).height() + 'px';
        resizeScrollableData(j$("[id$=" + obj.id + "]")[0], .8 * j$(window).height());
        openingPopup = false;
    }
}

function displaySpinner() {
    j$('.overlay').show();
    disableScroll();
}

function hideSpinner() {
    j$('.overlay').hide();
    enableScroll();
}

function disableScroll() {
    if (window.addEventListener) {
        window.addEventListener('DOMMouseScroll', preventDefault, false);
    } // older FF
    window.onwheel = preventDefault; // modern standard
    window.onmousewheel = document.onmousewheel = preventDefault; // older browsers, IE
    window.ontouchmove = preventDefault; // mobile
    document.onkeydown = preventDefaultForScrollKeys;
}

function enableScroll() {
    if (window.removeEventListener) {
        window.removeEventListener('DOMMouseScroll', preventDefault, false);
    }
    window.onmousewheel = document.onmousewheel = null;
    window.onwheel = null;
    window.ontouchmove = null;
    document.onkeydown = null;
}

function resizeScrollableData(iframe, dialogHeight) {

    var form = iframe.contentWindow.document.body.getElementsByTagName("form"),
        $iframeForm = j$(form),
        height1 = $iframeForm.find(".advanced-search-container").outerHeight(true),
        height2 = 0,
        height3 = $iframeForm.find(".product-search-header").outerHeight(true);

    $iframeForm.find(".data-controls").each(function () {
        height2 += j$(this).outerHeight(true);
    });

    scrollableAreaHeight = (dialogHeight - (height1 + height2 + height3 + 20));

    $iframeForm.find(".scrollable-data").height(scrollableAreaHeight);

    iframe.style.height = dialogHeight + "px";
}


function showHideUpdateCreateMatrixButton() {
    // implies either atleast one Attribute is selected or one matrix entry is present , means the matrix is already created
    var showUpdate = j$('.attributeSelect')[0].value != "" && j$('.attributeMatrixEntryVal').size() > 0;
    if (showUpdate) {
        j$('.createMatrixbtn').hide();
        j$('.updateMatrixbtn').show();
    } else {
        j$('.createMatrixbtn').show();
        j$('.updateMatrixbtn').hide();
    }
}

/**
 **  Bind events Section
 */


function bindPageReLoadEvents() {
    j$('.overlay').show();
    bindDatePicker();
    bindHeaderExpandCollapse();
    bindSaveClick();
    showHideUpdateCreateMatrixButton();
    bindCreateMatrixButton();
    bindChangeAttributeVal();
    addNewMatrixEntry();
    rerenderDropDown();
    bindDeleteMatrixEntry();
    bindExportEvent();
    bindImportClick();
    bindAddNewAttribute();
    bindUpdateMatrixButton();
    bindModalClick();
    bindAttributeSelectDropDownEvent();
    filterDropDown();
    adjustScrollableArea();
    bindCheckBox();
    updatePage();
    bindSingleSelectAttributePickList();
    j$('.overlay').hide();


}

function matrixRerenderEvents() {
    j$('.overlay').show();
    rerenderDropDown();
    updatePage();
    adjustScrollableArea();
    bindSingleSelectAttributePickList();
    showHideUpdateCreateMatrixButton();
    j$('.overlay').hide();

}

function adjustScrollableArea() {
    j$(".scrollable-outer").width(j$(".attributeInfo").width() - 45);
    j$(".scrollable-inner").width(j$(".attributeMatrixEntryTable").width());

}


function bindModalClick() {
    j$("body").off("click", ".clearAllMatrix");
    j$("body").on("click", ".clearAllMatrix", function (event) {
        j$('.confirmation').show();
    });

    j$("body").off("click", ".modal-cancel");
    j$("body").on("click", ".modal-cancel", function (event) {
       j$('.confirmation').hide();
    });

    j$("body").off("click", ".modal-ok");
    j$("body").on("click", ".modal-ok", function (event) {
        var j$attributeselectBox = j$('.attributeSelect');
        j$attributeselectBox.each(function () {
            j$(this).val("");
        });

        clearAllMatrix('');
    });

}

function clearAttributes() {
    var j$attributeselectBox = j$('.attributeSelect');
    j$attributeselectBox.each(function () {
        j$(this).val("");
        j$(this).prev().find(".attributeSingleSelect").val();
    });
    j$(".eachAttributeRow").remove();
    showHideUpdateCreateMatrixButton();
    j$('.confirmation').hide();
}

function bindCheckBox() {
	j$("body").off("click", ".checkbox-override");
    j$("body").on("click", ".checkbox-override", function (event) {
        var j$checkBox = j$(this).children(":checkbox");
        j$checkBox.attr('checked', !(j$checkBox.prop("checked")));
        event.stopPropagation();

    })
}

function bindDatePicker() {
    var $dateInputs = j$('.date-input');
    if ($dateInputs.length > 0) {
        $dateInputs.datetimepicker({
            timepicker: false,
            format: 'm/d/Y',
            scrollMonth: false,
            scrollTime: false,
            scrollInput: false
        });
    }
}

function bindHeaderExpandCollapse() {
    j$('.section .collapsible').unbind('click');
    j$('.section .collapsible').click(function () {
        var $head = j$(this);
        j$(this).parents(".section").next(".collapse").each(function(){
            j$(this).toggle(300, function () {
                var isVisible = j$(this).is(':visible');
                // animation complete
                if (isVisible) {
                    // is hidden, on animation completion change font awesome arrow icon to facing down
                    $head.find(".fa").attr('class', 'fa fa-caret-down');
                } else {
                    // is visible, on animation completion change font awesome arrow icon to facing right
                    $head.find(".fa").attr('class', 'fa fa-caret-right');
                }
            });

        });
        return false;
    });
}




function bindSaveClick() {
    j$('body').off("click", ".save");
    j$('body').on("click", ".save", function () {
    	selectedAttributeMatrixEntryList = prepareSelectedAttributeList();
        validateAndSave(selectedAttributeMatrixEntryList);
        showHideUpdateCreateMatrixButton();
        updateHeader();
    });
}


function prepareSelectedAttributeList() {
    var selectedAttrList = [];
    j$('.attributeMatrixEntryVal').each(function() {
       selectedAttrList.push(prepareSelectedAttrList(j$(this)));
    });
    return selectedAttrList.join("##");
} 

function prepareSelectedAttributeListAfterRemoval(removeAtIndex) {
    var selectedAttrList = [];
    j$('.attributeMatrixEntryVal').each(function(index, element) {
		if(index == removeAtIndex-1) {
			return true; // leave the deleted element from the collection string and skip the iteration
		}	
        selectedAttrList.push(prepareSelectedAttrList(j$(this)));
    });
    return selectedAttrList.join("##");
} 

function bindCreateMatrixButton() {
	j$('body').off('click', '.createMatrix');
    j$('body').on('click', '.createMatrix', function () {
        var list = new Array();
        var j$attributeselectBox = j$('.attributeSelect');
        j$attributeselectBox.each(function () {
            if (j$(this).val() != "") {
                list.push(j$(this).val());
            }
        });
        if(list.length > 0) {
            creatMatrix(list.join(';'));
            j$('.createMatrixbtn').hide();
            j$('.updateMatrixbtn').show();
        }
    });
}

function bindUpdateMatrixButton() {
	j$('body').off('click', '.updateMatrix');
    j$('body').on('click', '.updateMatrix', function () {
        selectedAttributeMatrixEntryList = prepareSelectedAttributeList();

        var list = new Array();
        //list = ['ABC'];
        var j$attributeselectBox = j$('.attributeSelect');
        j$attributeselectBox.each(function () {
            if (j$(this).val() != "") {
                list.push(j$(this).val());
            }
        });
        updateMatrix(list.join(';'));
        j$('.createMatrixbtn').hide();
        j$('.updateMatrixbtn').show();


    });

}

function bindAddNewAttribute() {

	j$('body').off('click', '.addAttribute');
    j$('body').on('click', '.addAttribute', function () {
        var list = new Array();
        addAttribute();
        showHideUpdateCreateMatrixButton();
    });
}

function bindChangeAttributeVal() {
    j$('body').off('change', '.attributeMatrixEntryVal');
    j$('body').on('change', '.attributeMatrixEntryVal', function () {
        var multiSelect = j$(this).next().attr("multiSelect");
        var multiSelectVal = j$(this).val();
        if (multiSelect === 'true') {
            multiSelectVal = j$(this).val().join(';');
        }
        if (multiSelectVal === j$(this).next().val()) {
            return true;
        } else {
            j$(this).next().val(multiSelectVal);
        }
        if (multiSelect === 'true') {
            j$(this).val(convertToMultiValue(multiSelectVal));

        }
        return true;
    });
}

function prepareSelectedAttrList(eachAttributeEntry) {
    var list = new Array();
    if (j$(eachAttributeEntry).val() == null) {
        j$(eachAttributeEntry).val('');
    }
    
    var multiselect = j$(eachAttributeEntry).next().attr("multiSelect");
    var multiselectVal = j$(eachAttributeEntry).val();
    if (multiselect === 'true') {
        multiselectVal = j$(eachAttributeEntry).val().join(';');
    }
    
    list = [j$(eachAttributeEntry).next().attr('index'), j$(eachAttributeEntry).next().attr('attrName'), multiselectVal];
    
    return list.join(';;');
}

function bindAttributeSelectDropDownEvent () {
    
    j$('body').off('change', '.attributeSelect');
    j$('body').on('change', '.attributeSelect', function () {
        filterDropDown();
    });
}

function filterDropDown() {
    var selectedValList = [];
    j$('.attributeSelect').each(function () {
        var selectedVal = j$(this).val();
        selectedValList.push(selectedVal);
    });

    j$('.attributeSelect').each(function () {
        j$(this).find('option').each(function () {
            if (j$(this).val() !== '' && (j$).inArray(j$(this).val(), selectedValList) !== -1 && j$(this).attr('selected') !== 'selected' ) {
                j$(this).hide();
            } else {
                j$(this).show();
            }
        });
    });
}

function addNewMatrixEntry() {
	j$('body').off('click', '.addAttributeMatrixEntry');
    j$('body').on('click', '.addAttributeMatrixEntry', function () {
        selectedAttributeMatrixEntryList = prepareSelectedAttributeList();
        var list = new Array();
        createNewRow(j$(this).attr('index'));
    });
}

function bindDeleteMatrixEntry() {
	j$('body').off('click', '.deleteAttributeMatrixEntry');
    j$('body').on('click', '.deleteAttributeMatrixEntry', function () {
        selectedAttributeMatrixEntryList = prepareSelectedAttributeListAfterRemoval(j$(this).attr('index'));
        var list = new Array();
        deleteRow(j$(this).attr('index'));
    });
}

function bindImportClick() {
	j$('body').off('click', '.importCSV');
    j$('body').on('click', '.importCSV', function () {
        j$('.hiddenFileInput').click();
    });


    j$('body').off('change', '.hiddenFileInput');
    j$('body').on('change', '.hiddenFileInput', function (event) {
        var fileString = '';
        var reader = new FileReader();
        reader.onload = function () {
            var text = reader.result;
            console.log(reader.result);
            fileString = reader.result;
            readFromCSV(fileString.replace(/\r/g, "\n"));
        };
        reader.readAsText(event.target.files[0]);
    });
}

function bindExportEvent() {
	j$('body').off('click', '.exportCSV');
    j$('body').on('click', '.exportCSV', function (event) {
        exportDataFunc();
    });
}




/************************************* Advanced Search Look up fields **********************/

var onDeleteEvent = function (itemValue, hiddenControlID) {
        var $hdnSelectedItems = j$("[id$=" + hiddenControlID + "]"),
            currentValues = $hdnSelectedItems.val(),
            updatedList = removeValue(currentValues, itemValue, "; ");

        $hdnSelectedItems.val((updatedList === "" ? "All" : updatedList));
    };

var removeValue = function (list, value, separator) {
        separator = separator || ",";
        var values = list.split(separator);
        for (var i = 0; i < values.length; i++) {
            if (values[i] == value) {
                values.splice(i, 1);
                return values.join(separator);
            }
        }
        return list;
    };

var onAddSelectedItem = function ($hiddenInput, itemValue) {
        var currentValue = $hiddenInput.val();
        if (currentValue === 'All' || currentValue === '') {
            $hiddenInput.val(itemValue);
        } else {
            $hiddenInput.val(currentValue + '; ' + itemValue);
        }
    }

    // removal of items from multi-pick widget.
var normalizeData = function (data, lblLabel, lblValue) {
        var newData = [];
        // normalize data from server if inconsistent
        for (i = 0; i < data.length; i++) {
            var item = {};
            if (typeof data[i] === 'string') {
                // use same value for value and name since is simple array of values
                item.label = data[i];
                item.value = data[i];
            } else {
                // handle single level nested property name (e.g. { "itemObj.value" : "value" } )
                if (lblLabel.indexOf('.') > 0) {
                    labelSplit = lblLabel.split('.');
                    item.label = data[i][labelSplit[labelSplit.length - 1]];
                } else {
                    item.label = data[i][lblLabel];
                }
                item.value = data[i].Id;
            }
            newData.push(item);
        }

        return newData;
    };


var productAdvancedSearchDialog;

function getSelectedProductID(productIDs) {
    setSelectedProductIDs(productIDs);
    productAdvancedSearchDialog.dialog('close');
}


var openAdvancedSearch = function (searchDialogInstance, advancedSearchContainerId, advancedSearchIframeId) {
        if (searchDialogInstance !== undefined) {
            searchDialogInstance.dialog("destroy");
        }

        searchDialogInstance = j$("[id$=" + advancedSearchContainerId + "]").dialog({
            autoOpen: true,
            modal: true,
            resizable: true,
            width: .8 * j$(window).width(),
            height: .8 * j$(window).height(),
            open: function () {
                resizeIframe(j$("[id$=" + advancedSearchIframeId + "]")[0]);
            }
        });

        j$("[id$=" + advancedSearchContainerId + "] .modal-dialog-close").on("click", function () {
            searchDialogInstance.dialog('close');
        });

        openingPopup = true;
        searchDialogInstance.dialog("open");
        productAdvancedSearchDialog = searchDialogInstance;
        return searchDialogInstance;



    };