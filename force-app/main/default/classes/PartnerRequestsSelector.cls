/*@ author           : Shaik Moulali
    * @ date         : 10-04-2018
    * @ Description  : selector class for Instructor Training Catalog object
	* @ Test Classes : TestPartnerRequestQueueable,TestPartnerRequestUpdateRecord,TestInstructorLedTrainingController
    *
    * Modification Log:
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Developer                Date                   Modification ID      Description
    * ---------------------------------------------------------------------------------------------------------------------------------------
    * Prakhar Kumar          25-09-2018                                    Initial version
    * Saurav Bhandari        06-03-2020                                    Added Status__c field in the query of selectInstructorLedTrainingCourses method
    * Anish                  15-03-2021                                    Added query by Set of Ids
    * Jitesh Lakhwani        6-July-2022                                   Code Scan fixes of Comments
    */
public with sharing class PartnerRequestsSelector extends ilib_SObjectSelector{
    
    /**
    * @description  This method will return the SObjectType of the Partner Request Object
    * @param : None
    * @return : Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Partner_Request__c.sObjectType;
    }
    
    /*
    * @author Shaik Moulali
    * @date   04-10-2018
    * @description  set select fields
    * 
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{
            Partner_Request__c.Country__c,
            Partner_Request__c.Course_Justification__c,
            Partner_Request__c.Customer_Type__c,
            Partner_Request__c.Email__c,
            Partner_Request__c.First_Name__c,
            Partner_Request__c.How_Can_We_Help__c,
            Partner_Request__c.Last_Name__c,
            Partner_Request__c.License_Type__c,
            Partner_Request__c.Phone__c,
            Partner_Request__c.Postal_Code__c,
            Partner_Request__c.Region__c
        };
    }
    
    /**
    * @description  fetches the list Partner Request record based on Instructor Id
    * @param : Id id
    * @return : List<Partner_Request__c>
    */
    public List<Partner_Request__c> selectInstructorLedTrainingCourses(Id id) 
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Id = :id');
        String strQuery = query.selectField('OwnerId')
            .selectField('Course_Justification__c')
            .selectField('Timeframe_for_Attendance__c')
            .selectField('Requested_Courses__c')
            .selectField('Status__c')
            .toSOQL();
        return Database.query(strQuery);
    }
    
     /*
    * @author Prakhar Kumar
    * @date   14-10-2018
    * @description  fetches the Partner Request record based on Id
    * 
    */
    public List<Partner_Request__c> selectPartnerRequestRecord(String strId) 
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Id =: strId');
        String strQuery = query.selectField('Id')
            .selectField('Name')
            .selectField('Status__c')
          .toSOQL();
          system.debug('Partner Selector selectPartnerRequestRecord SOQL===='+strQuery);
        return Database.query(strQuery);
    }
    
    /*
    * @author Anish
    * @date   15-Mar-2021
    * @description  fetches the Partner Request record based on Id set
    * 
    */
    public List<Partner_Request__c> selectPRRecords(Set<Id> idSet) 
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN: idSet');
        String strQuery = query.selectField('Id')
            .selectField('Name')
            .selectField('Status__c')
            .selectField('RecordType.DeveloperName')
          .toSOQL();
        return Database.query(strQuery);
    }
}