/*****************************************************************************************************************
 * Class Name: UpdateWarningMsg_WorkdetailHelper
 * Description: Queueable class to update warning message on the work order.
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               06-12-2021        Queueable class to update warning message on the work order.
 ******************************************************************************************************************/
public with sharing class UpdateWarningMsg_WorkdetailHelper implements Queueable{
    List < SVMXC__Service_Order_Line__c > records = new List<SVMXC__Service_Order_Line__c>();
	public static Boolean catchException = false;
    /**
     * Constructor
     */
    public UpdateWarningMsg_WorkdetailHelper(List < SVMXC__Service_Order_Line__c > records){
        this.records = records;
    }
    /*
     *  @AUTHOR:  Shruti 
     *  @DESCRIPTION: Method to restrict user from deleting Work Details. Updated for DCP-37747
     *  @MODIFICATION : CMSI-38 Added Try Catch mechanism Emitting exception to ApexExceptions class with Workstream.
     *  @PARAM :  List<SVMXC__Service_Order_Line__c> records
     *  @RETURN:  void
     */
    public void execute(QueueableContext qc){
        try{
        if(!records.isEmpty()){
            ProcessWDBeforeDelete_WorkdetailHelper.updateWarningMessageOnWorkOrder(records);
        }
		if(catchException == true){
				throw new AuraHandledException('throwing custom exception');
			}
        }catch(Exception e){
            //CMSI-38 Emitting exception to ApexExceptions class with Workstream.
            ApexExceptions.emit('UpdateWarningMsg_WorkdetailHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
}
