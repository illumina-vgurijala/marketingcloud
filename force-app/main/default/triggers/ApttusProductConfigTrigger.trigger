/**
*    @author Kristiyan Petkov
*    @date   2018-10-19
*    @description    DCP-15146: Selection of Explicit Promotions
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Kristiyan Petkov               27 May 2018
*    -------------------------------------------------------------------------------------------------------------------
*                    
*/
trigger ApttusProductConfigTrigger on Apttus_Config2__ProductConfiguration__c (before insert, after insert, before update, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusProductConfigurations.class);
}