({
    //method to fetch initial load of data
    loadData : function(component,helper) {
        //Doing server call to get page load info by passsing Record Id, sort field and sort direction
        helper.callServer(component,"c.getAssociatedCodes",function(response){
            helper.consoleLog('Result',false,response);
            if(response.toString().includes('ERROR :')){
                helper.showErrorToast(response.toString());
            }
            else{
                let objWrapObject = JSON.parse(response);
                component.set('v.mapLabels',objWrapObject.mapLabels);
                component.set('v.BoolQAUser',objWrapObject.boolQAUser);
                component.set('v.BoolLogisticsUser',objWrapObject.boolLogisticsUser);
                helper.generateURL(component,helper,objWrapObject.lstAssociatedCodes);
                helper.parseData(component,helper);
                let opts = [];
                if(objWrapObject.lSearchOptions.length > 0){
                    for (let i = 0; i < objWrapObject.lSearchOptions.length; i++) {
                        opts.push(objWrapObject.lSearchOptions[i]);
                    }
                }
                if(objWrapObject.lstAssociatedCodes!=null && objWrapObject.lstAssociatedCodes.length > 0)
                    component.set('v.AscCodeListSize',objWrapObject.lstAssociatedCodes.length);
                component.set('v.SearchRadioOptions',opts );
                component.set('v.SelectedSearchOption',objWrapObject.boolQAUser ? objWrapObject.mapLabels.CodeLibraryCodeTypeHazard : objWrapObject.boolLogisticsUser ? objWrapObject.mapLabels.CodeLibraryCodeTypeLogistics : 'All');
                
                //DCP-37793
                helper.updateColumns(component,helper,component.get("v.SelectedSearchOption"));
                component.set('v.BoolElevationCase',objWrapObject.bIsElevation);
                component.set('v.BoolLockCodes',objWrapObject.bLockCodes);
                //DCP-47684
                this.populateValidationMap(component, helper);
            }
        },{
            "strRecordId": component.get("v.recordId"),
            "strFieldName" : component.get("v.SortByField"),
            "strSortOrder" : component.get("v.SortByDirection")
        });
    },
    
    //method to fetch search results
    getCodes : function(component,helper) {
        //Doing server call to get search result info by passsing Record Id, search string,
        //selected search option, sort field and sort direction
        let queryTerm = component.find('code-search-input').get('v.value');
        component.set('v.SortByField',null);
        component.set('v.SortByDirection',null);
        if(typeof queryTerm === 'undefined')
            component.set('v.SearchedCode','');
        else
            component.set('v.SearchedCode',queryTerm);
        helper.parseData(component,helper);
        helper.callServer(component,"c.getSearchCodeList",function(response){
            if(response.toString().includes('ERROR :')){
                helper.showErrorToast(component.get("v.mapLabels").UI_Error_Message_System_Error);
            }
            else{
                let objWrapObject = JSON.parse(response);
                if(component.get("v.SelectedSearchOption") == component.get("v.mapLabels").CodeLibraryCodeTypeHazard || component.get("v.SelectedSearchOption") == component.get("v.mapLabels").CodeLibraryCodeTypeLogistics){
                    objWrapObject.lstCodeLibrary.forEach((element, index, array) => {
                        if(array[index].Parent_Code__r ){
                        array[index].ParentTitle = array[index].Parent_Code__r.Name;
                        }
                    })
                    //DCP-37793
                    helper.updateColumns(component,helper,component.get("v.SelectedSearchOption"));
                }
                objWrapObject.lstCodeLibrary.forEach((element, index, array) => {
                    if(array[index].Code_Description__c != null)
                        array[index].disable = false;
                    else
                        array[index].disable = true;
                })
                component.set('v.CodeLibraryList',objWrapObject.lstCodeLibrary);
                component.set('v.BoolLockCodes',objWrapObject.bLockCodes);
                if(objWrapObject.lstCodeLibrary!=null)
                    component.set('v.CodeLibListSize',objWrapObject.lstCodeLibrary.length);
                  
            }
        },{
            "codeTitle" : queryTerm,
            "strCodeType" : component.get("v.SelectedSearchOption"),
            "strRecordId": component.get("v.recordId"),
            "strFieldName" : component.get("v.SortByField"),
            "strSortOrder" : component.get("v.SortByDirection")
        });
    },
    //DCP-37793 : Updated logic
    //method to add a code library record as associated code
    addCode : function(component,event,helper,strCodeId){
        //Doing server call to get add code library
        helper.callServer(component,"c.addAssociatedCodes",function(response){
            if(response.toString().includes('ERROR :')){
                helper.showErrorToast(component.get("v.mapLabels").UI_Error_Message_System_Error);
            }
            else{
                let objWrapObject = JSON.parse(response);
                helper.generateURL(component,helper,objWrapObject.lstAssociatedCodes);
                if(objWrapObject.lstAssociatedCodes!=null)
                    component.set('v.AscCodeListSize',objWrapObject.lstAssociatedCodes.length);
                
                helper.getCodes(component,helper);
                //DCP-47684
                this.populateValidationMap(component, helper);
                $A.get('e.force:refreshView').fire(); //DCP-51200 [refresh view so that SFMs are refreshed too]
            }
        },{
            "strRecordId": component.get("v.recordId"),
            "strCodeId" : strCodeId
        });
    },
    //DCP-37793 : Updated logic
    //method to disassociate a code
    removeCode : function(component,event,helper,strCodeId,strParentId,boolIsActive){
        if(boolIsActive)
            helper.showErrorToast(component.get("v.mapLabels").UI_Error_Message_Restrict_Non_Hazard);
        else if(typeof strParentId === 'undefined' && component.get("v.BoolQAUser")){
            helper.showErrorToast(component.get("v.mapLabels").UI_Error_Message_Restrict_Parent);
        }
        else{
            //Doing server call to get disassociate code
            helper.callServer(component,"c.removeAssociatedCodes",function(response){
                if(response.toString().includes('ERROR :')){
                    helper.showErrorToast(component.get("v.mapLabels").UI_Error_Message_System_Error);    
                }
                else{
                    let objWrapObject = JSON.parse(response);
                    helper.generateURL(component,helper,objWrapObject.lstAssociatedCodes);
                    if(objWrapObject.lstAssociatedCodes!=null)
                        component.set('v.AscCodeListSize',objWrapObject.lstAssociatedCodes.length);
                    //DCP-47684
                    this.populateValidationMap(component, helper);
                    $A.get('e.force:refreshView').fire(); //DCP-51200 [refresh view so that SFMs are refreshed too]
                }
            },{
                "strRecordId": component.get("v.recordId"),
                "strCodeId" : strCodeId
            });
        }
    },
    /*
    * @author KD
    * @date
    * //DCP-37793
    * @description  Sort data
    * 
    */
     sortData: function (component, strFieldName, strSortDirection,data,dataType) {    
        let booReverse = strSortDirection !== 'asc';
        data.sort(this.sortBy(strFieldName, booReverse))
        if(dataType == 'CodeLibrary')
            component.set("v.CodeLibraryList", data);
        else
            component.set("v.AssociatedCodeList", data);
    },
    /*
    * @author KD
    * @date
    * //DCP-37793
    * @description  Add/Remove Parent Code column from COlumn list
    * 
    */
   generateURL: function(component,helper,lstAssociatedCodes){
    let boolQA = component.get("v.BoolQAUser");
    let boolLogistics = component.get("v.BoolLogisticsUser");
    lstAssociatedCodes.forEach((element, index, array) => {
        if(array[index].Parent_Code__c != null){
            array[index].ParentURL = '/'+array[index].Parent_Code__c;
            array[index].ParentURLTitle = array[index].Parent_Code__r.Name;
        }
        if(array[index].Code_Description__c != null)
            array[index].disable = false;
        else
            array[index].disable = true;
        //INC0282548
        if(array[index].Code_Type__c === component.get("v.mapLabels").CodeLibraryCodeTypeHazard){
            array[index].isActive = !boolQA;
       }
       //DCP-43515
       else if(array[index].Code_Type__c != component.get("v.mapLabels").CodeLibraryCodeTypeLogistics){
            array[index].isActive = false;
       }
       
       if(array[index].Code_Type__c === component.get("v.mapLabels").CodeLibraryCodeTypeLogistics){
           array[index].isActive = !boolLogistics;
       }
       else if(array[index].Code_Type__c != component.get("v.mapLabels").CodeLibraryCodeTypeHazard){
            array[index].isActive = boolLogistics;
       }
    });
    component.set('v.AssociatedCodeList',lstAssociatedCodes);
   },
    /*
    * @author KD
    * @date   
    * //DCP-37793
    * @description  Add/Remove Parent Code column from COlumn list
    * 
    */
    updateColumns: function(component,helper,codeType){
        let listColumn = component.get("v.columns");
        if(listColumn.length == 6 && codeType == component.get("v.mapLabels").CodeLibraryCodeTypeHazard){
            listColumn.splice(5,0,{label: 'Parent Code Title', fieldName: 'ParentTitle', type: 'text', sortable: true,wrapText: true,initialWidth : 100})
        }
        else if(listColumn.length == 7 && codeType != component.get("v.mapLabels").CodeLibraryCodeTypeHazard){
            listColumn.splice(5,1);
        }
        component.set('v.columns',listColumn);
    },
    /*
    * @author KD
    * @date
    * Story : DCP-37793
    * @description  parse the list returned into a JSON that can be passed to lightning data table
    * 
    */
    parseData: function(component,helper) {
    component.set('v.columns',[
        {label: 'Code Id', fieldName: 'Code_ID__c', type: 'text', sortable: true,initialWidth : 100},
        {
            type: 'button-icon',
            fixedWidth: 15,
            typeAttributes: {
                iconName: 'action:info',
                name: 'Info', 
                title:  {fieldName: 'Code_Description__c'},
                alternativeText:  {fieldName: 'Code_Description__c'},
                variant : "bare",
                disabled: {fieldName : 'disable'}
            }
        },
        {label: 'Code Title', fieldName: 'Name', type: 'text', sortable: true,wrapText: true},
        {label: 'Code Type', fieldName: 'Code_Type__c', type: 'text', sortable: true,initialWidth : 110},
        {label: 'Case Type', fieldName: 'Case_Type__c', type: 'text', sortable: true,initialWidth : 130},
        {
            type: 'button-icon',
            fixedWidth: 60,
            typeAttributes: {
                iconName: 'utility:new',
                name: 'Add_Record', 
                title: 'Add',
                variant: 'bare',
                alternativeText: 'Add',
                disabled: false,
                iconClass : 'addBtn',
                size : 'small'
            }
        }
    ]);
    component.set('v.Associatedcolumns',[
        {label: 'Code Id', fieldName: 'Code_ID__c', type: 'text', sortable: true,initialWidth : 100},
        {
            type: 'button-icon',
            fixedWidth: 15,
            typeAttributes: {
                iconName: 'action:info',
                name: 'Info', 
                title: {fieldName: 'Code_Description__c'},
                alternativeText: {fieldName: 'Code_Description__c'},
                variant : "bare",
                disabled: {fieldName : 'disable'}
            }
        },
        {label: 'Code Title', fieldName: 'Code_Title_Name__c', type: 'text', sortable: true, wrapText: true},
        {label: 'Code Type', fieldName: 'Code_Type__c', type: 'text', sortable: true,initialWidth : 110},
        {label: 'Case Type', fieldName: 'Case_Type__c', type: 'text', sortable: true,initialWidth : 130},
        {
            label: 'Parent Code Title',
            fieldName: 'ParentURL',
            type: 'url',
            typeAttributes: {label: { fieldName: 'ParentURLTitle' },
            tooltip : {fieldName: 'ParentURLTitle'}, 
            target: '_blank'},
            sortable: true,
            initialWidth : 100
        },
        {
            type: 'button-icon',
            fixedWidth: 60,
            typeAttributes: {
                iconName: 'utility:close',
                name: 'Remove_Record', 
                title: 'Remove',
                variant: 'bare',
                alternativeText: 'Remove',
                iconClass : 'removeBtn',
                size : 'small',
                disabled: {fieldName : 'isActive'}
            }
        }
    ]);
    },

    /*******************************************************************************************************
    * @description DCP-47684 Highlight mandatory codes
    */
    populateValidationMap : function(component,helper) {
        helper.callServer(component,"c.getValidationsMap",function(response) {
            let codes;
            
            if(response.toString().includes('ERROR :')) {
                helper.showErrorToast(response.toString());
            } else {
                let objWrapObject = JSON.parse(response);
                let isHighlight = false;
                if(!$A.util.isUndefined(component.find('codes-radio'))) {
                    codes = component.find('codes-radio');
                } else {
                    codes = component.find('second-codes-radio');
                }
                for (let item of codes) {
                    let codeName = item.get('v.label');
                    if(objWrapObject[codeName] === true) {
                        $A.util.addClass(item, 'highlight');
                        isHighlight = true;
                    } else if($A.util.hasClass(item, 'highlight')) {
                        $A.util.removeClass(item, 'highlight');
                    }
                }
                component.set('v.BoolHighlight', isHighlight);
            }
        }, {
			"strRecordId": component.get("v.recordId")
		});
	}
    
})
