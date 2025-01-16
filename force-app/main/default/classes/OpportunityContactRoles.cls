/**
*    @date          11 Aug 2020
*    @description   Opportunity Contact Role domain class
*    @Test Class    TestMktgWaterfallOpptyContactRoles - This test class tests all Marketing waterfall functionality of this class
*
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty             11 Aug 2020          Initial Version
*              Prem Ranjan                  09 Dec 2021          DCP-50538: Populate Role as Power Sponsor on First Contact Role inserted
*             Adyasha/Anand Palla           30 Mar 2022          DCP-52276: CodeScan Fixes
*             Maruthi                       02 June 2022         DCP-52631 added filterOutContactsOnIndirectOpps() 
*             Vaka Vishal Reddy             22 Aug 2022          CMSI-216 Instrumentation
*              Deep Diwakar                 July-27-2023         DCP-60131: Adding call to MarketingWaterfallService for trigger Markting waterfall logic
*              Akankshya Aparajita          Dec-07-2023          Added logic to check if the Opportunity is updated by contact role (Field:Is_Updated_From_Contact_Role__c) 
*    ------------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpportunityContactRoles extends ilib_SObjectDomain {
    
    public static final String STRING_OPPORTUNITYCONTACTROLES = 'OpportunityContactRoles';
    public static final String STRING_UPDATEOPPORTUNITYPRIMARYCONTACT = 'updateopportunityPrimaryContact';
    public static Boolean isConRoleCreatedFromOpp = false;
	public static Boolean isConRoleUpdatedFromQuote = false;
    public static Boolean oppConUpdateDone = false;
	public static final String STRING_INDIRECT_STANDARD = 'Indirect_Standard';
    public static final String STRING_INDIRECT_ORDER = 'Indirect_Re_Order';
    public static final String STRING_INDIRECT_FIELD_SERVICE = 'Indirect_Field_Services';
    private static final String NULLSTR = 'Null';
    private static final String LOG_TITLE = 'OpportunityContactRoles';
/*
* 	Boilerplate which is required for base class instantiation logic
*/
    public OpportunityContactRoles(List<OpportunityContactRole> sObjectList) {
        super(sObjectList);
    }
    /*
* 	Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * 	Boilerplate which is required for base class instantiation logic
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new OpportunityContactRoles(sObjectList);
        }
    }
    
    /**
     * @author Anand
     * @Modifieddate   30-Mar-2022
     * @description  All the logic in Before Insert Trigger run in this method
     * @return void
     * @parameter na
     **/
    public override void onBeforeInsert()
    {
         makeFirstContactPrimary((List<OpportunityContactRole>)records);  
        //DCP-52631
        List<OpportunityContactRole> updateOppoContRol = filterOutContactsOnIndirectOpps();
        if(!updateOppoContRol.isEmpty()) {
            OpportunityContactRolesHelper.makeContactPowerSponsorOnInsert(updateOppoContRol);//DCP-50538
        }
    }

    /**
     * @author Anand
     * @Modifieddate   30-Mar-2022 
     * @description  All the logic in After Insert Trigger run in this method
     * @return void
     * @parameter na
     **/
    public override void onAfterInsert()
    {
        //updateopportunityPrimaryContact((List<OpportunityContactRole>)records);
        ilib_Queueablethread queueableThreadAfterInsert = new ilib_Queueablethread('OpportunityContactRolesAfterInsert'); 

        queueableThreadAfterInsert.logandQueue(new OpportunityContactRoleQueueable(STRING_UPDATEOPPORTUNITYPRIMARYCONTACT ,(List<OpportunityContactRole>)records, isConRoleUpdatedFromQuote),'OpportunityContactRoleQueueable', STRING_UPDATEOPPORTUNITYPRIMARYCONTACT);
        
        if(queueableThreadAfterInsert.lstQueueableJobs.size() > 0) {
            ilib_QueueableManager.enqueueJob(queueableThreadAfterInsert,ilib_LogEvent.SALES);  
        } 
        
        //DCP-60131: calling MarketingWaterfallService
        ilib_LogEvent.info('calling marketing waterfall service after insert');
        MktgWaterfallServiceHelper.publishWaterfallOpptyEvent('Contact', UtilsCollection.getSetOfIds((List<OpportunityContactRole>)records, 'ContactId'));

    }

    /* METHOD NAME   : onAfterDelete
    * DEVELOPER      : prem ranjan
    * DESCRIPTION    : Opertaions after record delete
    * RETURN TYPE    : NA
    * PARAMETER      : NA
    */
    public override void onAfterDelete()
    {
        Map<Id,OpportunityContactRole> oldMap = (Map<Id,OpportunityContactRole>)trigger.oldMap;//DCP-50569
        OpportunityContactRolesHelper.updateToPowerSponsor(oldMap);//DCP-50538

        //DCP-60131: calling MarketingWaterfallService
        ilib_LogEvent.info('calling marketing waterfall service after delete');
        MktgWaterfallServiceHelper.publishWaterfallOpptyEvent('Contact', UtilsCollection.getSetOfIds(oldMap.values(), 'ContactId'));
        
    }

    /**
     * @author Anand
     * @Modifieddate   30-Mar-2022 
     * @description  All the logic in Before Update Trigger run in this method
     * @return void
     * @parameter na
     **/
    public override void onBeforeUpdate(Map<Id, sObject> idToOldRecords)
    {
        //before update
        Map<Id,OpportunityContactRole> newMap = (Map<Id,OpportunityContactRole>)trigger.newMap;//DCP-50569
        OpportunityContactRolesHelper.updateToPowerSponsor(newMap);//DCP-50538
    }

    /**
     * @author Anand
     * @Modifieddate   30-Mar-2022 
     * @description  All the logic in After Update Trigger run in this method
     * @return void
     * @parameter na
     **/
    public override void onAfterUpdate(Map<Id, sObject> idToOldRecords)
    {
        //updateopportunityPrimaryContact((List<OpportunityContactRole>)records); 
        ilib_Queueablethread queueableThreadAfterUpdate = new ilib_Queueablethread('OpportunityContactRolesAfterUpdate'); 

        queueableThreadAfterUpdate.logandQueue(new OpportunityContactRoleQueueable(STRING_UPDATEOPPORTUNITYPRIMARYCONTACT ,(List<OpportunityContactRole>)records, isConRoleUpdatedFromQuote),'OpportunityContactRoleQueueable', STRING_UPDATEOPPORTUNITYPRIMARYCONTACT);
        
        if(queueableThreadAfterUpdate.lstQueueableJobs.size() > 0) {
            ilib_QueueableManager.enqueueJob(queueableThreadAfterUpdate,ilib_LogEvent.SALES);  
        }

        //DCP-60131: calling MarketingWaterfallService
        ilib_LogEvent.info('calling marketing waterfall service after update');
        Set<Id> setContactUpdates = new Set<Id>();

        List<OpportunityContactRole> ocrRecords = (List<OpportunityContactRole>)records;
        
        for (OpportunityContactRole newOcr : ocrRecords) {
            OpportunityContactRole oldOcr = (OpportunityContactRole) idToOldRecords.get(newOcr.Id);

            // only collect contacts if they are changed/swapped in OCR
            if (newOcr.ContactId != oldOcr.ContactId) {
                // new contact that is added to this contact role
                setContactUpdates.add(newOcr.ContactId);

                // old contact that is removed from this contact role
                setContactUpdates.add(oldOcr.ContactId);

            }

        }

        ilib_LogEvent.info('setContactUpdates size: ' + setContactUpdates.size());
        if (!setContactUpdates.isEmpty()) {
            MktgWaterfallServiceHelper.publishWaterfallOpptyEvent('Contact', setContactUpdates);
        }

    }

    /**
    *  @author Vishal
    *  @description  CMSI-51,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

/**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-29588 update primary Contact on opportunity 
     * After update trigger method
     **/        
    public static void updateopportunityPrimaryContact(List<OpportunityContactRole> lstOCRs, Boolean isUpdateFromQuote) { 
        ilib_LogEvent.push(LOG_TITLE+'.updateopportunityPrimaryContact()');
        
        ilib_LogEvent.info('isUpdateFromQuote '+isUpdateFromQuote);
        List<Opportunity> lstParentOpps = new List<Opportunity>();
        Set<Id> setParentOppIds = utilscollection.getSetOfIds(lstOCRs, 'OpportunityId');
        List<OpportunityContactRole> lstAllOCRs = new OpportunityContactRoleSelector().selectRoles(setParentOppIds);
		
		ContactRoleWrapper objContactRoleWrapper = createOpportunityContactRolesMap(lstAllOCRs);
        Map<Id,List<OpportunityContactRole>> idToOppContRole = objContactRoleWrapper.idToOppContRole;
        Map<Id,Id> oppIdToPrimaryContact = objContactRoleWrapper.oppIdToPrimaryContact;
        List<Id> oppIdWithPowerSponsorContact = objContactRoleWrapper.oppIdWithPowerSponsorContact;					   
		

        lstParentOpps = new OpportunitySelector().selectOpportunities(setParentOppIds);

        List<Opportunity> lstOppsToBeUpdated = new List<Opportunity>();
        
        for(Opportunity opp : lstParentOpps) {
            Boolean oppUpdateNeeded = false;
            ilib_LogEvent.message('opp before update '+opp);
            if(oppIdToPrimaryContact.containsKey(opp.Id) && opp.Primary_Contact__c != oppIdToPrimaryContact.get(opp.Id)) {
                opp.Primary_Contact__c = oppIdToPrimaryContact.get(opp.Id);
                oppUpdateNeeded = true;
            }
            if(opp.Is_Power_Sponsor_Identified__c != oppIdWithPowerSponsorContact.contains(opp.Id) || 
               opp.Is_Contact_Role_Identified__c != idToOppContRole.containsKey(opp.Id)) {
                opp.Is_Power_Sponsor_Identified__c = oppIdWithPowerSponsorContact.contains(opp.Id);
                opp.Is_Contact_Role_Identified__c = idToOppContRole.containsKey(opp.Id);
                oppUpdateNeeded = true;
            }
            if(oppUpdateNeeded) {
                if(Opportunities.CLOSED_STATUSES.contains(opp.StageName) && isUpdateFromQuote) {
                    opp.Is_Updated_By_System__c = True;
                }
            if(opp.Is_Updated_From_Contact_Role__c){
                    opp.Is_Updated_From_Contact_Role__c = false; 
                }else{
                    opp.Is_Updated_From_Contact_Role__c = true; 
                }
                lstOppsToBeUpdated.add(opp);
            }
        }

        if(!lstOppsToBeUpdated.isEmpty()) {
            oppConUpdateDone = true;
			ilib_LogEvent.message('lstOppsToBeUpdated '+lstOppsToBeUpdated);
            List<Database.SaveResult> srUpdateOptys = Database.update(lstOppsToBeUpdated,false);
            ApexExceptions.emitSaveErrors(srUpdateOptys, STRING_OPPORTUNITYCONTACTROLES);
        }
        ilib_LogEvent.pop();  
    }

