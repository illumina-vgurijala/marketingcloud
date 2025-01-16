/* @ author       : Indra Ganesan
 * @ date         : 05-18-2018
 * @ Description  : OpportunityLineItemTrigger handles the logic for events (insert, update, delete)
 *
 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                    Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Indra Ganesan        05-18-2018                  Original Version
 * Govind Dubey	        26-06-2018					Added after delete
 * Akash Kumar          06-08-2018                  Added before delete
 * Prem Ranjan          28-06-2021         Added Befor Insert
 * Dushyant Srivastava  30-11-2021         Added Before Update
*/
trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert,after delete,before delete,before insert,before update) {
   ilib_SObjectDomain.triggerHandler(OpportunityLineItems.class);
 }