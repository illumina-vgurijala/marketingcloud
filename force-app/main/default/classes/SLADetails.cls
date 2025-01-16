/**
*    @author Mandeep Singh
*    @date   13-Sep-2018
*    @description    Domain class for SLADetailTrigger
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*           Mandeep Singh                 13-Sep-2018           Initial Version
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class SLADetails extends ilib_SObjectDomain {


		/*
         * Constructor
         */    
    public SLADetails(List<SVMXC__SLA_Detail__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new SLADetails(sObjectList);
        }
    }    
      
    /*
    * @author Mandeep Singh
    * @date   13 Sep 2018
    * @description  after insert trigger method
    */
    public override void onAfterInsert(){
        Set<id> setSLATermIds = new Set<id>();
        for (SVMXC__SLA_Detail__c item : (List<SVMXC__SLA_Detail__c>)records){
            setSLATermIds.add(item.SVMXC__SLA_Terms__c);
        }
     
        if(!setSLATermIds.isEmpty()){
                populateLeastSLA(setSLATermIds);
        }
    }

    /*
    * @author Mandeep Singh
    * @date   13-Sep-2018
    * @description  after update trigger method
    */
    public override void onAfterUpdate(Map<Id, SObject> oldRecords){    
        Set<id> setSLATermIds = new Set<id>();
        for (SVMXC__SLA_Detail__c objSLADetail: (List<SVMXC__SLA_Detail__c>)records){
            SVMXC__SLA_Detail__c objOldSLADetail= (SVMXC__SLA_Detail__c)(oldRecords.get(objSLADetail.Id));
            if(objOldSLADetail.SVMXC__Customer_Commitment__c != objSLADetail.SVMXC__Customer_Commitment__c){
                setSLATermIds.add(objOldSLADetail.SVMXC__SLA_Terms__c);
            }
        }
        
        if(!setSLATermIds.isEmpty()){
            populateLeastSLA(setSLATermIds);
        }
    }
    
    /*
    *@author Mandeep Singh
    *@date 13-Sep-2018
    *@description Method to populate Least SLA field
    *@param Set<Id> SLA term Ids
    */
    public void populateLeastSLA(Set<Id> setSLATermIds){
        List<SVMXC__Service_Level__c> listSLATermsToUpdate = new List<SVMXC__Service_Level__c>();
        Map<Id,Decimal> mapSLATerm = new Map<Id,Decimal>();
        if(!setSLATermIds.isEmpty()){
            for(SVMXC__SLA_Detail__c objSLADetails : new SLADetailsSelector().selectSLADetailsFromSLATermIds(setSLATermIds)){
                if(!mapSLATerm.containsKey(objSLADetails.SVMXC__SLA_Terms__c) && objSLADetails.SVMXC__Customer_Commitment__c != null){
                    mapSLATerm.put(objSLADetails.SVMXC__SLA_Terms__c,objSLADetails.SVMXC__Customer_Commitment__c);
                }
            }
        }
    
        if(!mapSLATerm.isEmpty()){
            for(SVMXC__Service_Level__c objSLATerm :new SLATermsSelector().selectSLATermsFromIds(mapSLATerm.keyset())){
                objSLATerm.Least_SLA__c = mapSLATerm.get(objSLATerm.Id);
                listSLATermsToUpdate.add(objSLATerm);
            }
        }
    
        if(!listSLATermsToUpdate.isEmpty()){
            update listSLATermsToUpdate;
        }  
    }
}