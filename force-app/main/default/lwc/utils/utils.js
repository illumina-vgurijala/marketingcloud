import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import consoleLogger from '@salesforce/label/c.UI_Console_Logger';
import ERROR_OBJECT from '@salesforce/schema/Exception_Log__c';
import ERROR_LINE from '@salesforce/schema/Exception_Log__c.Line_Number__c';
import ERROR_MESSAGE from '@salesforce/schema/Exception_Log__c.Message__c';
import ERROR_SOURCE from '@salesforce/schema/Exception_Log__c.Source__c';
import ERROR_STACK from '@salesforce/schema/Exception_Log__c.Stack_Trace__c';
import ERROR_TYPE from '@salesforce/schema/Exception_Log__c.Type__c';
import { createRecord } from 'lightning/uiRecordApi';

let LOG_LEVEL;
//initialize Utility values
const initialize=()=>{
    LOG_LEVEL="NONE";
    var levels= consoleLogger.split("|");
    if(levels[0]==="Yes")
        LOG_LEVEL="ERROR";
    if(levels[1]==="Yes")
        LOG_LEVEL="DEBUG";
};
//generic call server method
const callServer=(serverMethod,params,callBack,errorCallBack,bypassShowToast)=>{
    var strCallStack
    if(isNull(bypassShowToast)){
        bypassShowToast = false;
    }
    try {   throw new Error();  }   catch(e)    {   strCallStack = String(e.stack);   }
    
    serverMethod(params).then(result=>callBack(result))
        .catch(error => {
            handleError(error,strCallStack,params,bypassShowToast);
            if(errorCallBack)
                errorCallBack(error);
        });
};
//handle error
const handleError=(error,strCallStack,params,bypassShowToast)=>{
    consoleError('error:',error);
    const fields = {};
    var strTrace = strCallStack.split('\n')[2]
    var startIndex = strTrace.indexOf('/modules/c/')+ '/modules/c/'.length;
    var endIndex=strTrace.indexOf('.js:')+'.js:';
    fields[ERROR_SOURCE.fieldApiName] = strTrace.substring(startIndex).replace(')','');
    var lstTemp = fields[ERROR_SOURCE.fieldApiName].replace(strTrace.substring(startIndex,endIndex),'').split(':');
    fields[ERROR_LINE.fieldApiName] = lstTemp[lstTemp.length-1];
    if(typeof error =='object'){
        var e = error.body;
        var message = '';
        let fieldErrors = false;
        if(isNotNull(e.exceptionType) || isNotNull(e.message) || isNotNull(e.stackTrace)){
            if(isNotNull(e.exceptionType))
                message += 'ExceptionType:'+e.exceptionType+' ';
            if(isNotNull(e.message))
                message += 'Message:'+e.message+' ';
            if(isNotNull(e.stackTrace))
                message += 'StackTrace:'+e.stackTrace+' ';
            fields[ERROR_TYPE.fieldApiName] = e.exceptionType;
            fields[ERROR_MESSAGE.fieldApiName] = e.message;
            fields[ERROR_STACK.fieldApiName] = e.stackTrace;
        }else if(isNotNull(e.fieldErrors)){
            let error_type = 'Field Errors';
            let error_message = '';
            Object.keys(e.fieldErrors).forEach(fieldName => {
                e.fieldErrors[fieldName].forEach(issue => {
                    fieldErrors = true;
                    error_message += 'Field: ' + fieldName + '\nstatusCode: '+ issue.statusCode + '\nMessage: ' + issue.message + '\n\n';
                    if(!bypassShowToast){
                    showErrorToast(fieldName.substring(0, fieldName.length - 3) + ': ' + issue.message);
                    }
                });
            });
            
            fields[ERROR_TYPE.fieldApiName] = error_type;
            fields[ERROR_MESSAGE.fieldApiName] = error_message;
        }else if(isNotNull(e.pageErrors) && isNotEmpty(e.pageErrors)){
            var pageError = e.pageErrors[0];
            message = 'statusCode: '+pageError.statusCode+'\nMessage: '+pageError.message;
            fields[ERROR_TYPE.fieldApiName] = pageError.statusCode;
            fields[ERROR_MESSAGE.fieldApiName] = pageError.message;
        }else{
            fields[ERROR_MESSAGE.fieldApiName] = "Params:\n"+JSON.stringify(params);
            fields[ERROR_TYPE.fieldApiName] = "JavaScript";
            fields[ERROR_STACK.fieldApiName] = JSON.stringify(error);
        }
        if(isNotBlank(message)&& !bypassShowToast) {
            showErrorToast(message);
        }
        else if(!fieldErrors && !bypassShowToast){
            showErrorToast(error); 
        }
    }else{
        if(!bypassShowToast){
            showErrorToast(error);
        }
        fields[ERROR_MESSAGE.fieldApiName] = "Params:\n"+JSON.stringify(params);
        fields[ERROR_TYPE.fieldApiName] = "JavaScript";
        fields[ERROR_STACK.fieldApiName] = JSON.stringify(error);
    }
    const errorLog = { apiName: ERROR_OBJECT.objectApiName, fields };
    createRecord(errorLog)
            .then(errorRecord => {
                consoleError('Error log Id: '+errorRecord.id);
            })
            .catch(error => {consoleError('Error creating log record',error);});
        
};
//consle logging method
const consoleLog=(strMessage,obj)=>{
    if(isBlank(LOG_LEVEL))
        initialize();
    if(LOG_LEVEL==="DEBUG"){
        if(obj)
            console.log(strMessage,obj);
        else
            console.log(strMessage);
    }
        
}
//console error method
const consoleError=(strMessage,obj)=>{
    if(isBlank(LOG_LEVEL))
        initialize();
    if(LOG_LEVEL==="ERROR"||LOG_LEVEL==="DEBUG"){
        if(obj)
            console.error(strMessage,obj);
        else
            console.error(strMessage);
    }
        
}
//success toast
const showSuccessToast=(strMessage,strMode)=>{
    showToast('Success',strMessage,'success',strMode);
};
//error toast
const showErrorToast=(strMessage,strMode)=>{
    showToast('Error',strMessage,'error',strMode);
};
//Warning toast
const showWarningToast=(strMessage,strMode)=>{
    showToast('Warning',strMessage,'warning',strMode);
};
//generic toast message
const showToast=(strTitle,strMessage,strVariant,strMode,strMessageData)=>{
    if(isNull(strTitle) || isNull(strMessage) || isNull(strVariant)){
        showErrorToast('Basic attributes not found for toast!');
        return;
    }
    if(isNull(strMode))
        strMode='dismissable';
    const evt = new ShowToastEvent({
        title: strTitle,
        message: strMessage,
        messageData: strMessageData,
        variant: strVariant,
        mode: strMode
    });
    dispatchEvent(evt);
};
//check if string is blank
const isBlank=(strValue)=>{
    if(isNull(strValue) || strValue.trim()==='')
        return true;
    else
        return false;
};
//check if string is not blank
const isNotBlank=(strValue)=>{
    return !isBlank(strValue);
};
//Check if null
const isNull=(objValue)=>{
    if(objValue===null||objValue===undefined)
        return true;
    else
        return false;
}
//Check if not null
const isNotNull=(objValue)=>{
    return !isNull(objValue);
}
//Check if Array is Empty
const isEmpty=(objValue)=>{
    if(isNull(objValue)||!Array.isArray(objValue)|| objValue.length<1)
        return true;
    else
        return false;
}
//Check Array is not empty
const isNotEmpty=(objValue)=>{
    return !isEmpty(objValue);
}
//sort a list
const sortBy=(field, reverse, primer)=>{
    const key = primer
        ? function(x) {
              return primer(x[field]);
          }
        : function(x) {
              return x[field];
          };

    return function(a, b) {
        a = key(a);
        b = key(b);
        return reverse * ((a > b) - (b > a));
    };
}
// Generic Event dispatcher
const genericEvent=(eventName,evtDetails,context)=>{
    consoleLog('Details :',eventName);
    const evt = new CustomEvent(
        eventName, {
            detail: evtDetails
        }
    );
    context.dispatchEvent(evt);
}
/*Filter Method
* Description : Funtion to return subset of array
* Parameter : arr : Array to be reduced ; value : length of subset
*/
const arraySubset=(arr,value) => {
    return arr.filter(function (ele, index) {
        return index < value;
    });
}
/*Filter Method
* Description : Funtion to remove existing selected value from picklist value set
* Parameter : arr : picklist option value ; arr2 : array of option to be removed
*/
const arrayRemove=(arr,arr2) => {
    return arr.filter(function (ele) {
        return !arr2.includes(ele.value);
    });
}
/*Filter Method
* Description : Funtion to remove element from index
* Parameter : arr : array of value ; value : index to be removed
*/
const arrayIndexRemove=(arr,value) => {
    return arr.filter(function (ele, index) {
        return index != value;
    });
}
//get URL Parameters in encoded format to set on a URL
const getEncodedParams=(strKey,strValue) => {
    return encodeURIComponent(strKey)+'='+encodeURIComponent(strValue);
}

// Fetch URL Query String
const getURLQueryStringValues=()=>{
    try {
        /* Example URL: /s/isd-needs-assessment-domain-selection?attr1=value1&attr2=value2 
        oQueryString will be as follows:
        {"attr1":"value1", "attr2";"value2" }*/            
        var url = document.createElement('a');
        url.href = document.URL;
        //var url = new URL(document.URL);
        var sQueryString = url.search.substring(1);
        //var sQueryString = window.location.search.substring(1);
        var aQueryString = sQueryString.split("&");
        var oQueryString = {};
        oQueryString["PathName"] = url.pathname;
        for(var i=0; i<aQueryString.length; i++)
        {
            var aStr = aQueryString[i].split("=");
            oQueryString[aStr[0]] = aStr[1];
        }
        return oQueryString;
    } catch(e) {
        this.consoleLog(e.stack, true);
    }
}

export {consoleError,consoleLog,showSuccessToast,showErrorToast,showToast,isBlank,isNotBlank,sortBy,callServer,isNotNull,isNull,isEmpty,isNotEmpty,genericEvent,arraySubset,arrayRemove,arrayIndexRemove,getURLQueryStringValues,showWarningToast,getEncodedParams};