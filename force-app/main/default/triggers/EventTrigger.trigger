/**
*    @author: Rishab Wali
*    @date:   06-Jan-2022
*    @description:  Apex Trigger for Events objects 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger EventTrigger on Event (after insert , after update) {

    ilib_SObjectDomain.triggerHandler(Events.class);

}