/**
*    @author: Pradeep Kumar Aera
*    @date:   21-Aug-2018
*    @description:  Pardot prospect resubscription trigger for Contact related to DCP-9637
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Joshith K                    21-Sep-2019          Added after Insert Event
*    ------------------------------------------------------------------------------------                    
*/

trigger ContactTrigger on Contact (before insert,after insert,before update, after update,before delete, after delete) {
    ilib_SObjectDomain.triggerHandler(Contacts.class);
}