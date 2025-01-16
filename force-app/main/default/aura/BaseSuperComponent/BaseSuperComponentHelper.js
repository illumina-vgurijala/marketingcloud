({
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  Method handles server calls
    * @param component --> reference for the component from which this method is called
    * @param method (String) --> method name which needs to be called
    * @param callback(function) --> function to be called when server call completes
    * @param params(JSON) --> parameters to be passed to the server call
    * @param cacheable(boolean) --> boolean to set cacheable call
    * @param background(boolean) --> boolean to set background call
    */
    callServer : function(component, method, callback, params, cacheable,background) {
        try {
            let action = component.get(method);
            let baseComp = component.getSuper();
            this.toggleSpinner(baseComp);
            if (params) {
                action.setParams(params);
            }
            if(background){
                //console.log("In background");
                action.setBackground();
            }
            if (cacheable) {
                action.setStorable();
            }
            
            action.setCallback(this,function(response) {
                let state = response.getState();
                let lightningServerResponse = response.getReturnValue();
                this.toggleSpinner(baseComp);
                if (state === "SUCCESS") 
                    callback.call(this,lightningServerResponse);
                else{
                    this.consoleLog("Error calling the server",true,response.getError());
                    this.showErrorToast('Unexpected error occured!');
                }
                    
                
            });
            $A.enqueueAction(action);
        } catch(e) {
            this.consoleLog(e.stack, true);
        }
    },

    /*
    *  @AUTHOR:  Debalina   
    *  @DESCRIPTION:This reusable method Initializes Record Template for any sObject using data service   
    *  @PARAM :
       1. strObjAPIName(String) --> API name of the sObject
       2. strDataServiceAuraId(String) --> Aura Id of the recordData service used.
       3. objAttribute(Object) --> sObject instance specified in targetRecord
       4. strError(String) --> Error in initialization
       5. strRecTypeId(String) --> Initial record type Id for sObject Record
       6. boolSkipCache(Boolean) --> for skipping cache set true else false
       7. component
       8. callback(function) --> pass null if no callback method to be executed on success
    *  @RETURN:  JSON string with all relevant data
    *  Created as a part of DCP-3003
    */
    initializeRecordTemplate : function(strObjAPIName, strDataServiceAuraId, objAttribute, strError, strRecTypeId, boolSkipCache, component, callback){
        
        component.find(strDataServiceAuraId).getNewRecord(
            strObjAPIName, // objectApiName
            strRecTypeId, // recordTypeId
            boolSkipCache, // skip cache?
            $A.getCallback(function() {
                let record = component.get(objAttribute);
                let error = component.get(strError);
                if(error || (record === null)) {
                    console.debug("Error initializing record template: ", error);
                }
                else {
                    console.debug("Record template initialized: ", record);
                    if(!$A.util.isUndefinedOrNull(callback)){
                        callback.call(this);
                    }
                }
            })
        );
    },

    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  Method shows an error toast of the message passed
    * @param message (string) --> message to be displayed
    * @param error (boolean) --> parameter to be set only for error messages primarily from catch blocks 
    * @param objGeneric(Object) --> Parameter to be set only if an object needs to be printed in the console
    */
    consoleLog: function(message, error,objGeneric){
        try {
            let sCallStack = "";//storing call stack
            try {   throw new Error();  }   catch(e)    {   sCallStack = String(e.stack);   }
            let originalLine = sCallStack.split("\n")[2].trim();
            let sConsoleLog = $A.get("$Label.c.UI_Console_Logger");
            let sShowError = sConsoleLog.split("|")[0];
            let sShowMessage = sConsoleLog.split("|")[1];
            if(objGeneric)
                objGeneric = JSON.stringify(objGeneric);
            if(error && sShowError === "Yes")   {
                if(objGeneric)
                    console.error(message,objGeneric);
                else
                    console.error(message);
                
            }
            else if(sShowMessage === "Yes") {
                if (((Array.isArray(message) && typeof(message[0]) === "object")) && (console.table !== undefined)) {
                    console.table(message);
                } else if(objGeneric){
                    console.debug(message,objGeneric);
                } else {
                    console.debug(message);
                }
                
                console.debug(originalLine);
            }
            
        } catch(e) {
            console.error(e.stack);
        }
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  Method shows an error toast of the message passed
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showErrorToast : function(strMessage,strMode,intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';//by default sticky
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Error', strMessage, 'error', strMode, intDuration);
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  Method shows a success toast of the message passed, by default sticky
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showSuccessToast : function(strMessage,strMode,intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Success', strMessage, 'success', strMode, intDuration);
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  shows the lightning toast
    * Documentation for toast below
    * https://developer.salesforce.com/docs/component-library/bundle/force:showToast/documentation
    * @param strTitle (string) --> Title to be shown
    * @param strMessage (string) --> message to be shown
    * @param strType (string) --> type of toast to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showToast : function(strTitle, strMessage, strType, strMode, intDuration) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : strTitle,
            message : strMessage,
            duration : intDuration,
            mode: strMode,
            type: strType
        });
        toastEvent.fire();
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-Sep-2018
    * @description  Show error notices for modal windows
    * @param component 
    * @param strHeader (string) --> header to be shown
    * @param strMessage (string) --> Message to be shown
    * @param callBack (function) --> Callback on close of notice
    */
    showErrorNotice : function(component,strMessage,strHeader,helper,callBack){
        if($A.util.isEmpty(strHeader))
            strHeader = "Error!";
        helper.showNotice(component,"error",strHeader,strMessage,callBack);
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-Sep-2018
    * @description  Show notices for modal windows
    * @param component 
    * @param strVariant (string) --> Variant to be shown
    * @param strHeader (string) --> header to be shown
    * @param strMessage (string) --> Message to be shown
    * @param callBack (function) --> Callback on close of notice
    */
    showNotice : function(component,strVariant,strHeader,strMessage,callBack){
        component.find('notifyLib').showNotice({
            "variant": strVariant,
            "header": strHeader,
            "message": strMessage,
            closeCallback: callBack
        });
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  toggle the spinner
    * 
    */
    toggleSpinner : function(component){
        component.set("v.isSpinnerActive",!component.get("v.isSpinnerActive"));
    },
    
    /*
    * @author Akshay Mohan
    * @date   01-06-2018
    * @description  redirect to a url
    * @param strRedirectURL (string) --> redirection url
    */
    redirectToPageURL : function(strRedirectURL){
        //redirects to the page URL based on URL passed
        this.consoleLog("redirectToPageURL: " + strRedirectURL);
        let strURL = decodeURIComponent(strRedirectURL);
        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": strURL
        });
        urlEvent.fire();
    },
    
    /*
    * @author Akshay Mohan
    * @date   07-06-2018
    * @description  sort the JSON list based on field, sort direction and a parser
    * @param strField (string) --> Field to be sorted
    * @param booReverse (boolean) --> boolean to indicate direction
    * @param primer (function) --> parsing function
    */
    sortBy: function (strField, booReverse, primer) {
        let key = primer ?
            function(x) {return primer(x[strField])} :
            function(x) {return x[strField]};
        booReverse = !booReverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), booReverse * ((a > b) - (b > a));
        }
    },
    /*
    * @author Akshay Mohan
    * @date   18-10-2018
    * @description  copy an object
    * @param obj (object)
    */
    copy: function (obj) {
        return JSON.parse(JSON.stringify(obj));
    },
    /*
    * @author Akshay Mohan
    * @date   16-Oct-2018
    * @description  method to handle dependant picklist change
    * 
    */
    loadDependantValues : function(component,strSelectedValue,strMapName,strTargetPicklist) {
        let mapDependencies = component.get(strMapName);
        this.consoleLog('dependent values',false,mapDependencies[strSelectedValue]);
        component.set(strTargetPicklist,mapDependencies[strSelectedValue]);
    },
    /*
    * @author Akshay Mohan
    * @date   16-Oct-2018
    * @description  method to invalidate input field
    * 
    */
    invalidateInputField : function(component,strFieldName) {
        let inputField = component.find(strFieldName);
        inputField.set('v.validity', {valid:false, badInput :true});
        inputField.showHelpMessageIfInvalid();
    },
    /*
    * @author Pankaj Singla
    * @date   10-Apr-2019
    * @description  method to read query string parameters
    * 
    */
    getURLQueryStringValues: function() {
        try {
            /* Example URL: /s/isd-needs-assessment-domain-selection?attr1=value1&attr2=value2 
            oQueryString will be as follows:
            {"attr1":"value1", "attr2";"value2" }*/            
            let url = document.createElement('a');
            url.href = document.URL;
            //let url = new URL(document.URL);
            let sQueryString = url.search.substring(1);
            //let sQueryString = window.location.search.substring(1);
            let aQueryString = sQueryString.split("&");
            let oQueryString = {};
            oQueryString["PathName"] = url.pathname;
            for(let i=0; i<aQueryString.length; i++)
            {
                let aStr = aQueryString[i].split("=");
                oQueryString[aStr[0]] = aStr[1];
            }
            return oQueryString;
        } catch(e) {
            this.consoleLog(e.stack, true);
        }
    }
    
    
})