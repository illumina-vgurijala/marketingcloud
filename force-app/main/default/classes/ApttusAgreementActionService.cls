/**
*    @author Kushagra Desai
*    @date  4-Feb-2020
*    @description   Service class for agreement interface
*    Modification Log:
*   Test class for 90% coverage: TestApttusAgreementValidateController, TestAgreementOutputParametersForm, TestApttusAgreements,TestOpenOfferagreements
*   Test class for 75% coverage: TestApttusAgreementValidateController.
*    -----------------------------------------------------------------------------------------------------------------
*      Developer                 Date                Description
*      KD                        08-Feb-2020         Added support to update related Agreement
*      KD                        10-Feb-2020         Added support for Generate interface.
*      Kushagra Desai            19-Feb-2020         Start and end date update logic
*      Aman Tyagi                5-April-2022        CodeScan Fixes
*      Nesar Mohan               01-Apr-2022         CodeScan Fix - Code Comments
*      Saddam/Himanshu           02-sep-2022         DCP-54536 Modified sendRequestToSAP() to check the Open Offer error after activate button clicked.
*      Maruthi                   20-sep-2022         DCP-56218 Modified sendRequestToSAP() to check and update validation status.
*      Rishi Sharma              19-Sept-2022        DCP-56529 - Agreements getting stuck with "Terminate In progress" for BatchAutoTerminateAgreements
*      Satya Swain                09 Dec 2022         Added Codescan fix for Variable Naming Convention
*    -----------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusAgreementActionService extends ilib_RestReceiver {
    
    public static final String INTERFACE_NAME = 'Agreement_Validate_Inbound';  //Codescan fix
    public static final String GENERATE_INTERFACE_NAME = 'Agreement_Generate_Inbound'; //Codescan fix
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static final String ERROR = 'Error-';
    public static final String ERROROPENOFFER = 'ErrorOpenOffer'; //DCP-54536
    public static final String APPLICATION_JSON = 'application/json';
    public static final String APTTUS_AGREEMENT_VALIDATE_CONTROLLER = 'ApttusAgreementValidateController';
    
    private static ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper ValidateErrorWrapper;

    /*
    * @author Kushagra Desai
    * @Description Aura method to send validation request to SAP
    * @param String AgreementID
    * @return String Response
    */
    public static string sendRequestToSAP(Apttus__APTS_Agreement__c objAgreement, String action, String strValidationStatus)
    {
        ApttusAgreementActionService instantiated = new ApttusAgreementActionService();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;

        try
        {
            String strJSON = ApttusAgreementValidateController.createJSON(objAgreement, action);
            system.debug('JSON-->' + strJSON);
            if (strJSON == ERROR) {         // getting covered from TestApttusAgreementValidateController.testPastDateForNonOpenOfferAgremeentLineItem()        
                if(action !='PreValidate' || ((action != 'Terminate' || action !='Cancel') && System.IsBatch() != True) ) { //DCP-56218
                    objAgreement.Validation_Status__c = strValidationStatus;
                    update objAgreement;           
                }                   
                return ERROR+Label.UI_Agreement_Validate_Dates_Failure;                
            } else if(strJSON == ERROROPENOFFER && action == Label.AgreementActionActivate) {  // // getting covered from TestOpenOfferAgreements.testAgreementlineitemsIntegration()                              
                objAgreement.Validation_Status__c = strValidationStatus;
                update objAgreement;                           
                return ERROR+Label.UI_Agreement_Validate_Dates_Failure_For_Open_Offer;
            }
            Map<String, String> headerKeyToValue = new Map<String, String>
            {
                'content-type' => APPLICATION_JSON,
                'accept' => APPLICATION_JSON
            };

            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strJSON);
            HttpResponse response = UtilsRest.send(UtilsRest.createHttpRequest(INTERFACE_NAME, 'POST', headerKeyToValue, strJSON));

            if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE)
            {
                objAgreement.Validation_Status__c = action + ' ' + Label.AgreementValidationStatusFailed;
                update objAgreement;
                ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), objAgreement.id);
                ApexExceptions.emit(APTTUS_AGREEMENT_VALIDATE_CONTROLLER, log.logRecordId, response.getBody());
                return 'Error';
            }
            else
            {
                if (response.getBody().contains('REST API service endpoint returned error'))
                {
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), objAgreement.id);
                    ApexExceptions.emit(APTTUS_AGREEMENT_VALIDATE_CONTROLLER, log.logRecordId, response.getBody());
                    return 'Error-';
                }
                else
                {
                    ValidateErrorWrapper = (ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper) System.JSON.deserialize(response.getBody(), ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper.class);
                    ilib_LogInterface.finalizeLog(log,ValidateErrorWrapper.Status == 'E' || ValidateErrorWrapper.Status == null  ?ilib_LogInterface.RESULT_FAIL :  ilib_LogInterface.RESULT_SUCCESS,response.getStatusCode() + response.getBody(), objAgreement.id);
                    ValidateErrorWrapper = (ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper) System.JSON.deserialize(response.getBody(), ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper.class);
                    System.debug('Error Wrapper::::'+ValidateErrorWrapper);
                    return ApttusAgreementErrorHandler.checkErrors(ValidateErrorWrapper,action);
                }
            }

        }
        catch (Exception e)
        {
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'Stack trace           : ' + e.getStackTraceString());
            return e.getMessage();
        }
    }

    /*
    * @author Rishi Sharma
    * @Description DCP-56529 - Future method to send validation request to SAP for terminate from batch
    * @param String action
    * @param Id agrId
    * @return String void
    */
    @future (callout=true)
    public static void sendBatchTerminateRequestToSAP(String action, Id agrId)
    {
  
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(new Set<Id>{agrId})[0];
            sendRequestToSAP(objAgreement, action, objAgreement.Validation_Status__c);
    }


    /*
    *  @author      : Kushagra Desai
    *  @description : Method to update the parent agreement
    *  @param       : Apttus__APTS_Agreement__c, String
    *  @return      : void
    */
    
    public static void updateParentAgreement(Apttus__APTS_Agreement__c objAgr, String action)
    {
        List<Apttus__APTS_Related_Agreement__c> lstRelAgreement = new ApttusRelatedAgreementSelectors().getRelatedAgreementTo(objAgr.id);
        if (!lstRelAgreement.isEmpty())
        {
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(new Set<id>{lstRelAgreement[0].Apttus__APTS_Contract_From__c})[0];

            if (action == Label.AgreementActionCancel)
            {
                objAgreement.Apttus__Status__c = Label.AgreementStatusActivated;
                objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryInEffect;
                update objAgreement;
            }

            if (action == Label.AgreementActionActivate && objAgreement.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Renewed)
            {
                objAgreement.Apttus__Status__c = '';
                objAgreement.Apttus__Status_Category__c = Label.UI_Label_Agreement_Status_Category_Renewed;
                update objAgreement;
            }

            if (action == Label.AgreementActionActivate && objAgreement.Apttus__Status_Category__c == Label.UI_Label_Agreement_Status_Category_Amended) // getting covered from TestOpenOfferAgreements.testAgreementlineitemsIntegration()
            {
                objAgreement.Apttus__Status__c = '';
                objAgreement.Apttus__Status_Category__c = Label.UI_Label_Agreement_Status_Category_Amended;
                update objAgreement;
            }
        }
    }

    /*
    * @author Kushagra Desai
    * @Description Aura method to send Generate request to SAP
    * @param String AgreementID
    * @return String Response
    */
    public static string sendGenerateRequestToSAP(String strJSON, String strAgreementId)
    {
        system.debug('---JSON---'+strJSON);
        ApttusAgreementActionService instantiated = new ApttusAgreementActionService();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strJSON);

        try
        {
            Map<String, String> headerKeyToValue = new Map<String, String>{
                'content-type' => APPLICATION_JSON,
                'accept' => APPLICATION_JSON
            };

            HttpResponse response = UtilsRest.send(UtilsRest.createHttpRequest(GENERATE_INTERFACE_NAME, 'POST', headerKeyToValue, strJSON));

            if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE)
            {
                ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), strAgreementId);
                ApexExceptions.emit(APTTUS_AGREEMENT_VALIDATE_CONTROLLER,log.logRecordId,response.getBody());
                return ERROR;
            }
            else
            {
                if (response.getBody().contains('REST API service endpoint returned error'))
                {
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), strAgreementId);
                    ApexExceptions.emit(APTTUS_AGREEMENT_VALIDATE_CONTROLLER, log.logRecordId, response.getBody());
                    return ERROR;
                }
                else
                {
                    ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, response.getStatusCode() + response.getBody(), strAgreementId);
                    return 'Success-';
                }
            }
        }
        catch (Exception e)
        {
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'Stack trace           : ' + e.getStackTraceString());
            ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_FAIL, e.getMessage(), strAgreementId);
            return ERROR + e.getMessage();
        }
    }

}