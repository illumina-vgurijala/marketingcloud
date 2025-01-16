/* @ author       : KD
* @ date         : 15-Apr-2021
* @ Description  : Notification Detail Trigger helper class contains all Business logic implementation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class NotificationDetails extends ilib_SObjectDomain{
    /*
     * Constructor for Account Plans
     */
    public NotificationDetails(List<Notification_Detail__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
         * Constructor for Account Plans
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new NotificationDetails(sObjectList);
        }
    }
    /**
     *  @author       : Kushagra Desai
     *  @description  : Add afterinsert handler
     *  @return       : void
     */
    public override void onBeforeInsert(){
      
        updateImpactedField(records);
    }
    /** 
     * @description  onBeforeUpdate method
     */
    public override void onBeforeUpdate(Map<Id, SObject> idToOldRecords){
        List<Notification_Detail__c> lstNotificationDetails = new List<Notification_Detail__c>();
        for(Notification_Detail__c objND : (List<Notification_Detail__c>) records){
            Notification_Detail__c objOldND = (Notification_Detail__c)idToOldRecords.get(objND.id);
            if(objND.Rule_Syntax__c != objOldND.Rule_Syntax__c){
                lstNotificationDetails.add(objND);
            }
        }
        if(!lstNotificationDetails.isEmpty())
            updateImpactedField(lstNotificationDetails);
    }
	/** 
     * method: updateImpactedField
	 *Author: Kushagra Desai
     */
    public static void updateImpactedField(List<Notification_Detail__c> lstNotificationDetails){
        for(Notification_Detail__c objND : (List<Notification_Detail__c>) lstNotificationDetails){
            MSNotificationRuleEngine.getImpactedFields(objND.Rule_Syntax__c);
            System.debug('Trigger --setImpactedField'+MSNotificationRuleEngine.setImpactedField);
            objND.Impacted_Fields__c = String.join(new List<String>(MSNotificationRuleEngine.setImpactedField),';');
            objND.Impacted_Fields__c = objND.Impacted_Fields__c + ';Region';
        }
    }

}