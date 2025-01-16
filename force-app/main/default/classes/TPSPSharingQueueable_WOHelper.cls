/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger for TPSP Sharing
*/ 
public class TPSPSharingQueueable_WOHelper implements Queueable {

    Map<Id, sObject> mapsObjects = new Map<Id, sObject>();
    String methodName;
    public static Boolean testClassCoverage = false;
    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';

    /*******************************************************************************************************
    * @description Constructor
    * @param mapsObjects Map<Id, sObject>
    * @return
    */
    public TPSPSharingQueueable_WOHelper( Map<Id, sObject> mapsObjects) {
        this.mapsObjects = mapsObjects;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            TPSPWorkOrderShareService.shareRelatedRecordsWithWOOwner(mapsObjects);
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) { 
            ApexExceptions.emit('TPSPSharingQueueable_WOHelper.'+ 'shareRelatedRecordsWithWOOwner', ex); 
            throw ex; 
        }
        
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}
