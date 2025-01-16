/**
*    @author Kushagra Desai
*    @date  10-Dec-2019
*    @description   Controller class for Validate agreement interface
*    @Test Class for above 87% coverage.
       -TestApttusAgreementValidateController
*    @Test Class for atleast 75% coverage.
      -TestApttusAgreementValidateController
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------
*    *    Developer                      Date                Description
 *    Kushagra Desai                 27-Jan-2020             Activate Agreement support
 *    Kushagra Desai                 5-Jan-2020              Cancel Agreeement Support
 *    Kushagra Desai                 4-Feb-2020              Added support for Terminate
 *    Kushagra Desai                    19-Feb-2020             Start and end date update logic
 *    Kushagra Desai                    24-Feb-2020             Start and end date update logic for Activate
 *    Kushagra Desai                    26-Feb-2020             Start and end date update logic for Terminate
 *    Joshith K                      26-Nov-2020             TASK0537090-remove batch call on Agreement Activate.
 *    Joshith K                      28-Jan-2021             TASK0558698- check agreement is already activated or not.
 *    Prem Ranjan                    25-April-2022           CodeScan Fix:Avoid Literals in If condition
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Nesar Mohan                    01-Apr-2022             CodeScan Fix - Code Comments
 *    Nishan Shetty                  23-May-2022             DCP-50962 [Ilib Batch Manager Implementation and Logging Framework]
 *    Maruthi                        20-Sep-2022             DCP-56218 updated checkErrors
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusAgreementErrorHandler {
    public static Map<String,String> mapLineItemToId = new Map<String,String>();
    public static final String VALUE_E = 'E';
    public static final String VALUE_S = 'S';
    public final static String LOG_TITLE = 'ApttusAgreementErrorHandler';

    //Codescan - Duplicate Literals Fix
    public static final String STRING_ZERO_VALUE = '{0}';
    /**
    *  @author      : Kushagra Desai
    *  @description : Method to insert error
    *  @param       : Error Wrapper and Orgin
    *  @return      : String
    */
    public static string checkErrors(ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper ValidateErrorWrapper,String origin){
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementsByNumber(ValidateErrorWrapper.AgreementNum);

        List<Agreement_Error__c> lstAgrError = new List<Agreement_Error__c>();
        lstAgrError.addall(inActiveAgreementErrors(objAgreement, origin ));
        String strReturn;
        
        if(objAgreement == null)
            throw new UtilsRest.InterfaceException(Label.UI_Message_Agreement_Not_Present);
        if(ValidateErrorWrapper.Status != VALUE_E){
			if(Origin == Label.AgreementActionInterface || Origin == Label.AgreementActionPreValidate) { //DCP-56218
				objAgreement.Validation_Status__c = generateStatus(Origin,ValidateErrorWrapper.Status,objAgreement.Validation_Status__c);
			}
            if(ValidateErrorWrapper.EX_ReturnSet != null) 
                lstAgrError.addall(activeAgreementErrors(ValidateErrorWrapper.EX_ReturnSet.results,objAgreement, Origin));
               if(Origin == Label.AgreementActionPreValidate)
                    strReturn = Label.UI_Agreement_Validation_Status_Completed.replace(STRING_ZERO_VALUE,Origin);
            
            strReturn = Label.UI_Message_Agreement_Validation_Sent.replace(STRING_ZERO_VALUE,Origin);
            
        
    }
        else {
            if(Origin != Label.AgreementActionGenerate){
                objAgreement.Validation_Status__c = generateStatus(Origin,ValidateErrorWrapper.Status,objAgreement.Validation_Status__c);
            }
            lstAgrError.addall(activeAgreementErrors(ValidateErrorWrapper.EX_ReturnSet.results,objAgreement,origin));
            strReturn = Origin == Label.AgreementActionInterface ?Label.UI_ErrorMessage_Agreement_Validation_Failed.replace(STRING_ZERO_VALUE,objAgreement.Validation_Status__c.split(' ')[0]) : label.UI_ErrorMessage_Agreement_Validation_Failed.replace(STRING_ZERO_VALUE,Origin); 
        }
        if(Origin == Label.AgreementActionInterface && objAgreement.Validation_Status__c.contains(Label.AgreementActionValidate) && ValidateErrorWrapper.Status != 'E'){
            if(objAgreement.Apttus__Contract_Start_Date__c < objAgreement.Action_Date__c)
                objAgreement.Apttus__Contract_Start_Date__c = objAgreement.Action_Date__c;
            objAgreement.Is_Validated_Successful__c = true;
                updateLineItems(objAgreement,Label.AgreementActionValidate);
        }
        if(Origin == Label.AgreementActionInterface && objAgreement.Validation_Status__c.contains(Label.AgreementActionActivate) && ValidateErrorWrapper.Status != 'E'){
            if(!callCLMActivate(objAgreement)){
                Apttus__APTS_Agreement__c objAgreementUpdated = new ApttusAgreementSelectors().selectAgreementWithLines(new Set<id>{objAgreement.id})[0];
                objAgreementUpdated.Validation_Status__c = Label.AgreementValidationStatusFailed.replace(STRING_ZERO_VALUE,objAgreement.Validation_Status__c.split(' ')[0]);
                update objAgreementUpdated;
            }
        }
        if(Origin == Label.AgreementActionInterface && objAgreement.Validation_Status__c.contains(Label.AgreementActionCancel) && ValidateErrorWrapper.Status != 'E'){
            objAgreement.Apttus__Status__c = Label.AgreementStatusCancelled;
            objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryCancelled;
            ApttusAgreementActionService.updateParentAgreement(objAgreement,Label.AgreementActionCancel);
        }
        if(Origin == Label.AgreementActionInterface && objAgreement.Validation_Status__c.contains(Label.AgreementActionTerminate) && ValidateErrorWrapper.Status != 'E'){
            objAgreement.Apttus__Status__c = Label.AgreementStatusCategoryTerminated;
            objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryTerminated;
            objAgreement.Apttus__Termination_Date__c = objAgreement.Action_Date__c;
            updateLineItems(objAgreement,Label.AgreementActionTerminate);
        }  
        upsert lstAgrError;
        if(Origin != Label.AgreementActionInterface && Origin != Label.AgreementActionGenerate ){
            objAgreement.Action_Date__c = Date.today();
            update objAgreement;
        }
        if(Origin == Label.AgreementActionInterface && !objAgreement.Validation_Status__c.contains(Label.AgreementActionActivate))
            update objAgreement;
        if(Origin == Label.AgreementActionInterface) return objAgreement.id;
        else return strReturn;
        
    }
    /*
    * @author Kushagra Desai
    * @Description  method to call OOTB Activate
    * @param Sobject Apttus__APTS_Agreement__c
    * @return  Boolean
    */
    public static boolean callCLMActivate(Apttus__APTS_Agreement__c objAgreement){
        ilib_LogEvent.push(LOG_TITLE+'.callCLMActivate');
        Boolean res = false;
        List<ContentDocumentLink> lstContentDocLink = new ContentDocumentLinksSelector().selectDocumentsWithKey(new Set<String>{objAgreement.id},Label.Attachment_Prefix_Signed);
        List<Apttus__DocumentVersion__c> lstdocuments = new DocumentVersionSelector().getLatestDocumentById(new Set<Id>{objAgreement.id},Label.Attachment_Prefix_Signed);
        List<Id> selectedDocIds = new List<Id> ();
        List<Id> removableDocIds = new List<Id> ();
        
        // Check Files
        if(!lstContentDocLink.isEmpty()){
            for(ContentDocumentLink doc :lstContentDocLink){
                selectedDocIds.add(doc.ContentDocument.id); 
            }               
        }
        // Check Document Version
        else if(!lstdocuments.isEmpty()){
            for(Apttus__DocumentVersion__c doc :lstdocuments){
                selectedDocIds.add(doc.Apttus__LatestVersionId__r.Apttus__ContentId__c);
                }
        }
        //TASK0558698- check agreement is already activated or not
        Apttus__APTS_Agreement__c objAgreementToCheck = new ApttusAgreementSelectors().selectAgreements(new Set<id>{objAgreement.id})[0];
        if(objAgreementToCheck.Apttus__Status__c == Label.AgreementStatusActivated
        &&objAgreementToCheck.Apttus__Status_Category__c == Label.AgreementStatusCategoryInEffect){
            ilib_LogEvent.message('Already activated returning-->');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return true;
        }
        else if(!selectedDocIds.isEmpty()){
            res = Apttus.AgreementWebService.activateAgreement(objAgreement.Id, selectedDocIds, removableDocIds);
            ilib_LogEvent.message('CLM Activate-->'+res);
            if(res){
				//Updated below lines for Queuable Interface
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('AgreementActivateButton');
                queueableThread.logAndQueue(new ApttusPublishToContentRepository(objAgreement.Id,selectedDocIds), 'ApttusPublishToContentRepository', 'execute');
                ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SALES);
			}            
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return res;
    }
    /**
    *  @author      : Kushagra Desai
    *  @description : Method to insert error with flag as Active
    *  @param       : Error Wrapper
    *  @return      : List<Agreement_Error__c>
    */
    public static List<Agreement_Error__c> activeAgreementErrors(List<ApttusAgreementValidateErrorWrapper.ReturnSet> lstrtset,Apttus__APTS_Agreement__c objAgreement,string origin ){
        List<Agreement_Error__c> lstAgrErrorNew = new List<Agreement_Error__c>();
        for(Apttus__AgreementLineItem__c agLI : new ApttusAgreementLineItemSelectors().selectAgreementLineItem(new Set<Id>{objAgreement.id})){
                mapLineItemToId.put(agLI.Name,agLI.id);
            }
        for(ApttusAgreementValidateErrorWrapper.ReturnSet rtset : lstrtset){
            if(rtset.Type != VALUE_S){
                Agreement_Error__c ae = new Agreement_Error__c(
                    Agreement__c = objAgreement.id,
                    Agreement_Line_Item__c = mapLineItemToId.get(rtset.LineItemId),
                    Message__c = rtset.Message,
                    Message_Number__c = rtset.MsgNumber,
                    MsgId__c = rtset.MsgId,
                    Status__c = Label.AgreementErrorStatusActive,
                    Message_Type__c = rtset.Type == 'E' ? Label.AgreementErrorTypeError :(rtset.Type == 'W' ? Label.AgreementErrorTypeWarning : Label.AgreementErrorTypeInfo),
                    Generate_Error__c = origin == Label.AgreementActionGenerate ? true : false
                );
                lstAgrErrorNew.add(ae);
            }
        }
        return lstAgrErrorNew;
    }
    /**
    *  @author      : Kushagra Desai
    *  @description : Inactivate Ols error records on Agreement
    *  @param       : N/A
    *  @return      : List<Agreement_Error__c>
    */
    public static List<Agreement_Error__c> inActiveAgreementErrors(Apttus__APTS_Agreement__c objAgreement,string origin){
        Boolean isGenerateError = origin == Label.AgreementActionGenerate ? True : false;
        List<Agreement_Error__c> lstAgrErrorOld = new AgreementErrorSelector().selectAgreementErrorActiveTrue(objAgreement.id, isGenerateError);
        for(Agreement_Error__c ae : lstAgrErrorOld){
            ae.Status__c = Label.AgreementErrorStatusInactive;
        }
        return lstAgrErrorOld;
    }
    /**
    *  @author      : Kushagra Desai
    *  @description : Dynamic status generation
    *  @param       : N/A
    *  @return      : String
    */
    public static string generateStatus(String strOrigin,String strType,String strValStatus){
        ilib_LogEvent.push(LOG_TITLE+'.generateStatus');
        ilib_LogEvent.message('Status++ -->-'+strOrigin+'  '+strType+' '+strValStatus);
        if(strOrigin == Label.AgreementActionInterface){
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return strType != 'E' ? Label.UI_Agreement_Validation_Status_Completed.replace(STRING_ZERO_VALUE,strValStatus.split(' ')[0]) : Label.AgreementValidationStatusFailed.replace(STRING_ZERO_VALUE,strValStatus.split(' ')[0]);
        }
        else if(strOrigin == Label.AgreementActionPreValidate){
             ilib_LogEvent.pop();
             ilib_LogEvent.emit();
            return strType != 'E' ? Label.UI_Agreement_Validation_Status_Completed.replace(STRING_ZERO_VALUE,strOrigin) : Label.AgreementValidationStatusFailed.replace(STRING_ZERO_VALUE,strOrigin);
        }
        else{
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return strType != 'E' ? label.AgreementValidationStatusInProgress.replace(STRING_ZERO_VALUE,strOrigin) : label.AgreementValidationStatusFailed.replace(STRING_ZERO_VALUE,strOrigin);
        }
    }
    /*
    * @author      : Kushagra Desai
    * @Description : Method to update line items
    * @param       : Apttus__APTS_Agreement__c, String
    * @return      : void
    */
    public static void updateLineItems(Apttus__APTS_Agreement__c objAgreement,String strAction){
        // Logic moved to Batch class
        //START(DCP-50962)-Implementation using Ilib Batch Manager Class.
        ilib_BatchManager.executeBatch(new BatchUpdateAgreementLineItem(objAgreement.id,objAgreement.Action_Date__c,strAction),20);
        //END(DCP-50962)
    }
    /*
    * @author Kushagra Desai
    * @Description generate date for Line Start date
    * @param date
    */
    public static date generateStartDate(Apttus__AgreementLineItem__c agrline,Date dtActionDate){
        Date dtStartDateLocal = agrline.Apttus_CMConfig__StartDate__c;
        Date dtTodaylocal = dtActionDate;
        
        if(dtStartDateLocal != null){
            if(dtStartDateLocal < dtTodaylocal){
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated || agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                    return dtTodaylocal;
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedNo && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated || agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusNew))
                    return dtTodaylocal;
                return null;
            }
            else if(dtStartDateLocal >= dtTodaylocal){
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated || agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                    return null;
                return null;
            }
            else
            return dtStartDateLocal;
        }
        return null;
    }
    
    /*
    * @author Kushagra Desai
    * @Description generate date for Line End date
    * @param date
    */
    public static date generateEndDate(Apttus__AgreementLineItem__c agrline,Date dtActionDate){
        Date dtEndDatelocal = agrline.Apttus_CMConfig__EndDate__c;
        Date dtStartDateLocal = agrline.Apttus_CMConfig__StartDate__c;
        Date dtTodaylocal = dtActionDate;
        if(dtStartDateLocal != null && dtEndDatelocal != null){
            if(dtStartDateLocal < dtTodaylocal){
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated || agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                    return dtTodaylocal;
                return null;
            }
            else if(dtStartDateLocal >= dtTodaylocal){
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated || agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                    return null;
                return null;
            }
            else
            return dtEndDatelocal;
        }
        return null;
    }
     /*
    * @author Kushagra Desai
    * @Description generate date for Line End date (Terminate)
    * @param 
    * @return date
    */
    public static Date generateTerminateEndDate(Apttus__AgreementLineItem__c agrline,Date dtActionDate){
        Date dtEndDatelocal = agrline.Apttus_CMConfig__EndDate__c;
        Date dtStartDateLocal = agrline.Apttus_CMConfig__StartDate__c;
        Date dtTodaylocal = dtActionDate;
        
        if(dtStartDateLocal != null && dtEndDatelocal != null){
            if(dtEndDatelocal >= dtTodaylocal && dtStartDateLocal <= dtTodaylocal && agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedNo){
                return dtTodaylocal;
            }
            else
                return null;
        }
        return null;
    }
}