/**
*    @author Deloitte
*    @date   2022-05-10
*    @description    DCP-: Restrict Trainee Related Contacts From Deletion
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Prerna                10th May 2022                To Restrict the users from deleting the trainee record type related contact records
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger RelatedContactTrigger on Related_Contacts__c (before delete) {
    ilib_SObjectDomain.triggerHandler(RelatedContacts.class);
}