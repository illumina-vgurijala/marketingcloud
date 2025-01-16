/* @ author       : PA
* @ date         : 10-May-2022
* @ Description  : RelatedContact Trigger helper class contains all Business logic implementation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                  Date                   Modification ID                   Description
* Prerna Agrawal             10-Aug-22              Val Regression Defect             Restrict Field Service Users to Delete Trainee records.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class RelatedContacts extends ilib_SObjectDomain{
    private static Map<String, Schema.RecordTypeInfo> nameToRecordType;
    /*
     * Constructor for Related Contacts
     */
    public RelatedContacts(List <Related_Contacts__c> sObjectList) {
        super(sObjectList);
    }
    
    /*******************************************************************************************************
    * @description  Before Delete Logic for Related Contact Trigger
    * @param
    * @return void
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable{
        
        /****************************************************************************************************
        * @description  construct method
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList){
            return new RelatedContacts(sObjectList);
        }
    }
    /*******************************************************************************************************
    * @description  retrieve Record Type Name for sobject
    * @param
    * @return map
    */
    public static Map<String, Schema.RecordTypeInfo> getNameToRecordType(){
        if (nameToRecordType == null){
            nameToRecordType = Related_Contacts__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        }
        return nameToRecordType;
    }
        
    /*******************************************************************************************************
    * @description  Before Delete Logic for Related Contact Trigger
    * @param
    * @return void
    */
    public override void onBeforeDelete() {
        List<Related_Contacts__c> oldRecords = (List<Related_Contacts__c>) records;
        restrictUsersToDeleteTraineeRecords(oldRecords);
    }

    /*******************************************************************************************************
    * @description  Restrict Field Service Users To Delete Trainee Records
    * @param
    * @return void
    */
    public void restrictUsersToDeleteTraineeRecords(List<Related_Contacts__c> oldRecordsList) {
        String loggedInUserId = UserInfo.getUserId();
        String recordTypeName = 'Elevation Member';
        Id recordTypeId = getNameToRecordType().get(recordTypeName).getRecordTypeId();
        for(Related_Contacts__c relatedConObj : oldRecordsList){
            if(relatedConObj.recordTypeId != recordTypeId && relatedConObj.OwnerId != loggedInUserId){
                relatedConObj.addError(Label.Error_Message_On_Trainee_Deletion);
            }
        }
    }

    
}