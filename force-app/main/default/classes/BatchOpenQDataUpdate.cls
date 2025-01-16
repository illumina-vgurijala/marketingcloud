/*
*    @author: Pankaj Singla
*    @date:   17-Aug-2020
*    @description:  Batch Class to update KOL data-OpenQ records. This is one time data update job
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        17-Aug-2020		       Initial Build		
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class BatchOpenQDataUpdate extends ilib_ScheduleAndBatch{
  /*
   *  @author Pankaj Singla
   *  @description Start method of batch job
   *  @param bc batachable context
   *  @return Query records
  */	
  public override Database.QueryLocator start(Database.BatchableContext bc){
    
    String strSoql='select id,ownerId, '+ 
    ' (select id,Name,KOL__c,Last_Interaction_Date__c,Last_Interaction_Name__c,Last_Interaction_Type__c,Main_Illumina_Contact__c,MainLMNContact__c from KeyOpinionLeadersData__r), '+
    '(select id,Status__c,Expiration_Date__c,LastModifiedDate from Contracts__r where status__c=\'Active\' order by LastModifiedDate desc),'+
    ' (select id,openq__Interaction__c,openq__Interaction__r.name,openq__Interaction__r.openq__Date__c,openq__Interaction__r.LastModifieddate,openq__Interaction__r.openq__Interaction_Type__c from openq__Attendees__r order by openq__Interaction__r.LastModifieddate desc) from contact';
        return Database.getQueryLocator(strSOQL);
  
  }
  /*
   *  @author Pankaj Singla
   *  @description execute method of batch job
   *  @param bc batachable context
   *  @return None
  */	
  public override void execute (Database.BatchableContext bc, List<SObject> scope){
    List<Key_Opinion_Leader_Data__c> lstKOLRecords=new List<Key_Opinion_Leader_Data__c>();
    for (Contact objContact : (List<Contact>)scope){
      Key_Opinion_Leader_Data__c objKeyOpLeaderData;      
      Contracts__c objContract;
      openq__Attendee__c objAttendee;
      //objKeyOpLeaderData=(objContact.KeyOpinionLeadersData__r.size()>0)?objContact.KeyOpinionLeadersData__r[0]:(new Key_Opinion_Leader_Data__c());
      Key_Opinion_Leader_Data__c[] lstKeyOPL=objContact.KeyOpinionLeadersData__r;
      Contracts__c[] lstContract=objContact.Contracts__r;
      openq__Attendee__c[] lstAttendee=objContact.openq__Attendees__r;
      
      objKeyOpLeaderData=(lstKeyOPL.size()>0)?lstKeyOPL[0]:(new Key_Opinion_Leader_Data__c());      
      objContract=(lstContract.size()>0)?lstContract[0]:null;
      objAttendee=(lstAttendee.size()>0)?lstAttendee[0]:null;
      if(objContract!=null){
        objKeyOpLeaderData.Expiration_Date__c=objContract.Expiration_Date__c;
      }
      
      if(objAttendee!=null){
        objKeyOpLeaderData.Last_Interaction_Date__c=Date.ValueOf(objAttendee.openq__Interaction__r.openq__Date__c);
        objKeyOpLeaderData.Last_Interaction_Name__c=objAttendee.openq__Interaction__r.Name;
        objKeyOpLeaderData.Last_Interaction_Type__c=objAttendee.openq__Interaction__r.openq__Interaction_Type__c;
      }
      objKeyOpLeaderData.Main_Illumina_Contact__c=objContact.ownerId;
            
		if(objKeyOpLeaderData.MainLMNContact__c==null){
			objKeyOpLeaderData.MainLMNContact__c=objContact.id;
		}
      
      lstKOLRecords.add(objKeyOpLeaderData);
            system.debug('final--'+objKeyOpLeaderData);
      
      
    }
    if(lstKOLRecords.size()>0){
        upsert lstKOLRecords;
    }
    
  }
  /*
   *  @author Pankaj Singla
   *  @description Finish method of batch job
   *  @param bc batachable context
   *  @return None
  */	
  public override void finish(Database.BatchableContext bc) { 
        /*This is mandatory method for batchable interface*/
    }


}