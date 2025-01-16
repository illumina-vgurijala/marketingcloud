(
    {
        handleRecordUpdated: function(component, event, helperVar)
        {
            let helper = this;
            let lstWrapGlobalLang = [];
            let childCmp = component.find("idGlblLang");
            helper.callServer(component, "c.loadData", function(response)
            {
                response = JSON.parse(response);
                if (response.booInValidQuote)
                {
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_InvalidQuoteError);
                    return;
                }
                if (response.booQuoteswInValidAcc)
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_ErrorMessage_InValidAccountStatus);
                if (response.booInReview)
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_ErrorMessage_PPM_InReview);
                if (response.booApproved)
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_ErrorMessage_PPM_Approved);
                if (response.booAccepted)
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_ErrorMessage_PPM_Accepted);
                if (response.booDenied)
                    helper.showErrorAndQuit(component, helper, response.mapUiLabels.UI_ErrorMessage_PPM_AcceptPrQuote);
                component.set('v.lstPostPrimaryMsg', response.lstPstPricingMsg);
                component.set('v.strPostPrimaryMsg', response.strPpm);
                component.set('v.mapLabels', response.mapUiLabels);
                //DCP-21934: get all non standard picklist values for all langauges
                let setNonStandardPicklistValues=new Set();
                response.setNonStandardPicklistValues.forEach(function(iValue, iIndex){
                    setNonStandardPicklistValues.add(iValue);
                });
                component.set('v.setNonStandardPicklistValues', setNonStandardPicklistValues);
                childCmp.set("v.booIsTextArea",setNonStandardPicklistValues.has(response.strPpm));
                component.set('v.booDisablePostpricingList', response.booDisablePostpricingList);
                let lstGlobalLanguage = [];
                if (response.strGlLang)
                    lstGlobalLanguage = response.strGlLang;
                childCmp.set('v.lstStrTemp', JSON.parse(JSON.stringify(lstGlobalLanguage)));
                lstGlobalLanguage.forEach(function(iValue, iIndex)
                {
                    if (iValue.sType == 'static')
                    {
                        iValue.sValue = iValue.sValue.replace(/\n|\r\n|\r/g, '<br/>');
                    }
    
                    lstWrapGlobalLang.push(iValue);
                });
                component.set('v.lstGlobalLanguage', lstWrapGlobalLang);
                component.set('v.booIsPageLoaded', true);
            },
            {
                "strProposalId": component.get("v.recordId")
            });
        },
    
        validate: function(component, event)
        {
            let helper = this;
            let sppmVal = component.get("v.strPostPrimaryMsg");
            //DCP-25211 change
            if($A.util.isEmpty(sppmVal)){
                helper.clearPPM(component,helper);
                return;
            }
            let lstGlobalLanguage = [];
            let childCmp = component.find("idGlblLang");
            sppmVal = component.get("v.strPostPrimaryMsg");
            let sProposalId = component.get("v.recordId");
            // call the aura:method in the child component
            let strReturnValue = childCmp.validate(component, sProposalId, sppmVal);
            if (strReturnValue != 'error')
            {
                this.save(component, event, strReturnValue);
            }
    
        },

        //DCP-25211 change
        clearPPM: function(component, helper)
        {
            helper.consoleLog('Clearing PPM');
            let objQuote = component.get("v.objTargetQuote");
            objQuote.Post_Pricing_Message_List__c=null;
            objQuote.Post_Pricing_Message__c=null;
            helper.consoleLog('objQuote: ',false,objQuote);
            helper.toggleSpinner(component.getSuper());
            let quoteRecHandler = component.find("quoteRecordHandler");
            helper.consoleLog('quoteRecHandler: ',false,quoteRecHandler);
            quoteRecHandler.saveRecord($A.getCallback(function(saveResult) {
                setTimeout(function(){
                            helper.showSuccessToast('Cleared Post Pricing Message');
                            helper.toggleSpinner(component.getSuper());
                        }, '200');
                helper.redirectToPageURL('/' + component.get("v.recordId"));
            }));
            
        },
    
        save: function(component, event, strReturnValue)
        {
            let helper = this;
            let sProposalId = component.get("v.recordId");
            let sPpmVal = component.get("v.strPostPrimaryMsg");
            helper.callServer(component, "c.saveProposal", function(response)
            {
                if (response != 'Successfully Updated')
                {
                    helper.showErrorToast(response, '200');
                }
                else
                {
                    setTimeout(function()
                    {
                        helper.showSuccessToast(response);
                    }, '200')
                    helper.redirectToPageURL('/' + sProposalId);
                }
            },
            {
                "strProposalId": sProposalId,
                "strPpmVal": sPpmVal,
                "strGlobalLang": strReturnValue
            });
        },
    
        showErrorAndQuit: function(component, helper, strMessage)
        {
            setTimeout(function()
            {
                helper.showErrorToast(strMessage);
            }, '200')
            helper.redirectToPageURL('/' + component.get('v.recordId'));
        }
    })