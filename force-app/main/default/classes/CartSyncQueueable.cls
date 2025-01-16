/**
*    @author Akshay Mohan
*    @date   2021-04-27
*    @description    DCP-38809: Auto Finalize cart
*    @ Test class Coverage: 86% - TestCartFinalizeSyncQueueable
*    @ Test class Coverage : 75% - TestCartFinalizeSyncQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          Initial Version
*         Avina                   2022-07-05          CMSI-92 Added Instrumentation
*         Adithi Acharya          29-Sept-2022        86% Test Classes: TestCartFinalizeSyncQueueable.cls
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class CartSyncQueueable implements IOpportunityQuoteAutomation{
    private Id idQuotation,idCart;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.CART_FINALIZED;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'CartSyncQueueable';
    public static Boolean boolRunTestCartFinalizeSyncQueueable = false;

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return Id of quote
	**/
    public Id getRecordId(){
        return idQuotation;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Id of cart
	*	@return void
	**/
    public void setRecordId(String idCart){
        this.idCart = idCart;    
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return OpportunityQuoteAutomationQueueable.EmailWrapper
	**/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.handleNotification()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails= new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.CART_FINALIZED) ? Label.OpportunityQuoteAutomation_CART_FINALIZE_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
        wrapDetails.setErrorDetails(strErrorMessage);
        CartFinalizeQueueable.handleErrorFinalizeAndSync(idCart,wrapDetails);
        ilib_LogEvent.info('wrapDetails-->:'+wrapDetails);//CMSI-92
        ilib_LogEvent.pop();
        return wrapDetails;
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
            if(boolRunTestCartFinalizeSyncQueueable || !UtilsCart.synchronizeCart(idCart)){
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();//CMSI-92
                return;
            }
            ilib_LogEvent.info('Sync success');
            status=OpportunityQuoteAutomationQueueable.STATUS.CART_SYNCED;
            List<Apttus_Config2__ProductConfiguration__c> lstCart = new ApttusProductConfigurationsSelector().selectById(new Set<Id>{idCart});
            idQuotation=lstCart.get(0).Apttus_QPConfig__Proposald__c;
            ilib_LogEvent.info('lstCart-->:'+lstCart);//CMSI-92
        }catch(Exception e){
            ilib_LogEvent.message('Message... ' + e.getMessage());
            ilib_LogEvent.message('idCart... ' +idCart);
            ilib_LogEvent.message('LOG_TITLE... ' + LOG_TITLE);
            strErrorMessage = e.getMessage();
            ApexExceptions.emit(LOG_TITLE,idCart,e);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();//CMSI-92
    }
}