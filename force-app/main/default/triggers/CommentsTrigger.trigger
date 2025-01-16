/**
 * Created by tnewman on 11/20/18.
 */

trigger CommentsTrigger on Comment__c (after insert, after update) {
    ilib_SObjectDomain.triggerHandler(Comments.class);
}