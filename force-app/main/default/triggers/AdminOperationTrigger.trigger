/**
*    @author Kushagra Desai
*    @date   20-Nov-2019
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger AdminOperationTrigger on Admin_Operation__e (after insert) {
    ilib_SObjectDomain.triggerHandler(AdminOperations.class);
}