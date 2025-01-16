/**
*    @author: Pankaj Singla
*    @date:   12-Aug-2020
*    @description:  Attendee Trigger Handler Class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        12-Aug-2020		       Initial Build		
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class Attendees extends ilib_SObjectDomain{
    
    /*
    * Method - Return sObject Type
    */
    public Attendees(List<openq__Attendee__c> sObjectList){
        super(sObjectList);     
    }
    
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
          return new Attendees(sObjectList);
            
        }
    }
    
	/*
    * @author Pankaj
    * @date   12-Aug-2020
    * After Insert trigger method
    */
    public override void onAfterInsert(){
        List<openq__Attendee__c> lstnewAttendees=(List<openq__Attendee__c>) records;
        Set<Id> setContactIds=new Set<Id>();
		/*Map to Hold ContactIds to KOL Record*/
        Map<Id,Key_Opinion_Leader_Data__c> mapContactIdToKOL =new Map<Id,Key_Opinion_Leader_Data__c>();
		/*Map of Contact and List of Contract Records*/
        Map<Id,List<Contracts__c>> mapContactIdToContract=new Map<Id,List<Contracts__c>>();
		/*Map of Contact to List of Attendees*/
        Map<Id,List<openq__Attendee__c>> mapContactIdToAttendee=new Map<Id,List<openq__Attendee__c>>();    
        List<Key_Opinion_Leader_Data__c> lstKOLFinal=new List<Key_Opinion_Leader_Data__c>();
        
		for(openq__Attendee__c objAttendee:new AttendeeSelector().selectAttendeesFromTrigger(lstnewAttendees)){    
            setContactIds.add(objAttendee.openq__Contact__c);
            if(mapContactIdToAttendee.containsKey(objAttendee.openq__Contact__c)){
				List<openq__Attendee__c> lstAtten=mapContactIdToAttendee.get(objAttendee.openq__Contact__c);
				lstAtten.add(objAttendee);
                mapContactIdToAttendee.put(objAttendee.openq__Contact__c,lstAtten);
				
            }
            else {
                mapContactIdToAttendee.put(objAttendee.openq__Contact__c,new List<openq__Attendee__c>{objAttendee});
            }
        }
        
        for(Contracts__c objContract:new ContractSelector().selectContractsByContactIds(setContactIds)){
            if(mapContactIdToContract.containsKey(objContract.Contact__c)){
                mapContactIdToContract.get(objContract.Contact__c).add(objContract);
            }
            else {
                mapContactIdToContract.put(objContract.Contact__c, new List<Contracts__c>{objContract});

            }
        }
        
         for(Key_Opinion_Leader_Data__c objKOL:new KeyOpinionLeaderSelector().selectKOLByContactIds(setContactIds)){
            mapContactIdToKOL.put(objKOL.MainLMNContact__c,objKOL);
        } 
        
        for(Id idContactId:setContactIds){
            Key_Opinion_Leader_Data__c objKOL;
            Contracts__c objContract;
            String strContractName='';
            openq__Attendee__c objAttendeeFinal;
            if(mapContactIdToKOL.containsKey(idContactId)){
                objKOL=mapContactIdToKOL.get(idContactId);
            }
            else {
                objKOL=new Key_Opinion_Leader_Data__c();
                
            }
            
            if(mapContactIdToContract.containsKey(idContactId)){
                objContract=mapContactIdToContract.get(idContactId)[0];
				objKOL.Expiration_Date__c=objContract.Expiration_Date__c;
                strContractName=objContract.Name;
            }
            
            if(mapContactIdToAttendee.containsKey(idContactId)){
                objAttendeeFinal=mapContactIdToAttendee.get(idContactId)[0];
				objKOL.Name=objAttendeeFinal.openq__Interaction__r.Name+'~'+strContractName;
				objKOL.Main_Illumina_Contact__c=objAttendeeFinal.openq__Contact__r.ownerId;            
				objKOL.Last_Interaction_Date__c=Date.ValueOf(objAttendeeFinal.openq__Interaction__r.openq__Date__c);
				objKOL.Last_Interaction_Name__c=objAttendeeFinal.openq__Interaction__r.name;
				objKOL.Last_Interaction_Type__c=objAttendeeFinal.openq__Interaction__r.openq__Interaction_Type__c;
            }
			
            
             if(objKOL.MainLMNContact__c==null){
                objKOL.MainLMNContact__c=idContactId;
            }  
            lstKOLFinal.add(objKOL);
        }
        
        if(lstKOLFinal.size()>0){
            upsert lstKOLFinal;
        }
        
        
    }
}