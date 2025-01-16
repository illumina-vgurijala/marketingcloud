/**
*    @author Rishab Wali
*    @date   2020-05-23
*    @description  DCP-34910 Web Service Resceiver Class
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rishab Wali                 2020-05-23           Initial Version
*    Prabhsimran Singh           2020-06-12           DCP-37888 Logic for generate large cart.
*    Ashwin Kumar                25-May-2021          INC0321438 - ApttusLineItemsSelector.selectLineItemsByConfigId param updated from Id to Set<Id>
*    Aman Tyagi                  31-Mar-2022          CodeScan Fixes
*    ------------------------------------------------------------------------------------                  
*/
@RestResource(urlMapping='/ValidateAsyncInterface/')
global without sharing class RealTimePricingResponseReciever {
    
    public static String validationIdString = '';    
    public static String validationId = '';
    public static String quoteId = '';
    public static String productConfigId = '';
    public static String triggerType = '';    
    public static final String CHECKPRICECLASSNAME = 'ApttusCheckPriceController';
    public static final String JSONSTRINGRESPONSE = 'JSON Response -- ';
    public static final String VALIDATECARTQUOTE = 'Validate cart for quote ';
    public static final String NOINPUTRECIEVED = 'No input recieved';
    public static final String VALIDATE = 'validate';
    public static final String OLDREQUESTMESSAGE = 'Response from Old/OutDated request.';
    public static final String TEXTIDZLQT = 'ZLQT';
	
    public static String quoteValidationId = '';
    public static final String GENERATEQUOTECLASSNAME = 'ApttusGenerateQuoteController';
    public static final String GENERATECARTQUOTE = 'Generate cart for quote ';

    @HttpPost
    /*
    * @Author: Rishab Wali
    * @Description : this method has logic for update the cart
    * @param : null
    * @return : void
    */
    global static void updateCart() 
    {
        String strResponseBody = parseQuoteResponse(RestContext.request);
        RealtimePricingResponse objRTPResp = parseQuoteResponse(strResponseBody);

        try{
        if (objRTPResp.NAVHDRTOTXT == null)
            return;

         for (RealtimePricingResponse.LineItem ex : objRTPResp.NAVHDRTOTXT.results)
         {
             if(ex.TextId == TEXTIDZLQT) //Condition satisfies only once as ZLQT is for validation id only
                 validationIdString = ex.TextLine;
         }

        if (String.isBlank(validationIdString))
            return;

        String strValidationIdResp = validationIdString.substringBetween('|');
        validationId = strValidationIdResp.substringBefore('-');
        triggerType = validationIdString.substringAfterLast('|');
        if (triggerType == VALIDATE)
        {
            productConfigId = strValidationIdResp.substringBetween('-', '*');
            quoteId = strValidationIdResp.substringAfterLast('*');
            Apttus_Config2__ProductConfiguration__c objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id> {productConfigId})[0];

            Apttus_Proposal__Proposal__c objQuotation = getQuotation(quoteId);

            if(objConfiguration.Validation_Number__c != Integer.valueOf(validationId)+1 
               || objQuotation.Validation_In_Progress__c == false)
            {
                //Log Creation
                ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + objQuotation.Name + strResponseBody);
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,OLDREQUESTMESSAGE,objQuotation.Id);
                return;
            }
            
			List<Apttus_Config2__LineItem__c> lstLineItems = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {productConfigId});  //INC0321438
            Map<String,Apttus_Config2__LineItem__c> lineItemNameToLineItemMap = new Map<String,Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__LineItem__c li : lstLineItems)
            {
                lineItemNameToLineItemMap.put(li.Name,li);
            }
            RealtimePricingRequestGenerator.lineNameToLineItem = lineItemNameToLineItemMap;

            if(!Test.isRunningTest())
            RealtimePricingResponseParser.parser(productConfigId, strResponseBody);
            
            //Update Quotation
            updateQuotation(objQuotation);
            
            //Log Creation
            ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + objQuotation.Name + strResponseBody);
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,JSONSTRINGRESPONSE + strResponseBody, objQuotation.Id);
        }
		//DCP-37888 logic for generate large cart.
        else
        {
            quoteId = strValidationIdResp.substringAfterLast('-');
            List<String> lstIds = strValidationIdResp.split('-');
            quoteValidationId = lstIds[0];
            Apttus_Proposal__Proposal__c objQuotation = getQuotation(quoteId);
            //Checking if validation id not matches with the response validation id
            if(objQuotation.Last_Validation_Id__c != Integer.valueOf(quoteValidationId)+1 || 
               objQuotation.Generate_In_Progress__c == false)
            {
                //Log Creation
                ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(GENERATEQUOTECLASSNAME);
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,GENERATECARTQUOTE + objQuotation.Name + strResponseBody);
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,OLDREQUESTMESSAGE,objQuotation.Id);
                return;
            }
			
            //Setting up value of class members for large cart.
                ApttusGenerateQuoteController instantiated = new ApttusGenerateQuoteController(quoteId);
                ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strResponseBody);
                ApttusGenerateQuoteController.objQuote = new ApttusProposalsSelector().selectProposalById(quoteId);
                List<Apttus_Proposal__Proposal_Line_Item__c> lstQuoteLineItem = new ApttusProposalLineItemsSelector().selectByQuoteId(new set<ID>{quoteId});
                for(Apttus_Proposal__Proposal_Line_Item__c objCartLine: lstQuoteLineItem){
                    ApttusGenerateQuoteController.lineNameToLineItem.put(objCartLine.name,objCartLine);
                }
				//Sendin response for processing.
                ApttusGenerateQuoteController.generateQuoteResponseCalculation(strResponseBody,log);
				//Creating log for successful response.
                if(!ApttusGenerateQuoteController.boolHasError){                    
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,strResponseBody, quoteId);
                }
                //Update Quotation
                updateQuotationGenerate(objQuotation);            
        }
       
    }
    Catch(Exception e)
    {
        string quotationName = '';
        string quotationId = '';
        if(quoteId != '')
        {
            Apttus_Proposal__Proposal__c objQuotation = getQuotation(quoteId);
            quotationName = objQuotation.Name;
            quotationId = objQuotation.Id;
            updateQuotation(objQuotation);
        }
            ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + quotationName + strResponseBody);
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,e.getLineNumber() +'-'+ e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(), quotationId);
    }
    }

    private static String parseQuoteResponse(RestRequest request)
    {
        if (String.isBlank(request.requestBody.toString()))
        {
            throw new UtilsRest.InterfaceException(NOINPUTRECIEVED);
        }

        String strResponseBody = request.requestBody.toString();
        return strResponseBody;
    }

    private static RealtimePricingResponse parseQuoteResponse(String strResponseBody)
    {
        Map<String, Object> parseJsonResponse = (Map<String, Object>)Json.deserializeUntyped(strResponseBody);
        Object objResp = parseJsonResponse.get('d');
        String serializedResp = JSON.serialize(objResp);
        RealtimePricingResponse objRTPResp = (RealtimePricingResponse) JSON.deserialize(serializedResp, RealtimePricingResponse.class);
        return objRTPResp;
    }

    private static void updateQuotation(Apttus_Proposal__Proposal__c objQuotation)
    {
        objQuotation.Validation_In_Progress__c = false;
        objQuotation.Async_Validation_Complete__c = true;
        update objQuotation;
    }
	
	//DCP-37888 Method to update the quotation when response received for generate large cart.
    private static void updateQuotationGenerate(Apttus_Proposal__Proposal__c objQuotation)
    {
        objQuotation.Generate_In_Progress__c = false;        
        objQuotation.Async_Generation_Complete__c = true;   
        if(!ApttusGenerateQuoteController.boolHasError)
            objQuotation.Last_Generate_Success__c = system.now();  
        update objQuotation;
    }

    private static Apttus_Proposal__Proposal__c getQuotation(Id quoteId)
    {
        ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.selectProposalById(quoteId);
        return objQuotation;
    }

}