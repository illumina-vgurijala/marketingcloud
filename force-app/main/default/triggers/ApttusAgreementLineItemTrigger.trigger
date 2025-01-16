/**
*    @author Kushagra Desai
*    @date   19-Dec-2019
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*				Kushagra Desai                19 Dec 2019         Created
*              Kushagra Desai               15-Jan-2020          DCP-33377 : Condition type/Table update; before update
*               B Kamini                     21 Feb 2020         DCP-34092 : Added before delete
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ApttusAgreementLineItemTrigger on Apttus__AgreementLineItem__c (before insert,before update,before delete,after insert,after delete,after update) {
    ilib_SObjectDomain.triggerHandler(ApttusAgreementLineItems.class);
}