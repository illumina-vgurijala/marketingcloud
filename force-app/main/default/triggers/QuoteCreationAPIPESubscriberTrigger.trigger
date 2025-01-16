/**
*    @author Arquimidez Mora
*    @date   29-10-2024
*    @description  Quote Creation API Platform Event trigger
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*          Arquimidez Mora               29 Oct 2024           Initial version
*    ------------------------------------------------------------------------------------ 
*                    
*/

trigger QuoteCreationAPIPESubscriberTrigger on Quote_Creation_API__e (after insert) {
    ilib_SObjectDomain.triggerHandler( QuoteCreationAPIPlatformEvents.class );
}