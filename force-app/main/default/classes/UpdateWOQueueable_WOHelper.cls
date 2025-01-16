/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to update Case
*/ 
public class UpdateWOQueueable_WOHelper implements Queueable {
    List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';
    public static Boolean testClassCoverage = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param lstWorkOrders List<SVMXC__Service_Order__c>
    * @return
    */
    public UpdateWOQueueable_WOHelper(List<SVMXC__Service_Order__c> lstWorkOrders) {
        this.lstWorkOrders = lstWorkOrders;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updateWOFields(lstWorkOrders);
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) {
            ApexExceptions.emit('UpdateWOQueueable_WOHelper.'+ 'updateWOFields', ex);
            throw ex;
        }
    }

    /**
    *  @author Nitin Sood
    *  @description - DCP-42922
    *                 To update WO with the values  
    *  @PARAM :  
    *  @RETURN:  void
    */ 
    public static void updateWOFields(List<SVMXC__Service_Order__c> lstWorkOrders) {
        if(lstWorkOrders != null && !lstWorkOrders.isEmpty()) {
            Update lstWorkOrders;
        }
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}
}

