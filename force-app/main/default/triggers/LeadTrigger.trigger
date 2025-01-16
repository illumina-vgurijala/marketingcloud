/**
*    @author: Pradeep Kumar Aera
*    @date:   21-Aug-2018
*    @description:  Pardot prospect resubscription trigger for Lead related to DCP-9637
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Joshith K                     21-Sep-2019        after insert logic link Software Download records to lead
*    ------------------------------------------------------------------------------------ 
*                    
*/

trigger LeadTrigger on Lead (before insert,after insert,before update,after update,after delete) {
    ilib_SObjectDomain.triggerHandler(Leads.class);
}