/**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-29588 For Creation of OpportunityContactRole related to Opportunity Map
     * After update trigger method
     **/   
    private static ContactRoleWrapper createOpportunityContactRolesMap(List<OpportunityContactRole> lstOptContRole) {
        ilib_LogEvent.push(LOG_TITLE+'.createOpportunityContactRolesMap()');
        Map<Id,List<OpportunityContactRole>> idToOppContRole = new Map<Id,List<OpportunityContactRole>>();
        Map<Id,List<OpportunityContactRole>> oppIdToLstOppCon = new Map<Id,List<OpportunityContactRole>>();
        Map<Id,Id> oppIdToPrimaryContact = new Map<Id,Id>();
        List<Id> oppIdWithPowerSponsorContact = new List<Id>();
		Set<Id> setParentOppIds = new Set<Id>();

        for(OpportunityContactRole oppConRole : lstOptContRole) {
            setParentOppIds.add(oppConRole.OpportunityId);

            if(oppConRole.isPrimary) {
                oppIdToPrimaryContact.put(oppConRole.OpportunityId,oppConRole.contactId);
            }
            if(idToOppContRole.containsKey(oppConRole.OpportunityId) && oppConRole.Role != NULL) {
                List<OpportunityContactRole> lstTemp = idToOppContRole.get(oppConRole.OpportunityId);
                lstTemp.add(oppConRole);
            } else {
                idToOppContRole.put(oppConRole.OpportunityId,new List<OpportunityContactRole> {oppConRole});
            }
            if(oppConRole.Role == System.Label.Power_Sponsor_Contact_Role) {
                oppIdWithPowerSponsorContact.add(oppConRole.OpportunityId);
            }
            
            if(!oppIdToLstOppCon.containsKey(oppConRole.OpportunityId)) {
                oppIdToLstOppCon.put(oppConRole.OpportunityId,new List<OpportunityContactRole>());
            }
            oppIdToLstOppCon.get(oppConRole.OpportunityId).add(oppConRole);
            
        }
        
        ilib_LogEvent.info('idToOppContRole : ' + (idToOppContRole != Null ? String.valueof(idToOppContRole.keySet()):NULLSTR));
        ilib_LogEvent.info('oppIdToLstOppCon : ' + (oppIdToLstOppCon != Null ? String.valueof(oppIdToLstOppCon.keySet()):NULLSTR));
        ilib_LogEvent.info('oppIdToPrimaryContact : ' + oppIdToPrimaryContact);
        ilib_LogEvent.info('oppIdWithPowerSponsorContact : ' + oppIdWithPowerSponsorContact);
        ilib_LogEvent.info('setParentOppIds : ' + setParentOppIds);

		ContactRoleWrapper objContactRoleWrapper = new ContactRoleWrapper();
        objContactRoleWrapper.idToOppContRole = idToOppContRole;
        objContactRoleWrapper.oppIdToPrimaryContact = oppIdToPrimaryContact;
        objContactRoleWrapper.oppIdWithPowerSponsorContact = oppIdWithPowerSponsorContact;
        objContactRoleWrapper.setParentOppIds = setParentOppIds;
        objContactRoleWrapper.oppIdToLstOppCon = oppIdToLstOppCon;
        
		ilib_LogEvent.info('objContactRoleWrapper : '+ objContactRoleWrapper);
        ilib_LogEvent.pop();
        return objContactRoleWrapper;
    }     

    /**
     * @author Tapas Chakraborty
     * @date   11 Aug 2020
     * @description    DCP-29588 make 1st contact as primary
     * After update trigger method
     **/
    private void makeFirstContactPrimary(List<OpportunityContactRole> lstOCRs) {
        ilib_LogEvent.push(LOG_TITLE+'.makeFirstContactPrimary()');
        if(isConRoleCreatedFromOpp) {
            ilib_LogEvent.pop();
            return;
        }
        
        Set<Id> setOppIds = new Set<Id>();
        List<Id> lstOppIdsToBypass = new List<Id>();
        List<OpportunityContactRole> lstOpportunityContactRole = new List<OpportunityContactRole>();

        for(OpportunityContactRole objOCR : lstOCRs) {
            setOppIds.add(objOCR.OpportunityId);
            if(objOCR.IsPrimary) {
                lstOppIdsToBypass.add(objOCR.OpportunityId);
            }
        }
        ilib_LogEvent.info('setOppIds : '+setOppIds);
        
        lstOpportunityContactRole = new OpportunityContactRoleSelector().selectRoles(setOppIds);

        ContactRoleWrapper objContactRoleWrapper = createOpportunityContactRolesMap(lstOpportunityContactRole);
        Map<Id,Id> oppIdToPrimaryContact = objContactRoleWrapper.oppIdToPrimaryContact;		   
        
        for(OpportunityContactRole objOppConRole : lstOCRs) {            
            if(!oppIdToPrimaryContact.containsKey(objOppConRole.OpportunityId) && !lstOppIdsToBypass.contains(objOppConRole.OpportunityId)) {
                    objOppConRole.IsPrimary = true;
                    lstOppIdsToBypass.add(objOppConRole.OpportunityId);
            }
        }
        ilib_LogEvent.info('oppIdToPrimaryContact : '+oppIdToPrimaryContact);
        ilib_LogEvent.info('lstOppIdsToBypass : '+lstOppIdsToBypass);
        ilib_LogEvent.pop();
    }
	
	 /**
     * @author Maruthi
     * @date   02 Jun 2022
     * @description DCP-52631: added this to get opportunities with selected record type. 
     * Before Insert trigger method
     **/
    private List<OpportunityContactRole> filterOutContactsOnIndirectOpps() { 

        ilib_LogEvent.push(LOG_TITLE+'.filterOutContactsOnIndirectOpps()');
        Map<Id,List<OpportunityContactRole>> mapIdToOppoConRole = UtilsCollection.getMapOfIdToSObjects((List<OpportunityContactRole>)records,'OpportunityId');        
        ilib_LogEvent.info('mapIdToOppoConRole : ' + (mapIdToOppoConRole != Null ? String.valueof(mapIdToOppoConRole.keySet()):NULLSTR));
        List<Opportunity> oppoList = new OpportunitySelector().selectOpportunities(mapIdToOppoConRole.keySet());                        
        Set<String> setRecordTypes = new Set<String>();
        setRecordTypes.add(STRING_INDIRECT_STANDARD);
        setRecordTypes.add(STRING_INDIRECT_ORDER);
        setRecordTypes.add(STRING_INDIRECT_FIELD_SERVICE);
        List<OpportunityContactRole> updateOppoContRol = new List<OpportunityContactRole>();
        for(Opportunity oppo : oppoList) {
            if(setRecordTypes.contains(oppo.RecordType.DeveloperName)) {
                continue;
            }
            updateOppoContRol.addAll(mapIdToOppoConRole.get(oppo.Id));
        }
        ilib_LogEvent.info('updateOppoContRol : '+UtilsCollection.getSetOfIds(updateOppoContRol));
        ilib_LogEvent.pop();                                  
        return updateOppoContRol;
    }


    /**
     * @author Anand
     * @Modifieddate   30-Mar-2022 
     * @description  Inner Class to hold values returned by createOpportunityContactRolesMap method
     **/
    public class ContactRoleWrapper {
        Map<Id,List<OpportunityContactRole>> idToOppContRole ;
        Map<Id,List<OpportunityContactRole>> oppIdToLstOppCon ;
        Map<Id,Id> oppIdToPrimaryContact ;
        List<Id> oppIdWithPowerSponsorContact ;
		Set<Id> setParentOppIds ;   
    }
}
