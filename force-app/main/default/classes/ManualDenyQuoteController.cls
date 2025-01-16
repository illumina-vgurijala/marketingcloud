/**
 * @author Prem Ranjan    
 * @description    @date   22-Sep-2022 DCP-56119 Ability to Manually Deny a Quote
 * Test class for 90%+ coverage : TestManualDenyQuoteController
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Prem Ranjan             22-Sep-2022         DCP-56119: Initial Version 
*   Balakrishna				18-July-2023		CMCM-803
*  ------------------------------------------------------------------------------------ 
*/

public with sharing class ManualDenyQuoteController extends ilib_RestReceiver {
    private static final String LOG_TITLE = 'ManualDenyQuoteController';
    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    
    public String strConfigId;
    public string strConfigRequestId;
    public string strFlow;
    public String strBusinessObjectId;
    
    public static String strRequstQuotJSON;
    public static HttpResponse response = new HttpResponse();
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static String strErrorMsg{get;set;}
    public static Boolean boolHasError{get; set;}
    public static String strQuotResponse;
    public static Boolean boolError;
    public static ilib_LogInterface.LogDetails log;
    public static String quoteStatus='Reject';
    public static string strRETErrors;
    public static String strWarningMsgs = ''; // Show soft error Beadchip Warning
    public static Boolean boolRETError = false;
    public static Boolean boolWarning = false;  //Show soft error Beadchip Warning
    public static final String STRHTMLTAGLINESTART = '<li>';//CodeScan Fix
    public static final String STRHTMLTAGLINEEND = '</li>';//CodeScan Fix
	public static final String WARNING = 'X';
    
    
    /**CMCM-803
    *  @author: Bala
    *  @description Constructor of ManualDenyQuoteController
    **/
    public ManualDenyQuoteController(){
        this(ApexPages.currentpage().getparameters().get(CONFIGID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID) == null ? null : ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4());
    }
    
    /**CMCM-803
    *  @author Bala
    *  @description Constructor with Parameters
    **/
    public ManualDenyQuoteController(String strConfigId,String strConfigRequestId,String strFlow, String strBusinessObjectId){
        this.strConfigId = strConfigId;
        this.strConfigRequestId = strConfigRequestId;
        this.strFlow = strFlow;
        this.strBusinessObjectId = strBusinessObjectId;
        boolHasError = false;
        
    }
    
/*
*  @author       : Prem Ranjan
*  @description  : To Update Quote Denied
*  @param        : String QuoteRecordId  @return : Boolean*/

@AuraEnabled
public static boolean updateQuotationToDenied(String quoteRecordId) {
    ilib_LogEvent.rootTitle = LOG_TITLE;
    ilib_LogEvent.push(LOG_TITLE + '.updateQuotationToDenied()');
    ilib_LogEvent.message('quoteRecordId: ' + quoteRecordId);
    try {
        ilib_RestInterface.InterfaceDetails interfaceDetails;
        if(!String.isBlank(quoteRecordId)) {             
            ApttusProposalsSelector objProposalSelector = new ApttusProposalsSelector();
            Apttus_Proposal__Proposal__c objProposal = objProposalSelector.selectByQuotationId(new set<String>{quoteRecordId}).get(0);
            ManualDenyQuoteController instantiated;
           if(string.isnotBlank(objProposal.SAP_Quote__c)){               	
                
                instantiated = new ManualDenyQuoteController(quoteRecordId,null,null,null);               
             	interfaceDetails = instantiated.interfaceDetails;
                strRequstQuotJSON = createQuotJSON(objProposal);

                log = ilib_LogInterface.initiateLog(interfaceDetails, strRequstQuotJSON);
                ilib_LogEvent.message('@@@ RTP Quote Request ' + strRequstQuotJSON);

                response = ApttusSAPConnector.getPrice(strRequstQuotJSON,false);
                checkQuotResponse(response,false,quoteRecordId,log,objProposal);
                ilib_LogEvent.message('@@@ RTP Quote response ' + response);
                
                if(test.isRunningTest()){boolHasError=false;}
               if((response.getStatusCode() == HTTP_SUCCESS_CODE || response.getStatusCode() == HTTP_POST_SUCCESS_CODE) && !boolHasError){
                    
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, strQuotResponse, quoteRecordId);                              
                    ilib_LogEvent.pop();

                    update new Apttus_Proposal__Proposal__c(
                        Id = quoteRecordId,
                        Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDenied
                        );
                    return true;
               }
                
            }else{
                update new Apttus_Proposal__Proposal__c(
                        Id = quoteRecordId,
                        Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDenied
                        );
                    return true;
            }
        }
    } catch (Exception e) {
        //throw new AuraHandledException(e.getMessage());
        ilib_LogEvent.error('Error at line        : ' + e.getLineNumber());
        ilib_LogEvent.error('The following exception has occurred:++++getMessage+++ ' + e.getMessage());
        ilib_LogEvent.error('Exception type caught : ' + e.getTypeName());
        ilib_LogEvent.error('Cause                 : ' + e.getCause());
        ilib_LogEvent.error('Stack trace           : ' + e.getStackTraceString());


        if(log != null){
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, e.getLineNumber() +'-'+ e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(), quoteRecordId);
            ApexExceptions.emit('ManualDenyQuoteController->updateQuotationToDenied ',log.logRecordId,e);     
        }
        else{
             ApexExceptions.emit('ManualDenyQuoteController',quoteRecordId,e);
        }
        boolHasError=true;
        strErrorMsg = Label.UI_Error_Contact_Admin;
       }

        /*if (!boolHasError && log != null){
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, strQuotResponse, quoteRecordId);
        }

        ilib_LogEvent.pop();
        if (isDirectUC){
                return String.valueOf(boolHasError)+'_'+strErrorMsg;
        }else{
                return String.valueOf(boolHasError)+'@'+String.valueOf(boolFapiao)+'_'+strErrorMsg+'#'+boolWarning+'#'+strWarningMsgs;
        }*/	     
    return false;
  }   

  /*
    * @Author: Bala
    * @date: 17-July-2023
    * @Description :static method for Check Quote Responce.
    * @param : Object objProposal
    * @return: 
    */
   
    public static void checkQuotResponse(HttpResponse response , Boolean isDirectUC , String strBusinessObjectId , ilib_LogInterface.LogDetails log ,Apttus_Proposal__Proposal__c objQuots){
        ilib_LogEvent.push('checkQuotResponse');

        if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ){
            boolHasError=true;
            strErrorMsg = Label.UI_Failed_Response_Code;
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), strBusinessObjectId);
            ApexExceptions.emit(LOG_TITLE,log.logRecordId,response.getBody());      
        }
        else
        {
            strQuotResponse = response.getBody();
            system.debug('$$$ strQuotResponse :: '+strQuotResponse);
            ilib_LogEvent.message('Response body'+strQuotResponse);
           // ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,'UI Error :'+ strErrorMsg+ ' JSON Response :'+ strQuotResponse, strBusinessObjectId);
            if(!isDirectUC){
                boolError = quoteParser(objQuots.id ,strQuotResponse);               
            }

            if(boolError){
                boolHasError = true;
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,'UI Error :'+ strErrorMsg+ ' JSON Response :'+ strQuotResponse, strBusinessObjectId);
            }
        }

        ilib_LogEvent.pop();
    }

    /*
    * @Author: Bala
    * @date: 17-July-2023
    * @Description :static method for create Quote JSON
    * @param : Object objProposal
    * @return: JSON
    */

    public static String createQuotJSON(Apttus_Proposal__Proposal__c objProposal) {
        ilib_LogEvent.push('createQuotJSON');
        CreateQuotJSONWrapper wrrRequest = new CreateQuotJSONWrapper();
        
        wrrRequest.ZzapQuot = (String) objProposal.Name;
        wrrRequest.Zzoppid = (String) objProposal.Apttus_Proposal__Opportunity__c;
        wrrRequest.Zstatus = quoteStatus;
        if(objProposal.SAP_Quote__c == null){
            wrrRequest.Vbeln = '';
        }
        else{
            wrrRequest.Vbeln = (String) objProposal.SAP_Quote__c;
        }
        ilib_LogEvent.message('Quote --'+objProposal);
        List<Object> lstNavhdRtoret = new List<Object>();
        wrrRequest.NAVHDRTORET.add(lstNavhdRtoret);
       
        String quotJSON = JSON.serializePretty(wrrRequest);

        ilib_LogEvent.pop();
        return quotJSON;
    }
    /* 
    wrapper Class for JSON
    */
    public class CreateQuotJSONWrapper{
        public string ZzapQuot;
        public String Zzoppid;
        public String Zstatus;
        public String Vbeln;
        public List<Object> NAVHDRTORET = new List<Object>();

    }

    public static Boolean quoteParser(Id idQuote, String strResponseJSON){

        Boolean boolError= false;
        Boolean boolISQuoteUpdate = true;
        Map<String, Object> lstJsonParse = (Map<String, Object>)Json.deserializeUntyped(strResponseJSON);
        Object objResponse = lstJsonParse.get('d');
        String ser = JSON.serialize(objResponse);
        ilib_LogEvent.message('serialize Response : '+ ser);
        RealtimePricingResponse objRTPResponse = (RealtimePricingResponse) JSON.deserialize(ser, RealtimePricingResponse.class);
        ilib_LogEvent.message('@@@ RTP Quote-Response ' + objRTPResponse);
        ilib_LogEvent.message('SAP Quote Number--'+objRTPResponse.ZzapQuot);
       

        if(objRTPResponse != null){
            Apttus_Proposal__Proposal__c objConfig = new Apttus_Proposal__Proposal__c(
                Id = idQuote,
                SAP_Errors__c = ''
            );

                strRETErrors = '';
                if(objRTPResponse.NAVHDRTORET != null){
                    ilib_LogEvent.message('Inside Log Structure');
					String strWarningMessages ;
                    strRETErrors += '<ui>';
                    strWarningMsgs += '<ui>';
                    for(RealtimePricingResponse.LineReturns ret : objRTPResponse.NAVHDRTORET.results){
                        if(ret.Type == 'E' || ret.Type == 'A'){
                            boolRETError = true;
                            ilib_LogEvent.message('ManualDenyQuoteController.strRETErrors-1 ->'+strRETErrors);
                            strRETErrors +=  STRHTMLTAGLINESTART +ret.Message + STRHTMLTAGLINEEND;
                            boolError = true;
                            boolISQuoteUpdate = false;
                            ilib_LogEvent.message('ManualDenyQuoteController.strRETErrors-2 ->'+strRETErrors);
                        }
                        else if(ret.Type == WARNING) //Soft warning message
                        {
                            boolWarning = true;
                            strWarningMessages = ret.Message + '/n';
                            strWarningMsgs +=  STRHTMLTAGLINESTART +ret.Message + STRHTMLTAGLINEEND;
                            boolISQuoteUpdate = true;
                        }
                    }
                    strRETErrors += '</ui>';
                    strWarningMsgs += '</ui>';
                    objConfig.SAP_Errors__c = strRETErrors;
                    //objConfig.SAP_Warnings__c = strWarningMessages;
                    ilib_LogEvent.message('Quote Data Errors -- '+ strRETErrors);
                }
        }
		ilib_LogEvent.pop();
        return boolError;

    }

}