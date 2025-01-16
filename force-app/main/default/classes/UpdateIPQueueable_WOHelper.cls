/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger for updating Installed Products 
*/ 
public class UpdateIPQueueable_WOHelper implements Queueable {

    public static Boolean testClassCoverage = false;
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';
    Map<Id, sObject> mapIPIdtoIPObj = new Map<Id, sObject>();
    

    /*******************************************************************************************************
    * @description Constructor
    * @param mapIPIdtoIPObj Map<Id, sObject>
    * @return
    */
    public UpdateIPQueueable_WOHelper(Map<Id, sObject> mapIPIdtoIPObj) {
        this.mapIPIdtoIPObj = mapIPIdtoIPObj;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            upsert mapIPIdtoIPObj.values();
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) { 
            ApexExceptions.emit('UpdateIPQueueable_WOHelper.'+ 'execute', ex); 
            throw ex; 
        }
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}

