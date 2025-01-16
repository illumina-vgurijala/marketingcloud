/**
*    @author Raja Siva Krishna
*    @date   2020-11-24
*    @description    DCP-43185: UploadAttachmentController class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Raja Siva Krishna              24/11/2020          Initial Version
*     ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class UploadAttachmentController {
    public static final String COMPLETED='Completed';//DCP-49741
    public static final String COMPLETED_LOA_SIGNED='100% Completed - LOA Signed';//DCP-49741
    public static final String ORDER_TYPE_INSTALLATION='Installation';//DCP-49741
    

    /**
    *  @author Raja Siva Krishna
    *  @description create content document link records for given objbect and file Id
    **/
    @AuraEnabled
    public static void createFileRecInIP(Id recIpId,String fileAttachId) {
        try{
            if(String.isNotBlank(fileAttachId)){
                List<ContentDocumentLink> lstContentDocLink = new List<ContentDocumentLink>();
                List<Id> lstFileIds = new List<Id>();
                lstFileIds.addall(fileAttachId.split(', '));
                ContentDocumentLink cdl;
                for(Id eachId:lstFileIds){
                    if(!String.isBlank(eachId)&& !String.isBlank(recIpId)){
                        cdl = New ContentDocumentLink();
                        cdl.LinkedEntityId = recIpId;
                        cdl.ContentDocumentId = eachId;
                        cdl.shareType = 'V';
                        lstContentDocLink.add(cdl);
                    }
                }
                if(lstContentDocLink.size()>0){
                    Insert lstContentDocLink;
                }
           }
        }
        catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /*
     *  @author Pooja Shalwadi
     *  @description : This method is used to created an attachment and update Work Order field.
     *  Start DCP-49741
     */
    @AuraEnabled
    public static void saveFiles(Id woRecordId){
        try{
            System.debug('woRecordId-->'+woRecordId);
            List<SVMXC__Service_Order__c> lstWOUpdate= new List<SVMXC__Service_Order__c>();
            // Update Work Order: LOA
                SVMXC__Service_Order__c woObjUpdate = new WorkOrdersSelector().selectWorkOrdertoKnowCompletionDate(woRecordId);
                if(woObjUpdate!=null && woObjUpdate.SVMXC__Order_Type__c==ORDER_TYPE_INSTALLATION){
                    woObjUpdate.Acceptance_Status__c=COMPLETED;	
                    woObjUpdate.Acceptance_Forecast_in_Current_Quarter__c=COMPLETED_LOA_SIGNED;	
                    woObjUpdate.LOA_Signed_and_Attached__c=true;	
                    lstWOUpdate.add(woObjUpdate);		
                    if(!lstWOUpdate.isEmpty()){
                    System.debug('lstWOUpdate-->'+lstWOUpdate);
                    update lstWOUpdate;
                }
            }
        }
        catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage()); 
        }
    }//END DCP-49741
    
}