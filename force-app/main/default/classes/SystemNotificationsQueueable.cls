/*************************************************************************************
*   @Author:Pooja Shalwadi
*   @Date: 15-06-2021
*   @Description:DCP-46067 to send an emails with attachment to the owner of Parts Order based on inbound received from  SAP to SFDC

Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pooja Shalwadi                15-06-2021         initial version
*    ------------------------------------------------------------------------------------
*/

/*
*  @Author: Pooja Shalwadi
*  @Description: Method to create Attachment and send email 
*/
/*DCP-46067 :Start*/
public class SystemNotificationsQueueable implements Queueable {
    
    map<string, SVMXC__RMA_Shipment_Order__c> mapPartOrder= new map < string, SVMXC__RMA_Shipment_Order__c >();   
    List<System_Notification__c> records= new List<System_Notification__c>();
    set < id > setSysNotificationIds = new set < id > ();
    String strMethodtoExecute; 
    public static final String EMAILATTACHMENT = 'createAttachmentAndSendEmail';
	public static Boolean catchException = false;
    
    /*
    * Constructor method
    *
    *
    */
    public SystemNotificationsQueueable(String strMethodtoExecute,map<string, SVMXC__RMA_Shipment_Order__c> mapPartOrder, List<System_Notification__c> records,Set<id> setSysNotificationIds)
    {
        this.strMethodtoExecute= strMethodtoExecute;
        this.mapPartOrder=mapPartOrder;
        this.records=records;
        this.setSysNotificationIds=setSysNotificationIds;
    }
    /*
    *  Execute method to create attachment and send email
    *  @modification CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions with Workstream.
    *
    */
    public void execute(QueueableContext qc){
        try{
         if(strMethodtoExecute == EMAILATTACHMENT){
          SystemNotifications.createAttachmentAndSendEmail(mapPartOrder,records,setSysNotificationIds);
      }
		if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
		}
    }catch(Exception e){
        //CMSI-38 Emitting exception to ApexExceptions with Workstream.
        ApexExceptions.emit('SystemNotificationsQueueable',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }
    }
}
//DCP-46067 :END
