/**
*    @author: Pankaj
*    @date:   07-Sept-2020
*    @description:  Charket Scoring Event Handler
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 15 Oct 2018        Handler class for platform event
              
*    ------------------------------------------------------------------------------------
*
*/
public with sharing class CharketScoringEvents extends ilib_SObjectDomain{
	
    /**Paramterized Constructor */
    public CharketScoringEvents(List<Charket_Scoring_Event__e> sObjectList)
    {
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
            return new CharketScoringEvents(sObjectList);
        }
    }
    /*
    * @author Pankaj Singla
    * @date   07-Sept-2020
    * @description: After insert trigger method
    */
    public override void onAfterInsert(){
        List<Charket_Scoring_Event__e> lstEventRecords=(List<Charket_Scoring_Event__e>)records;
        Map<Id,Id> mapMemberIdToLeadId=new Map<Id,Id>();
        Map<Id,Id> mapMemberIdToContactId=new Map<Id,Id>();
        List<CampaignMember> lstCampaignMembers=new list<CampaignMember>();
        List<Lead> lstLead=new List<Lead>();
        List<Contact> lstContact=new List<Contact>();
		Set<Id> setMemberIds=new set<Id>();
		Map<Id,Lead> mapIdToLead;
		Map<Id,Contact> mapIdToContact;	
		String strNonScoringJobFunctions=Label.Prospect_Non_Scoring_Job_Function;
        List<String> lstJobFunctions=strNonScoringJobFunctions.split(',');
        List<Prospect_Scoring_Log__c> lstProspectLog=new List<Prospect_Scoring_Log__c>();
        for(Charket_Scoring_Event__e objEvent:lstEventRecords){
            if(objEvent.CampaignMemberId__c!=null){
                CampaignMember objCampaignMember=new CampaignMember(id=objEvent.CampaignMemberId__c);
                lstCampaignMembers.add(objCampaignMember);
                if(objEvent.LeadId__c!=null){
                    mapMemberIdToLeadId.put(objEvent.CampaignMemberId__c,objEvent.LeadId__c);
					setMemberIds.add(objEvent.LeadId__c);
                }
                else if(objEvent.ContactId__c!=null){
                    mapMemberIdToContactId.put(objEvent.CampaignMemberId__c,objEvent.ContactId__c);
					setMemberIds.add(objEvent.ContactId__c);
                }
            }
        }
        List<CampaignMember> lstCampaignMembersdata=new CampaignMemberSelector().selectCampaignMembersList(lstCampaignMembers);
		mapIdToLead=new Map<Id,Lead>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c 
												from Lead where id in:setMemberIds and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
		mapIdToContact=new Map<Id,Contact>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c from Contact where id in:setMemberIds 
                                            and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
		
        for(CampaignMember objCampaignMember:lstCampaignMembersdata){
            CampaignMembers.CampaignMemberWrapper objWrapper;
            Lead objLead;
            Contact objContact;
            if(objCampaignMember.LeadId!=null && mapMemberIdToLeadId.containsKey(objCampaignMember.id)){
				Id idLead=mapMemberIdToLeadId.get(objCampaignMember.id);
				if(mapIdToLead.containsKey(idLead)){
					objLead=mapIdToLead.get(idLead);
					objWrapper=CampaignMembers.processCampaignMemberForScoring(objCampaignMember,objLead);
					if(objWrapper!=null && objWrapper.ScoreUpdated){
						objLead.Marketing_Score__c=objWrapper.FinalScore;
						objLead.Date_Of_Last_Score_Change__c=Datetime.now();
                        lstProspectLog.add(objWrapper.objProspectLog);
						lstLead.add(objLead);
					}
				}
                
            }
            else if(objCampaignMember.ContactId!=null && MapMemberIdToContactId.containsKey(objCampaignMember.id)){
				Id idContact=MapMemberIdToContactId.get(objCampaignMember.id);
				if(mapIdToContact.containsKey(idContact)){
					objContact=mapIdToContact.get(idContact);
					objWrapper=CampaignMembers.processCampaignMemberForScoring(objCampaignMember,objContact);
					if(objWrapper!=null && objWrapper.ScoreUpdated){
						objContact.Marketing_Score__c=objWrapper.FinalScore;
						objContact.Date_Of_Last_Score_Change__c=Datetime.now(); 
                        lstProspectLog.add(objWrapper.objProspectLog);
						lstContact.add(objContact);
					}
				}
                
            }
        }
	
        if(!lstContact.isEmpty()){
            update lstContact;
        } 
        
        if(!lstLead.isEmpty()){
            update lstLead;
        }
        if(!lstProspectLog.isEmpty()){
            system.debug( 'lstProspectLog------'+lstProspectLog );
            insert lstProspectLog;
        }
    }
}