/**
 *    @author Arquimidez Mora
 *    @date   30-10-2024
 *    @description Class to add errors while the Web Genereated Opportunity is creating
 *    @Tested By: TestQuoteCreationAPIErrorHandler
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Arquimidez Mora                 06 Nov 2024          Initial Version
 */
public with sharing class QuoteCreationAPIErrorHandler {
    public List<ErrorItemWrapper> lstErrors = new List<ErrorItemWrapper>();
    public static final String STRING_OPPORTUNITY_STEP = 'Opportunity Creation';
    public static final String STRING_CART_CREATION = 'Cart Creation';
    public static final String STRING_CART_VALIDATE = 'Cart Validation';
    public static final String STRING_FINALIZE_CART = 'Finalize Cart';
    public static final String STRING_SYNC_CART = 'Sync Cart';

    /**
    * @description Method to add errors when the Opportunity is creating
    * @author Arquimidez Mora | 11-05-2024 
    * @param strErrorCode 
    * @param strMessage 
    **/
    public void addError(String strErrorCode, String strMessage){
        ErrorItemWrapper objErrorItemWrapper = new ErrorItemWrapper(strErrorCode, strMessage);
        lstErrors.add(objErrorItemWrapper);
    }

    /**
    * @description Method to validate email address is in correct format
    * @author Arquimidez Mora | 11-05-2024 
    * @param email 
    * @return Boolean 
    **/
    public Boolean validateEmailAddress(String email) {
		String emailRegex = '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$'; 
		Pattern myPattern = Pattern.compile(emailRegex);
		Matcher myMatcher = myPattern.matcher(email);
		return myMatcher.matches();	
	}

    /**
    * @description Method to log succes or errors of Web Generated Quote Request
    * @author Arquimidez Mora | 11-11-2024 
    * @param lstCartCreationWrapper 
    * @return List<QuoteCreationAPIOppCartWrapper> 
    **/
    public static List<QuoteCreationAPIOppCartWrapper> insertInterfaceLog(List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper, String strStep) {
        List<Interface_Log__c> lstInterfaceLogs = new List<Interface_Log__c>();
        RestOpportunityQuoteCreationDataReceiver instantiated = new RestOpportunityQuoteCreationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        List<QuoteCreationAPIOppCartWrapper> lstErrorRecords = new List<QuoteCreationAPIOppCartWrapper>();
        
        for(QuoteCreationAPIOppCartWrapper objWrapper : lstCartCreationWrapper){
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, objWrapper.strJsonPayload );
            String strRelatedRecord = '';
            String strMessage = '';
            if(strStep == STRING_OPPORTUNITY_STEP){
                strRelatedRecord = objWrapper.strOpportunityId;
            }else if(strStep == STRING_CART_CREATION || strStep == STRING_CART_VALIDATE || strStep == STRING_SYNC_CART || strStep == STRING_FINALIZE_CART){
                strRelatedRecord = objWrapper.objRequestWrapper.quoteId;
            }
            if(objWrapper.objErrorHandler.lstErrors != null && objWrapper.objErrorHandler.lstErrors.size() > 0){
                strMessage = strStep + ' -- ' + objWrapper.objErrorHandler.lstErrors.toString();
                lstInterfaceLogs.add(createInterfaceLog(log, false, strRelatedRecord, strMessage));
                lstErrorRecords.add(objWrapper);
            }else if(objWrapper.lstSuccessesSteps != null && objWrapper.lstSuccessesSteps.size() >0){
                strMessage = objWrapper.lstSuccessesSteps + ' -- Completed' ;
                lstInterfaceLogs.add(createInterfaceLog(log, true, strRelatedRecord, strMessage));
            }
        }
        if(!lstInterfaceLogs.isEmpty()){
            insert lstInterfaceLogs;
        }
        return lstErrorRecords;
	}

    private static Interface_Log__c createInterfaceLog(ilib_LogInterface.LogDetails log, Boolean isSuccess, String strRelatedRecord, String strMessage){
        Interface_Log__c objLog = ilib_LogInterface.returnLogRecord(
                                    log,
                                    (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                                    strMessage,
                                    strRelatedRecord,
                                    null
                                );

        return objLog;
    }

    /**
     * @description: Wrapper for error code and message.
     */
    public class ErrorItemWrapper{
       public String errorCode;
       public String message;

        /**Constructor */
        public ErrorItemWrapper(String strErrorCode, String strMessage){
            this.errorCode = strErrorCode;
            this.message = strMessage;
        }

    }
}