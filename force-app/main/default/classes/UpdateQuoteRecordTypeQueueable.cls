/***************************************************************************************************************************************
* NAME         : UpdateQuoteRecordTypeQueueable
* DESCRIPTION  : Updates the recordtype of Quotation when Opportunity is updated .
* TEST CLASS  for 75% coverage : TestUpdateQuoteRecordTypeQueueable  
* TEST CLASS  for 90% coverage : TestUpdateQuoteRecordTypeQueueable                   
* @AUTHOR : Anish
* @DATE   : 23-Mar-2021  

* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Anish                 23-Mar-2021          Initial Version. 
* Anshaj Sinha          16-Sep-2022          CMSI-204 Instrumented class with latest changes in Logging Framework
* Adithi Acharya        31-Oct-2022          DCP-56437 : Removal of Rejected Quote Stage
****************************************************************************************************************************************/

public class UpdateQuoteRecordTypeQueueable implements Queueable {
    private static final String LOG_TITLE = 'UpdateQuoteRecordTypeQueueable';
    public static final String QUOTATION_RT_PROPOSAL = 'Proposal';
    public static final String QUOTATION_RT_CUSTOM_PRODUCT_QUOTE = 'Custom_Product_Quote';
    public static final String QUOTATION_RT_PROPOSAL_READ_ONLY = 'Proposal_Read_Only';
    public static final Map<String, Schema.RecordTypeInfo> QUOTE_RECORD_TYPE_MAP = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByDeveloperName();
    public static final Map<Id,Schema.RecordTypeInfo> OPP_RECORD_TYPE_MAP = Opportunity.sobjectType.getDescribe().getRecordTypeInfosById();
    Set<Id> oppIdSet = new Set<Id>();
    public static final Id QUOTATION_RTID_PROPOSAL = QUOTE_RECORD_TYPE_MAP.get(QUOTATION_RT_PROPOSAL).getRecordTypeId();
    public static final Id QUOTATION_RTID_CUSTOM_PRODUCT_QUOTE = QUOTE_RECORD_TYPE_MAP.get(QUOTATION_RT_CUSTOM_PRODUCT_QUOTE).getRecordTypeId();
    public static final Id QUOTATION_RTID_PROPOSAL_READ_ONLY = QUOTE_RECORD_TYPE_MAP.get(QUOTATION_RT_PROPOSAL_READ_ONLY).getRecordTypeId();
    public static final Set<String> REORDER_RECORD_TYPES = new Set<String> { Label.OpportunityRTDirectReOrder, Label.IndirectReOrder};
    public static final Set<String> QUOTE_STAGE_ACCEPTED_OR_DENIED = new Set<String> { Label.QuoteStageAccepted, Label.QuoteStageDenied};
    public static final String OPPTYPECUSTOMPRODUCTFIRSTBUY = 'Custom Product (First Buy)'; 
    public static Boolean catchException = false;
    
    /*Constructor to Initialize Class parameters*/  
    public UpdateQuoteRecordTypeQueueable(Set<Id> oppIdSet){
        this.oppIdSet = oppIdSet;
    }
    
    
    /**
*  @author Anish
*  @description -Method to update Quotation RecordType
*                 
**/
    public void execute(QueueableContext qc) { 
        try{
            ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
            ilib_LogEvent.push(LOG_TITLE + '.execute()');
            updateRecordType(oppIdSet);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
            }
        }
        catch(Exception e){ ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SALES); }
    }
    
    /*Method - Updates Record Type On Quote , Param - Set<Id> [DCP-45455]*/
    public static void updateRecordType(Set<Id> oppIdSet)
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateRecordType()');
        String recordType;
            ApttusProposalsSelector obj =new ApttusProposalsSelector();
            List<Apttus_Proposal__Proposal__c> updateQuotationList = new List<Apttus_Proposal__Proposal__c>();
            for(Apttus_Proposal__Proposal__c quoteRec : obj.selectValidQuote(oppIdSet)){
                recordType = OPP_RECORD_TYPE_MAP.get(quoteRec.Apttus_Proposal__Opportunity__r.RecordTypeId).getDeveloperName();
                ilib_LogEvent.message('Record Type : '+recordType);
                if(REORDER_RECORD_TYPES.contains(recordType) && quoteRec.Apttus_Proposal__Opportunity__r.Type == OPPTYPECUSTOMPRODUCTFIRSTBUY){//Reorder quotes
                    if(quoteRec.RecordTypeId != QUOTATION_RTID_CUSTOM_PRODUCT_QUOTE){
                        quoteRec.RecordTypeId = QUOTATION_RTID_CUSTOM_PRODUCT_QUOTE;
                        updateQuotationList.add(quoteRec);
                    }
                }else{//Non Reorder Quotes
                    if(!QUOTE_STAGE_ACCEPTED_OR_DENIED.contains(quoteRec.Apttus_Proposal__Approval_Stage__c) && quoteRec.RecordTypeId != QUOTATION_RTID_PROPOSAL){
                        quoteRec.RecordTypeId = QUOTATION_RTID_PROPOSAL;
                        updateQuotationList.add(quoteRec);
                    }
                }
            }
            if(!updateQuotationList.isEmpty()){
                update updateQuotationList;
                ilib_LogEvent.info('Updated Quotation Record Ids : '+UtilsCollection.getSetOfIds(updateQuotationList));
            }
            ilib_LogEvent.pop();
    }
}