/**
 *    @author Anisha Bharti
 *    @date   19-Nov-2020
 *    @description  Trigger on FeedItem
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *  
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
trigger FeedItemTrigger on FeedItem (after insert) {

    ilib_SObjectDomain.triggerHandler(FeedItems.class);
}