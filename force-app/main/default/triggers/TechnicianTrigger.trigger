/**
*    @author Akash Kumar
*    @date   2018-05-15
*    @description    DCP-758:Populate Field Service fields on Opportunity
*    Modification Log:
*    -------------------------------------------------------------------------------------------------
*             Developer                      Date                      Description
*            Akash Kumar                28th September 2018           
*    ------------------------------------------------------------------------------------------------- 
*                    
*/
trigger TechnicianTrigger on SVMXC__Service_Group_Members__c (after update,after insert) {

    ilib_SObjectDomain.triggerHandler(Technicians.class);

}