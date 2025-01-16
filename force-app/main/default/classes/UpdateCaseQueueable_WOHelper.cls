/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to update Case
*/ 
public class UpdateCaseQueueable_WOHelper implements Queueable {
    Set<Id> setWOIds = new Set<Id>();
    public static Boolean testClassCoverage = false;
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';

    /*******************************************************************************************************
    * @description Constructor
    * @param setWOIds Set<Id>
    * @return
    */
    public UpdateCaseQueueable_WOHelper(Set<Id> setWOIds) {
        this.setWOIds = setWOIds;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updateIPAndProductOnCase(setWOIds);
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) { 
            ApexExceptions.emit('UpdateCaseQueueable_WOHelper.'+ 'updateIPAndProductOnCase', ex); 
            throw ex; 
        }
       
    }

    /**
    *  @author Nitin Sood
    *  @description - DCP-42922
    *                 To update installed product and product on case 
    *  @PARAM :  
    *  @RETURN:  void
    */ 
	public static void updateIPAndProductOnCase(Set<Id> setWOIds) {
		
		Map<Id, Case > idToCase = new Map<Id, Case>();
		
		for(SVMXC__Service_Order__c objWorkOrder: new WorkOrdersSelector().selectOpenWorkOrdersFromIds(setWOIds)) {
			
			if(objWorkOrder.SVMXC__Component__c !=  objWorkOrder.SVMXC__Case__r.SVMXC__Component__c) {

				if(!idToCase.containsKey(objWorkOrder.SVMXC__Case__c)) {
                    idToCase.put(objWorkOrder.SVMXC__Case__c, new Case(Id = objWorkOrder.SVMXC__Case__c, ContactId = objWorkOrder.SVMXC__Contact__c ,AccountId = objWorkOrder.SVMXC__Company__c ));
				
                } else {
                    idToCase.get(objWorkOrder.SVMXC__Case__c).ContactId = objWorkOrder.SVMXC__Contact__c;
                    idToCase.get(objWorkOrder.SVMXC__Case__c).AccountId = objWorkOrder.SVMXC__Company__c;
				}
			}
			
		}
        
        if(idToCase != null && !idToCase.isEmpty()) {
            update idToCase.values();
        }
    }   

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}