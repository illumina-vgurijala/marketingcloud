/*
 *    @author Preetha
 *    @date   02-Sep-2022
 *    @description : Controllerr class for Quality Notification
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description 
 *    --------------------------------------------------------------------------------------
 */
public without sharing class QualityNotificationController {
    private static final String LOG_TITLE = 'QualityNotificationController';
    private static Map<Id, TreeStructure> finalTreeMap;	
	private static Map<Id, SVMXC__RMA_Shipment_Order__c> poMap;
	/**
    Static Method to be fed in @wire for LWC
    */
    @AuraEnabled(cacheable=true)
    public static List<TreeStructure> getPartsOrderWithQN(Id recordId) {
        ilib_LogEvent.push(LOG_TITLE + '.getPartsOrderWithQN()');
        finalTreeMap = new Map<Id, TreeStructure>();
		poMap = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
        try {
            if(recordId!=null) {
                    for(SVMXC__RMA_Shipment_Order__c objPO :new PartsOrdersSelector().selectPartsOrderByCaseId(recordId)) {                
                        poMap.put(objPO.Id,objPO);
                    }
            }
            if(!poMap.isEmpty()) {
                startFetchingPODetails(poMap);
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return finalTreeMap.values();
        } Catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
            throw new AuraHandledException(e.getMessage());
        } 
    }
	 /**
    * Recursion method to get all levels of po and their related records
    */
    private static List<TreeStructure> startFetchingPODetails(Map<Id,SVMXC__RMA_Shipment_Order__c> poMap) {
        ilib_LogEvent.push(LOG_TITLE + '.startFetchingPODetails()');    
        Map<Id, TreeStructure> parentStructure = gatherAllPOInformation(poMap);
        try {
            if(finalTreeMap == null || finalTreeMap.isEmpty()) {
                finalTreeMap.putAll(parentStructure);
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return parentStructure.values();
        } Catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
            throw new AuraHandledException(e.getMessage());
        } 
	}
	/**
    * Method to gather all information for all Parts Orders recieved
    */
    private static Map<Id, TreeStructure> gatherAllPOInformation(Map<Id, SVMXC__RMA_Shipment_Order__c> poMap) {
		Map<Id, TreeStructure> mapToFormTree = new Map<Id, TreeStructure>();
		Map<Id, List<Quality_Notification__c>> poQNMap = new  Map<Id, List<Quality_Notification__c>>();
		Map<Id, List<Quality_Notification__c>> polQNMap = new  Map<Id, List<Quality_Notification__c>>();
		Set<Id> polIdFromQN = new Set<Id>();
		Map<Id, List<SVMXC__RMA_Shipment_Line__c>> poPolMap = new  Map<Id, List<SVMXC__RMA_Shipment_Line__c>>();
        ilib_LogEvent.push(LOG_TITLE + '.gatherAllPOInformation()');    
        try {
            //gather all QN's 
            for(Quality_Notification__c qn : new QualityNotificationSelector().selectQNwithPO(poMap.keySet())) {
                if(qn.Quality_Notification_Number__c!=null) {
                    if(qn.Parts_Order_Line__c ==null) {
                        if(!poQNMap.containsKey(qn.Parts_Order__c)) {
                            poQNMap.put(qn.Parts_Order__c, new List<Quality_Notification__c>());
                        }
                        poQNMap.get(qn.Parts_Order__c).add(qn);
                    }else if(qn.Parts_Order_Line__c !=null) {
                        polIdFromQN.add(qn.Parts_Order_Line__c);
                        if(!polQNMap.containsKey(qn.Parts_Order_Line__c)) {
                            polQNMap.put(qn.Parts_Order_Line__c, new List<Quality_Notification__c>());
                        }
                        polQNMap.get(qn.Parts_Order_Line__c).add(qn);
                    }
                }
            }
            //Getting the Parts Order Line details
            if(polIdFromQN!=null) {
                for(SVMXC__RMA_Shipment_Line__c pol :new PartsOrderLineSelector().selectPartsOrderLineRecords(polIdFromQN)) {
                    if(!poPolMap.containsKey(pol.SVMXC__RMA_Shipment_Order__c)) {
                        poPolMap.put(pol.SVMXC__RMA_Shipment_Order__c, new List<SVMXC__RMA_Shipment_Line__c>());
                    }
                    poPolMap.get(pol.SVMXC__RMA_Shipment_Order__c).add(pol);
                }
            }
            //Building a data structure
            for(Id poId : poMap.keySet()) {
                SVMXC__RMA_Shipment_Order__c po = poMap.get(poId);
                TreeStructure poStructure = new TreeStructure();
                poStructure.label = 'Parts Order: '+po.name;
                poStructure.name = po.Id;
                //add all QN if present for a Parts Order
                if(poQNMap!= null && poQNMap.containsKey(poId)) {
                    List<Items> poqnItemList = new  List<Items>();
                    for(Quality_Notification__c qn :  poQNMap.get(poId)) {
                        Items poqnItem = new Items();
                        poqnItem.label = 'QN-'+qn.Quality_Notification_Number__c;
                        poqnItem.name = qn.Quality_Notification_Number__c;
                        poqnItemList.add(poqnItem);
                    }
                    if(!poqnItemList.isEmpty()) {
                        poStructure.items = poqnItemList;
                    }
                }//add all QN if present for a Parts Order Line
                if(poPolMap!=null && poPolMap.containsKey(poId)) {
                    List<Items> polItemList = new  List<Items>();
                    for(SVMXC__RMA_Shipment_Line__c pol : poPolMap.get(poId)) {
                        Items polItem = new Items();
                        polItem.label = pol.Name+' ('+pol.SVMXC__Product__r.Name+')';
                        polItem.name = pol.Id;
                        if(polQNMap.containsKey(pol.Id)) {
                            List<Items> polqnItemList = new  List<Items>();
                            for(Quality_Notification__c qn : polQNMap.get(pol.Id)) {
                                Items polqnItem = new Items();
                                polqnItem.label = 'QN-'+qn.Quality_Notification_Number__c;
                                polqnItem.name = qn.Quality_Notification_Number__c;
                                polqnItemList.add(polqnItem);
                            }
                            polItem.items = polqnItemList;
                        }
                        polItemList.add(polItem);
                    }
                    if(!polItemList.isEmpty()) {
                        if(poStructure.items == null) {
                            poStructure.items = new List<Items>();
                        }
                        poStructure.items.addAll(polItemList);
                    }
                }
                mapToFormTree.put(poId,poStructure);
            }
            return mapToFormTree;
        } Catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
            throw new AuraHandledException(e.getMessage());
        } 
	}

    /**
   *  @author: Preetha
   *  @description : to get the current App on which the user is on. Default it to service max if the user is community user so that Parts Order and Parts Oder Line would open in new tab.
   *  @return : String.
   **/
  @AuraEnabled
  public static String getCurrentApp() {
    ilib_LogEvent.push(LOG_TITLE + '.getPartsOrderWithQN()');
    try {
        Profile p = [Select Id,Name from Profile where Id =: UserInfo.getProfileId()];
        if(!p.name.containsIgnoreCase('Channel Partner')) {
            // to get the current app.
          List<UserAppInfo> userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
          if(userAppInfo.size()!=0 && !userAppInfo.isEmpty() && userAppInfo !=null) {
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition Where DurableId = :userAppInfo[0].AppDefinitionId LIMIT 1];
            ilib_LogEvent.pop();
            return appDefinition.Label;
          } else {
            return 'Service Console';
          }
        } else {
            ilib_LogEvent.pop();
            return 'Service Max';
      }
    } Catch(Exception e) {
        ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE);
        ilib_LogEvent.pop();
        throw new AuraHandledException(e.getMessage());
    }
  }
	/*
    Wrapper class to form a Parent tree structure 
    */
	public class TreeStructure {
        @AuraEnabled 
        public String label {get;set;}
        @AuraEnabled 
        public String name {get;set;}
        @AuraEnabled 
        public List<Items> items {get;set;}
    }
    /*
    Wrapper class to form a Child structure 
    */
    public Class Items {
        @AuraEnabled 
        public String label {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled 
        public List<Items> items {get;set;} 
    }
}