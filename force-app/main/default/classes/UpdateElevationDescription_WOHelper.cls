/**
* @author Shivani Jain
* @date 8 March 2022
*
* @description DCP-49679 Helper class to update Elevation Description 
* MODIFICATION LOG: 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Nitin Z                11-Nov-2024          CMCM-2184 - // Added Additional detail and Notes
 
*/ 
public with sharing class UpdateElevationDescription_WOHelper implements Queueable {

    List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();

    /*******************************************************************************************************
    * @description Constructor
    * @param woList List<SVMXC__Service_Order__c>
    * @return
    */
    public UpdateElevationDescription_WOHelper(List<SVMXC__Service_Order__c> woList) {
        this.woList = woList;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updateElevationsDescription(woList);
        } catch(Exception ex) {
            ApexExceptions.emit('UpdateElevationDescription_WOHelper.'+ 'updateElevationsDescription', ex);
            throw ex;
        }
        
    }

    /*******************************************************************************************************
    * @description List of Work Orders where Description is updated
    * @param newWORecord SVMXC__Service_Order__c
    * @param oldWOrecord SVMXC__Service_Order__c
    * @return void
    */
    public static void populateWOList(SVMXC__Service_Order__c newWORecord, SVMXC__Service_Order__c oldWOrecord) {
        if(
            newWORecord.SVMXC__Problem_Description__c != oldWOrecord.SVMXC__Problem_Description__c || 
            newWORecord.Notes__c != oldWOrecord.Notes__c || //CMCM-2184
            newWORecord.Additional_Detail__c != oldWOrecord.Additional_Detail__c || //CMCM-2184 
            newWORecord.Business_Impact_to_Customer__c != oldWOrecord.Business_Impact_to_Customer__c
          ) {
            WorkOrders.updatedWOList.add(newWORecord);
        }
    }

    /*******************************************************************************************************
    * @description Update Elevation Description from Work Order 
    * @param woList List<SVMXC__Service_Order__c>
    * @return void
    */
    public static void updateElevationsDescription(List<SVMXC__Service_Order__c> woList) {
        Map<Id, Elevations__c> elevationMap = new  Map<Id, Elevations__c>();

        for(SVMXC__Service_Order__c woRec : woList) {
            if(woRec.Account_Elevation__c != NULL) {
                Elevations__c eRec = new Elevations__c(Id = woRec.Account_Elevation__c, 
                        Work_Order_Description__c = woRec.SVMXC__Problem_Description__c,
                        Notes__c=woRec.Notes__c,
                        Additional_Detail__c=woRec.Additional_Detail__c,
                        Business_Impact_to_Customer__c = woRec.Business_Impact_to_Customer__c);
                elevationMap.put(woRec.Account_Elevation__c, eRec);
            }
            if(woRec.Technical_Elevation__c != NULL) {
                Elevations__c eRec = new Elevations__c(Id = woRec.Technical_Elevation__c, 
                        Work_Order_Description__c = woRec.SVMXC__Problem_Description__c,
                        Notes__c=woRec.Notes__c,
                        Additional_Detail__c=woRec.Additional_Detail__c,
                        Business_Impact_to_Customer__c = woRec.Business_Impact_to_Customer__c);
                elevationMap.put(woRec.Technical_Elevation__c, eRec);
            }            
        }
        if(!elevationMap.isEmpty()) {
            update elevationMap.values();
        }
    }
}