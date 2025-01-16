/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to update Work Details
*/ 
public class InsertWOResourceQueueable_WOHelper implements Queueable {

    List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
    public static Boolean testClassCoverage = false;
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';

    /*******************************************************************************************************
    * @description Constructor
    * @param lstWorkOrders List<SVMXC__Service_Order__c> 
    * @return
    */
    public InsertWOResourceQueueable_WOHelper(List<SVMXC__Service_Order__c> lstWorkOrders) {
        this.lstWorkOrders = lstWorkOrders;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertWOResourceRecord(lstWorkOrders, null, null);
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) {  
            ApexExceptions.emit('InsertWOResourceQueueable_WOHelper.'+ 'insertWOResourceRecord', ex); 
            throw ex; 
        }
       
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}
