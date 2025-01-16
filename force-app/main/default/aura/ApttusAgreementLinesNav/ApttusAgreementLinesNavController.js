({
  init: function (component, event, helper) {
    let recordid = component.get("v.recordId");
    if (!recordid){
      let myPageRef = component.get("v.pageReference");
      let agreementId = myPageRef.state.c__agreementId;
      console.log('see'+JSON.stringify(myPageRef));
      component.set("v.recordId",agreementId);
      recordid=agreementId;
        if(!agreementId){ //codescanfix-A conditionally executed single line should be denoted by indentation
          return;
        }
    }
    
    
    
    console.log("$%$%$%$--" + component.get("v.recordId"));
    let boolLineItemsFound = undefined;
    helper.callServer(component,"c.getAgreementAura", function(response) 
    {
        console.log("@@@@@ response from server for getAgreement method, debug 1: " +JSON.stringify(response));
        
            console.log('@@@@ parseINT Value: '+parseInt(response.Number_Of_Agreement_Line_Items__c));
            if (parseInt(response.Number_Of_Agreement_Line_Items__c) === 0) 
            {
                let message = 'Please add agreement line items and then try again';
                let duration = 200;
                let mode = 'dismissible';
                //helper.showErrorToast(message,mode,duration);
                boolLineItemsFound = false;
                setTimeout(function () {
                helper.showErrorToast(message, mode, duration);
                }, '200');
                helper.redirectToPageURL("/" + component.get("v.recordId"));
                return;
            }
            else {
                console.log('@@@@ inside else block,calling redirectToAppPage');
                boolLineItemsFound = true;
                helper.callServer(component, "c.checkSessionCache",function (response) 
                {
                    response = JSON.parse(response);
                    console.log("(()()(()" + response);
                    helper.consoleLog("Result: ", false, response);
                    let urlEvent = $A.get("e.force:navigateToURL");
                    let urlToNav = "/lightning/n/Agreement_Lines_Detail";
                    urlEvent.setParams({
                    url: urlToNav
                    });
                    urlEvent.fire();
                },
                {
                    recordId: recordid
                }
                );
            }
        
        //console.log('@@@@@ response from server for getAgreement method, debug 1: '+JSON.stringify(response));
        //data = JSON.parse(response);
        //console.log('@@@@@ response from server for getAgreement method, , debug 2: '+data);
        // if (parseInt(response.Number_Of_Agreement_Line_Items__c) === 0) {
        //   var message = "Please add agreement line items and then try again";
        //   var duration = 200;
        //   var mode = "dismissible";
        //   //helper.showErrorToast(message,mode,duration);
        //   boolLineItemsFound = false;
        //   setTimeout(function () {
        //     helper.showErrorToast(message, mode, duration);
        //   }, "200");
        //   helper.redirectToPageURL("/" + component.get("v.recordId"));
        //   return;
        // } else {
        //   boolLineItemsFound = true;
        // }
      },
      {
        agreementId: recordid
      }
    );
    console.log("@@@@ boolLineItemsFound before if: " + boolLineItemsFound);
    if (boolLineItemsFound) {
      let params = {
        recordId: recordid
      };
      console.log("@@@@ boolLineItemsFound: " + boolLineItemsFound);
      console.log("before calling redirect to app page");
      //redirectToAppPage(params);
    }
  },
  redirectToAppPage: function (params) {
    console.log("redirect to app page called ");
    helper.callServer(component, "c.checkSessionCache",function (response) 
    {
        response = JSON.parse(response);
        console.log("(()()(()" + response);
        helper.consoleLog("Result: ", false, response);
        let urlEvent = $A.get("e.force:navigateToURL");
        let urlToNav = "/lightning/n/Agreement_Lines_Detail";
        urlEvent.setParams({
          url: urlToNav
        });
        urlEvent.fire();
      },
      params
    );
  }
});