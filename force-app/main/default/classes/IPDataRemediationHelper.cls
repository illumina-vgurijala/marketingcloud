/**************************************************************************************************************************************
* NAME   : IPDataRemediationHelper
* DESCRIPTION  : Domain class for v.
* Test Class- IPDataRemediationHelper.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 6 -Dec -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                 6 -Dec -2024    

****************************************************************************************************************************************/ 



public with sharing class IPDataRemediationHelper {

	private static Map<Id, Map<String,List<MockHistoryRecord>> > mapIPWithHistoryList = new  Map<Id,Map<String,List<MockHistoryRecord> >>();
    private static Map<Id, SVMXC__Installed_Product__c > ipUpsertMap = new  Map<Id,SVMXC__Installed_Product__c >();
    private static List<String> csvLines = new List<String>();    
    private static Set<Id> sideIds = new Set<Id>();	
    private static final String SITE_FIELD='SVMXC__Site__c';    


     /*
    * @author - Nitin Z
    * @Description-   method to process history records
    */
	public static List<String>  processHistoryRecords(List<MockHistoryRecord> historyRecords,String field) {

		 for(MockHistoryRecord iphistory : historyRecords){
             updateFieldHistoryMap(iphistory);
         } 

		updateIPData(field );
        return csvLines;
       
        
    }

    
     /*
    * @author - Nitin Z
    * @Description-   method to update IP Records
    */
	 private  static void updateIPData(String field){
        Set<String> ipStatusFilter = new Set<String>{'Scrapped','Decommissioned'};
        Set<Id> parentIdList=mapIPWithHistoryList.keySet();
        Map<id,SVMXC__Site__c> mapOfSide= new Map<id,SVMXC__Site__c>();  
        String baseQuery = 'SELECT Id ,'+ field + ' FROM SVMXC__Installed_Product__c WHERE   Id IN :parentIdList and '+field+' = null and SVMXC__Status__c in : ipStatusFilter ';
        Map<Id, SVMXC__Installed_Product__c> installProductMap= new   Map<Id, SVMXC__Installed_Product__c>((List <SVMXC__Installed_Product__c> )Database.query(baseQuery));
        
         if(field==SITE_FIELD){
             mapOfSide= new Map<Id, SVMXC__Site__c>((List<SVMXC__Site__c>)[select Id from SVMXC__Site__c WHERE Id IN :sideIds]);
         }
         
        for (Id parentId : mapIPWithHistoryList.keySet()) {

            if (installProductMap.containsKey(parentId)) {

   			 Map<String, List<MockHistoryRecord>> fieldHistoryMap = mapIPWithHistoryList.get(parentId);
                for (String fieldName : fieldHistoryMap.keySet()) {
                    MockHistoryRecord latestIpHistory = fieldHistoryMap.get(fieldName)[0];
                    SVMXC__Installed_Product__c newRecord = ipUpsertMap.get(parentId) ?? new SVMXC__Installed_Product__c(Id = latestIpHistory.ParentId);

                    switch on fieldName  {
                        when 'Acceptance_Date__c' {
                            newRecord.put('Acceptance_Date__c', latestIpHistory.oldValue);  
                            ipUpsertMap.put(parentId,(SVMXC__Installed_Product__c)newRecord);  
                        }
                        when 'SVMXC__Date_Shipped__c' {
                            newRecord.put('SVMXC__Date_Shipped__c', latestIpHistory.oldValue);
                            ipUpsertMap.put(parentId,(SVMXC__Installed_Product__c)newRecord);  
                        }
                        when 'SVMXC__Date_Installed__c' {
                            newRecord.put('SVMXC__Date_Installed__c', latestIpHistory.oldValue);
                            ipUpsertMap.put(parentId,(SVMXC__Installed_Product__c)newRecord);  
                        }when 'SVMXC__Site__c' {
                            if (mapOfSide.containsKey((Id)latestIpHistory.OldValue)) {
                                newRecord.put('SVMXC__Site__c', (Id)latestIpHistory.OldValue);
                                ipUpsertMap.put(parentId,(SVMXC__Installed_Product__c)newRecord);        
                            }
                        }
                    }
					
                }
            }  
    	}

         try{ 
             if (ipUpsertMap.values().size() > 0) {
                 List<Database.SaveResult> updateResults = Database.update(ipUpsertMap.values(), false);
                 for(Database.SaveResult result : updateResults){
                     if (result.isSuccess()){
                         csvLines.add(result.getId() + ',' + String.valueOf(ipUpsertMap.get(result.getId()).get(field))+',,True,');
                     }else if (!result.isSuccess()){
                         Database.Error error = result.getErrors().get(0);
                         csvLines.add(result.getId() + ',' + String.valueOf(ipUpsertMap.get(result.getId()).get(field))+',,false,'+error.getMessage());
                     }
                     
                 }
             }
         }Catch(Exception ex){
             System.debug('Exeption in updating the IP' + ex.getMessage());
         }
    }
    
    
     /*
    * @author - Nitin Z
    * @Description-   method to  create the fields wise history data
    */
    private static  void updateFieldHistoryMap(MockHistoryRecord  iphistory){
        
        //..
        if(iphistory.isSite()){
            if(!iphistory.isValidSite()){
				return;
        	}
        	sideIds.add((Id)iphistory.oldValue);
        }  
        
        if (!mapIPWithHistoryList.containsKey(iphistory.ParentId)) {
        	mapIPWithHistoryList.put(iphistory.ParentId, new Map<String, List<MockHistoryRecord>>());
   		 }
    	Map<String, List<MockHistoryRecord>> fieldHistoryMap = mapIPWithHistoryList.get(iphistory.ParentId);
        if (!fieldHistoryMap.containsKey((String)iphistory.Field)) {
            fieldHistoryMap.put((String)iphistory.Field, new List<MockHistoryRecord>());
        }
    	fieldHistoryMap.get((String)iphistory.Field).add(iphistory);
	}

   
  /**************************************************************************************************************************************
        * NAME   : MockHistoryRecord
        * DESCRIPTION  : Domain class for v.
        * T
        *  
        *                    
        * @AUTHOR : Nitin Z 
        * @DATE   : 06 -Dec -2024  
        *  
        * MODIFICATION LOG: 
        * --------------------------------------------------------------------------------------------------------------------------------------
        * DEVELOPER                DATE                DESCRIPTION 
        * --------------------------------------------------------------------------------------------------------------------------------------
        Nitin Z                  06 -dec -2024   

        ****************************************************************************************************************************************/ 

   
	public class MockHistoryRecord {
		
        public String field;
        public Object oldValue;
        public Object newValue;
		public String parentId;

        /*
        * @author - Nitin Z
        * @Description-   constructor
        */
        public MockHistoryRecord(String field, Object oldValue, Object newValue,String parentId) {
            this.field = field;
            this.oldValue = oldValue;
            this.newValue = newValue;
			this.parentId = parentId;
        }
        
        /*
        * @author - Nitin Z
        * @Description-   method to check is its valid side id 
        */
        public Boolean isValidSite(){
             return isSite() && ((String)this.OldValue).substring(0, 3) == SVMXC__Site__c.SObjectType.getDescribe().getKeyPrefix();            
        }
        
         /*
        * @author - Nitin Z
        * @Description-   method to check  given field is site field
        */
        public Boolean isSite(){
            return this.field == SITE_FIELD;
        }

    }
    
    
}