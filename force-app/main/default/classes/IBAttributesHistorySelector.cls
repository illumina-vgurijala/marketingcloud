/***************************************************************************************************************************************
* @author Shivani Jain
* @date 16 Sep 2022
*
* @description DCP-52682 Selector Class for SVMXC__SM_IB_Attributes_History__c
* @Test Class - TestInstalledProductsSelector
*/
public with sharing class IBAttributesHistorySelector extends ilib_SObjectSelector {
    public static String stringSortOrder = 'CreatedDate DESC';

    /*******************************************************************************************************
    * @description Method to return Object Type
    * @return Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType() {
        return SVMXC__SM_IB_Attributes_History__c.sObjectType;
    }

    /*******************************************************************************************************
    * @description Method to override Order by
    * @return String
    */
	public override String getOrderBy() {
        return stringSortOrder;
    }

    /*******************************************************************************************************
    * @description Retrieve list of fields for SVMXC__SM_IB_Attributes_History__c sObject
    * @return List<Schema.SObjectField>
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField> {
            SVMXC__SM_IB_Attributes_History__c.Id,
            SVMXC__SM_IB_Attributes_History__c.CreatedDate
        };
    }

}