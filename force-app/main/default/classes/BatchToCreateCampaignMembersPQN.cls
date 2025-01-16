/**
*    @author  Pankaj Singla
*    @date    01-August-2018
*    @description  This Batch job inserts Contacts and Leads as Campaign members for PQN Alerts

*        Modification Log:
*       
------------------------------------------------------------------------------------
*       Developer                       Date                Description
*       
------------------------------------------------------------------------------------
*       Pankaj Singla          			01/08/2018            Original  Version
*/
public with sharing class BatchToCreateCampaignMembersPQN implements Database.batchable<String>, Database.Stateful{
    public List<String> lstIds;
    public Id idCampaignId;
    static final String STR_CONTACT_FINAL='Contact';
    static final String STR_LEAD_FINAL='Lead';
    /*Paramterized Constructor */
    public BatchToCreateCampaignMembersPQN (List<string> lstIds,Id idCampaignId){
        this.lstIds=lstIds;
        this.idCampaignId=idCampaignId;
    }
    /*Start method of Batch Class */
    public Iterable<string> start(Database.batchableContext objBatchableContext){
         Iterable<string> lstIterable = (Iterable<string>) new CustomIteratorId(lstIds);
        return lstIterable;
    }
    /*Execute method of Batch Class */
    public void execute(Database.BatchableContext objBatchableContext, List<String> lstScope){
         List<CampaignMember> lstCmpaignMemberToInsert = new List<CampaignMember>();
        set<Id> setCampaignMemberIds=new set<id>();
        for(CampaignMember objCampaignMemeber:[select id,ContactId,leadId from CampaignMember where campaignid =:idCampaignId
                                  and (ContactId  in:lstScope or  LeadId in:lstScope)]){
            if(objCampaignMemeber.ContactId!=null){
                setCampaignMemberIds.add(objCampaignMemeber.ContactId);
            }
            if(objCampaignMemeber.leadId!=null){
                setCampaignMemberIds.add(objCampaignMemeber.leadId);
            }
        }
        system.debug('scope is--'+lstScope);
        for(String strScope :lstScope){
            Id idMemberId=Id.valueOf(strScope);
            String strObjName = idMemberId.getSObjectType().getDescribe().getName();
            system.debug('sobject name is--'+strObjName);
             
                
            if(strObjName.equalsIgnoreCase(STR_CONTACT_FINAL) && !setCampaignMemberIds.contains(idMemberId)){
                CampaignMember objCampaignMember = new CampaignMember(CampaignId = idCampaignId,
                status = 'Sent',ContactId=idMemberId); 
                lstCmpaignMemberToInsert.add(objCampaignMember);
                
            }
            else if(strObjName.equalsIgnoreCase(STR_LEAD_FINAL) && !setCampaignMemberIds.contains(idMemberId)){
                CampaignMember objCampaignMember = new CampaignMember(CampaignId = idCampaignId,
                status = 'Sent',LeadId=idMemberId);
                lstCmpaignMemberToInsert.add(objCampaignMember);
            }
           
        }
        system.debug('list is--'+lstCmpaignMemberToInsert);
        if(lstCmpaignMemberToInsert.size()>0){
            insert lstCmpaignMemberToInsert;
        }
    }

    /*Finish method of Batch Class */ 
    public void finish(Database.BatchableContext objBatchableContext){
        system.debug('I am finish-'+lstIds+'##'+idCampaignId);
        AsyncApexJob objAsyncApexJob  = [SELECT Id,Status,JobType,NumberOfErrors,
                          JobItemsProcessed,TotalJobItems,CompletedDate,ExtendedStatus
          					FROM AsyncApexJob WHERE Id =:objBatchableContext.getJobId()];
        Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();
  		objSingleEmailMessage.setTargetObjectId(UserInfo.getUserId());
        objSingleEmailMessage.setSubject('Inserting Campaign Members for PQN Batch  - ' + objAsyncApexJob.Status);
   		objSingleEmailMessage.setSaveAsActivity(false);
   		objSingleEmailMessage.setPlainTextBody
   		('The batch Apex job completed on  ' + objAsyncApexJob.CompletedDate + ',\n\n' +
   			'Job Status : ' + objAsyncApexJob.Status + '\n'+
   			'Total Job Items processed : ' + objAsyncApexJob.TotalJobItems + '\n'+
   			'Number of Job Items processed : ' + objAsyncApexJob.JobItemsProcessed + '\n' +
   			'Number of Failures : '+ objAsyncApexJob.NumberOfErrors);
   			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { objSingleEmailMessage });
    }
}