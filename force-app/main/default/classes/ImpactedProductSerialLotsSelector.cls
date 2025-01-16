/**
 *    @author Deepak Kumar
 *    @date   30-Mar-2021
 *    @description    Class to get the Impacted product records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Deepak Kumar                 30-Mar-2021             Initial Version  
 *    ------------------------------------------------------------------------------------ 
 *                   
 */
public with sharing class ImpactedProductSerialLotsSelector extends ilib_SObjectSelector
{
   /**
    *  @author Deepak Kumar
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Impacted_Products_Serials_Lots__c.sObjectType;
   }
    
    /**
     *  @author  Deepak Kumar
     *  @description Retrieve list of fields for Case sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Impacted_Products_Serials_Lots__c.id,
           Impacted_Products_Serials_Lots__c.Serial_Number__c,
           Impacted_Products_Serials_Lots__c.Product__c	,
           Impacted_Products_Serials_Lots__c.Lot_Number__c,
           Impacted_Products_Serials_Lots__c.OwnerId,
           Impacted_Products_Serials_Lots__c.Name,
           Impacted_Products_Serials_Lots__c.Field_Action_Notification__c,
           Impacted_Products_Serials_Lots__c.CurrencyIsoCode
          
       };
    }

    private Boolean removeDefaultOrderBy=false;
    /*  
    * @description  Override Default ordering 
    */
    public override String getOrderBy() {
        if(removeDefaultOrderBy){
            return 'CreatedDate DESC';
        }else{
            return super.getOrderBy();
        }
        
    }  

     /**
     *  @author      : Deepak Kumar  
     *  @description : DCP-42002 -Fetch workorder by passing case id as string
     *  @return      : Work Order
     **/
    public List<Impacted_Products_Serials_Lots__c> selectImpactedProductByProductId(String productId) 
    {
        removeDefaultOrderBy = TRUE;

        //CMCM 1021 start
        List<Id> lockedNotificationIds = new List<Id>();
        for (Field_Action_Notification__c notification : [
            SELECT Id
            FROM Field_Action_Notification__c
            WHERE Status__c LIKE '%Locked%']) {
                    lockedNotificationIds.add(notification.Id);
                }
        //CMCM 1021 start
        return (List<Impacted_Products_Serials_Lots__c>) Database.query(
              newQueryFactory()
                            .selectField('Field_Action_Notification__r.Name')                      
                            .selectField('Field_Action_Notification__r.RecordType.Name')
                            .selectField('Field_Action_Notification__r.Mitigations__c')
                            .selectField('Field_Action_Notification__r.Subject__c')//DCP-47394
                            .selectField('Product__r.ProductCode')
                            .selectField('Field_Action_Notification__r.Status__c')//CMCM-1021
                            .setCondition('Product__c = :productId AND Product__c != null AND Field_Action_Notification__c NOT IN :lockedNotificationIds') //CMCM-1021 adding FAN condition
                            .toSOQL()                                       
        );
    }

}