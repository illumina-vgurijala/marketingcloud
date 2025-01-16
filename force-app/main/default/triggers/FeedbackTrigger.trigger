/**
*    @author Deepak Kumar
*    @date   2020-11-27
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer               Date                Description
*             Deepak                27 Nov 2020           Trigger class for feedback
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger FeedbackTrigger on Feedback__c (before insert, before update, after update,after insert) {
    ilib_SObjectDomain.triggerHandler(Feedbacks.class);
}