/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger for CreAte Associated Code for Abandoned WO
*/ 
public class AbandonedStatusQueueable_WOHelper implements Queueable {

    public static Boolean testClassCoverage = false;
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';
    Set<Id> setAbandonedWOId = new Set<Id>();

    /*******************************************************************************************************
    * @description Constructor
    * @param setAbandonedWOId Set<Id>
    * @return
    */
    public AbandonedStatusQueueable_WOHelper(Set<Id> setAbandonedWOId) {
        this.setAbandonedWOId = setAbandonedWOId;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            WorkOrdersCustomerAbandonedService.createAssociatedCodeOnAbandonedWO(setAbandonedWOId);
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) { 
            ApexExceptions.emit('AbandonedStatusQueueable_WOHelper.'+ 'createAssociatedCodeOnAbandonedWO', ex); 
            throw ex; 
        }
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}

