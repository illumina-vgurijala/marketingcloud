/***************************************************************************************************************************************
* NAME   : LocationsCovered
* DESCRIPTION  : Domain class for LocationsCoveredTrigger
*                    
* @AUTHOR : Debanka Chakraborty
* @DATE   : 19th June 2019 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* -------------------------------------------------------------------------------------------------------------------------------------- 
*   Debanka               19th June 2019          Method to Populate federation id on Locations Covered fields(On After Insert,
*                                                 On After Delete)
****************************************************************************************************************************************/
public with sharing class LocationsCoveredCls extends ilib_SObjectDomain{

		/*
         * Constructor
         */
 public LocationsCoveredCls (List<SVMXC__Service_Group_Site__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    { 
	     /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new LocationsCoveredCls(sObjectList);
        }
    }
    
		/*
         * description - onAfterInsert method
		 * return - void
         */	
    public override void onAfterInsert()
    {
         Set<ID> setFieldSupportLocationIds = new Set<Id>();
 
        for (SVMXC__Service_Group_Site__c objLocationsCovered : (List<SVMXC__Service_Group_Site__c>)records)
        {
            if(objLocationsCovered.SVMXC__Site__c != null) {
                    setFieldSupportLocationIds.add(objLocationsCovered.SVMXC__Site__c);
                
                }
        }
        
        if(!setFieldSupportLocationIds.isEmpty()) {
            
           updateFieldSupportIdsOnLocation(setFieldSupportLocationIds);
          }
    }

		/*
         * description - onAfterDelete method
		 * return - void
         */
    public override void onAfterDelete()
    {
        Set<ID> setFieldSupportLocationIds = new Set<Id>();
        for(SVMXC__Service_Group_Site__c objLocationsCovered : (List<SVMXC__Service_Group_Site__c>)records){
            if(objLocationsCovered.SVMXC__Site__c != null) {
               setFieldSupportLocationIds.add(objLocationsCovered.SVMXC__Site__c);
            } 
        }
        if(!setFieldSupportLocationIds.isEmpty()) {
          updateFieldSupportIdsOnLocation(setFieldSupportLocationIds);
        }
    }
    
		/*
         * description - onAfterUpdate method
		 * return - void
         */	
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
        {
        Set<ID> setFieldSupportLocationIds = new Set<Id>();
        for(SVMXC__Service_Group_Site__c objLocationsCovered : (List<SVMXC__Service_Group_Site__c>)records){
            if(objLocationsCovered.SVMXC__Site__c != null) {
               setFieldSupportLocationIds.add(objLocationsCovered.SVMXC__Site__c);
            } 
        }
        if(!setFieldSupportLocationIds.isEmpty()) {
          updateFieldSupportIdsOnLocation(setFieldSupportLocationIds);
        }
    }
        
    
    /**
     *  @AUTHOR:  Debanka
     *  @DESCRIPTION: This method updates field support ids on Location
     *  @PARAM :  set<Id> setFieldSupportLocationIds
     */
    private void updateFieldSupportIdsOnLocation(set<Id> setFieldSupportLocationIds) {
        
        map<Id, String> fieldSupportIdMap = new map<Id, String>();
        list<SVMXC__Site__c> locToUpdateLst = new list<SVMXC__Site__c>();
        map<Id, list<SVMXC__Service_Group_Site__c>> mapLocToFieldSupport = new map<Id, list<SVMXC__Service_Group_Site__c>>();
        
        for(SVMXC__Service_Group_Site__c objFieldSupport : new LocationsCoveredSelector().selectLocationsCovered(setFieldSupportLocationIds)) {
                                                                
            String uniqueUserIdentifier = objFieldSupport.SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.FederationIdentifier != null ? 
                                          objFieldSupport.SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.FederationIdentifier : '';
            
            uniqueUserIdentifier = objFieldSupport.SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.Alias != null ? 
                                   uniqueUserIdentifier + objFieldSupport.SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.Alias : uniqueUserIdentifier;
            
            if(!mapLocToFieldSupport.containsKey(objFieldSupport.SVMXC__Site__c)) {
                mapLocToFieldSupport.put(objFieldSupport.SVMXC__Site__c, new list<SVMXC__Service_Group_Site__c>());
            } 
            mapLocToFieldSupport.get(objFieldSupport.SVMXC__Site__c).add(objFieldSupport);
            fieldSupportIdMap.put(objFieldSupport.Id,uniqueUserIdentifier);
        }
        
        for(Id locationId : mapLocToFieldSupport.keySet()) {
            String fieldSupportIds = '';
            
            SVMXC__Site__c objLocation = new SVMXC__Site__c(Id = locationId);
            for(SVMXC__Service_Group_Site__c objFieldSupport : mapLocToFieldSupport.get(locationId)) {
               
                if(fieldSupportIdMap.containsKey(objFieldSupport.Id)){
                    if(!(String.ISBLANK(fieldSupportIdMap.get(objFieldSupport.Id)))){
                        if(!fieldSupportIds.contains(fieldSupportIdMap.get(objFieldSupport.Id))){
                            fieldSupportIds = (fieldSupportIds != ''  ? fieldSupportIds+','+fieldSupportIdMap.get(objFieldSupport.Id) : fieldSupportIdMap.get(objFieldSupport.Id));
                        }
                    }
                }
            }
            
            if(fieldSupportIds !='' ){ 
                objLocation.Field_Support_IDs__c = fieldSupportIds;
                locToUpdateLst.add(objLocation);
            }
        }
        
        if(locToUpdateLst.size() > 0){
            update locToUpdateLst;
        }
    }

}