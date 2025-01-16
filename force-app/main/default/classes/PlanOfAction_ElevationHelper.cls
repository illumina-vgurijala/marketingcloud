/**
* @author Shivani Jain
* @date 24 Feb 2022
*
* @description DCP-49675 Helper Class for use in Flow -> Work Order : Send Plan of Action	
*/
public with sharing class PlanOfAction_ElevationHelper {
    
    static final String STRING_COMMENT_NAME = 'Technical POA - ';
    static final String LOG_TITLE = 'PlanOfAction_ElevationHelper';
    /*******************************************************************************************************
    * @description DCP-49675 - Notifictaions for elevation records whenever Plan of Action is updated 
    *                          from flow
    */
    @InvocableMethod(label='Create Comment & Send Email' 
        description='Notifications for Plan of Action for Technical Elevation' category='Elevation')
    public static List<String> sendNotifications(List<Elevations__c> elevationRec) {
        String errMsg = '';
        try {            
            if(elevationRec != NULL && !elevationRec.isEmpty()) {
	        createWOComment(elevationRec[0]);
	        sendEmail(new Set<Id>{elevationRec[0].Id});
            }  
        } catch(Exception e) {
            errMsg = e.getMessage();
            ApexExceptions.emit(LOG_TITLE, e); 
        }
        return new List<String>{errMsg};
    }

    /*******************************************************************************************************
    * @description DCP-49675 - Creation of WO comments for elevation records 
    */
    public static void createWOComment(Elevations__c elevationRec) {
        DateTime dt = System.now();
        
        Comment__c newComment = new Comment__c();
        newComment.Name = STRING_COMMENT_NAME + dt.formatGMT('ddMMMyyyy - HH:mm');
        newComment.Comment__c =elevationRec.Plan_of_Action__c;
        newComment.Work_Order__c = elevationRec.Work_Order__c;
        insert newComment; 
    }


    /*******************************************************************************************************
    * @description DCP-49675 - Send Email Notification
    */
    public static void sendEmail(Set<Id> elevationIds) {
        Set<String> fseRolesSet = new Set<String>();
        Set<String> setAccountIdTeFetchFSERoles = new Set<String>();
        String fseRolseStr = '';

        List<Elevations__c> lstElevationsRecord = new ElevationsSelector().selectElevations(elevationIds);

        if(lstElevationsRecord != NULL && !lstElevationsRecord.isEmpty() && lstElevationsRecord[0].Work_Order__c != NULL) {
            Send_Email_Setting__mdt emailDetails = Send_Email_Setting__mdt.getInstance(Label.Technical_Elevation_Send_Plan_of_Action_Metadata);
            fseRolseStr = emailDetails.To_Address_Roles__c;
            setAccountIdTeFetchFSERoles.add(lstElevationsRecord[0].Work_Order__r.SVMXC__Company__c);
            fseRolesSet.addAll(fseRolseStr.split(';'));

        

            Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(setAccountIdTeFetchFSERoles, fseRolesSet); 
            SendEmailNotification.getSendEmailParamaters(Label.Technical_Elevation_Send_Plan_of_Action_Metadata, lstElevationsRecord, 
                                            accountIdToFSERoles, 'Work_Order__r.SVMXC__Company__c');
        }
    }

    
}
