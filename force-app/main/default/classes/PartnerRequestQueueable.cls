/***************************************************************************************************************************************
* NAME         : PartnerRequestQueueable
* DESCRIPTION  : PartnerRequestQueueable.
*                    
* @AUTHOR : Anish
* @DATE   : 15-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Anish                 15-Mar-2021          Initial Version. 
****************************************************************************************************************************************/

public class PartnerRequestQueueable implements Queueable {
    private static final String LOG_TITLE = 'PartnerRequestQueueable';
    Set<Id> partnerRequestIdSet = new Set<Id>();
    
    /*Constructor to Initialize Class parameters*/
    public PartnerRequestQueueable(Set<Id> partnerRequestIdSet){
        this.partnerRequestIdSet=partnerRequestIdSet;
    }
    
    /**
*  @author Anish
*  @description -Method to update Partner Request Status
*                 
**/
    public void execute(QueueableContext qc) { 
        try{
            PartnerRequestsSelector obj =new PartnerRequestsSelector();
            List<Partner_Request__c> updatePRList = new List<Partner_Request__c>();
            System.debug('BBBBB::::'+partnerRequestIdSet);
            for(Partner_Request__c pr : obj.selectPRRecords(partnerRequestIdSet)){
                if(pr.RecordType.DeveloperName == Label.PartnerRequestRecordTypeReagentRentalRequest && pr.Status__c == Label.PartnerRequestStatusPending){
                    pr.Status__c = Label.PartnerRequestStatusAccepted;
                    updatePRList.add(pr);
                }
            }
            if(!updatePRList.isEmpty()){
            System.debug('CCCCC::::'+partnerRequestIdSet);
                update updatePRList;
            }
        }
        catch(Exception e){ ApexExceptions.emit(LOG_TITLE, e);
        }
    }
    
}