/**
*    @author Rahul Sharma
*    @date   2018-08-25
*    @description    DCP-10312: Transborder Price List
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Sharma                25 Aug 2018            To populate the price list on Account Sales Area
*             Roopal Verma                10 Dec 2018            Adding After Insert Event
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger AccountSalesAreaTrigger on Account_Sales_Area__c (before update,before insert,after insert) {
    
        ilib_SObjectDomain.triggerHandler(AccountSalesAreas.class);
    
}