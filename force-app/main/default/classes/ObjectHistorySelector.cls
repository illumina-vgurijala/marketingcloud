/**
 *    @author Maruthi
 *    @date   2022-Mar-16
 *    @description  PM:54 Object History Selector 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Maruthi                        2022-Mar-16         Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ObjectHistorySelector extends ilib_SObjectSelector {
    private String strOrderByClause;

    /**
    *  @author Maruthi B 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Object History
    **/
   public Schema.SObjectType getSObjectType() {
        return Object_History__c.sObjectType;
   }

   /**
    * @description  call default orderby method and override with additional parameters
    */
    public override String getOrderBy() {
        string orderBy;
    
        if (String.isNotBlank(strOrderByClause)) {
          orderBy = strOrderByClause;
        } else {
          orderBy = super.getOrderBy();
        }
        return orderBy;
      }

   /**
     *  @author  Maruthi
     *  @description Retrieve list of fields for Object History sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList() { 
    	return new List<Schema.SObjectField> {
        	Object_History__c.id, 
            Object_History__c.Field__c, 
            Object_History__c.New_Value__c,
            Object_History__c.Date__c,
            Object_History__c.Original_Value__c,
            Object_History__c.Source_Object_Record_ID__c,
            Object_History__c.Source_Object__c
        };
    }
    /*
     * @Author : Maruthi B
     * @Decription : Fetch Object History records records by thier Source_Object_Record_ID__c
     * @Param Set Apprus Order Ids
     * @return  List of Apptus Orders
     */
    public List<Object_History__c> selectObjectHistory(String setSourceRecordIds) {
        strOrderByClause = 'CreatedDate desc';
        return (List<Object_History__c>)  Database.query(
            newQueryFactory().selectField('Field__c')
            				.selectField('New_Value__c')
                            .selectField('Date__c') 
                            .selectField('Original_Value__c')
                            .selectField('Source_Object_Record_ID__c')
							.selectField('Source_Object__c')
            				.selectField('User__r.Name')
                            .selectField('User__c') 
                            .selectField('LastModifiedDate')            				                            
            				.setCondition('Source_Object_Record_ID__c = :setSourceRecordIds').toSOQL());
    }
}