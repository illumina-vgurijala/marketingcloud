/**
*    @author Akshay Mohan
*    @date   2021-05-06
*    @description    DCP-38809: Auto Finalize cart
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          Initial Version
*         KD                      2021-05-10          DCP-46472 : Error handling 
*         Avina                   2022-07-05          CMSI-92 Added Instrumentation
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class CartFinalizeQueueable implements IOpportunityQuoteAutomation{
    private Id idCart,idCartOutput;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATED;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'CartFinalizeQueueable';

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return Id of Cart
	**/
    public Id getRecordId(){
        return idCartOutput;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Id of cart
	*	@return void
	**/
    public void setRecordId(String idCart){
        this.idCart = idCart;   
    }

    /**DCP-46472
	*	@author Akshay Mohan
	*	@param NA
	*	@return OpportunityQuoteAutomationQueueable.EmailWrapper
	**/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.getErrorDetails()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails= new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATED) ? Label.OpportunityQuoteAutomation_CART_FINALIZE_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
        CartFinalizeQueueable.handleErrorFinalizeAndSync(idCart,wrapDetails);
        ilib_LogEvent.info('wrapDetails: '+wrapDetails);//CMSI-92
        ilib_LogEvent.pop();
        return wrapDetails;
    }
    
    /**DCP-46472
	*	@author Akshay Mohan
	*	@param Id idCart,OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails
	*	@return void
	**/
    public static void handleErrorFinalizeAndSync(Id idCart,OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails){
        ilib_LogEvent.push(LOG_TITLE + '.handleErrorFinalizeAndSync()');
        ilib_LogEvent.info('idCart: '+idCart);//CMSI-92
        Apttus_Config2__ProductConfiguration__c objConfig = new ApttusProductConfigurationsSelector().selectById(new Set<Id>{idCart}).get(0);
        ilib_LogEvent.info('objConfig: '+objConfig);
        wrapDetails.idRecord=objConfig.Apttus_QPConfig__Proposald__c;
        wrapDetails.setEmail(objConfig.Apttus_QPConfig__Proposald__r.Work_Order__r.OwnerId);
        wrapDetails.idProposal= objConfig.Apttus_QPConfig__Proposald__c;
        wrapDetails.idSourceWorkOrder= objConfig.Apttus_QPConfig__Proposald__r.Work_Order__c;
        wrapDetails.strQuoteName= objConfig.Apttus_QPConfig__Proposald__r.Name;
        wrapDetails.strWOName= objConfig.Apttus_QPConfig__Proposald__r.Work_Order__r.Name;
        wrapDetails.strRegion= objConfig.Apttus_QPConfig__Proposald__r.Work_Order__r.Account_Region__c;
        ilib_LogEvent.info('wrapDetails: '+wrapDetails);//CMSI-92
        ilib_LogEvent.pop();
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext context){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);//CMSI-92
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            if(!UtilsCart.finalizeCart(idCart)){
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();//CMSI-92
                return;
            }
            ilib_LogEvent.info('Finalize Done'); 
            status=OpportunityQuoteAutomationQueueable.STATUS.CART_FINALIZED;
            idCartOutput=idCart;
        }catch(Exception e){
            strErrorMessage = e.getMessage();
            ilib_LogEvent.info('Exception '+e); 
            ApexExceptions.emit(LOG_TITLE,idCart,e);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();//CMSI-92
    }
}