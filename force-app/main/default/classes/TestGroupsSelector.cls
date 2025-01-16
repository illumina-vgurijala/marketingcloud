/*@ author       : 
* @ date         : 
* @ Description  : TestGroupsSelector Test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Parthasarathy D      10-Oct-2022                                 Codescan Fix- Added Header comments.
* Rishi Sharma         16-Jan-2023                                 Codescan Fix- Avoid Unused Local Variables.
* 
*/
@isTest(SeeAllData = false)
public with sharing class TestGroupsSelector {
    static testMethod void testmethodQueueOwnerSelector() {
            Group g1 = new Group(Name='TS_Informatics', type='Queue');
            insert g1;
            
        test.startTest();
         QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Lead');
         insert q1;
         List<String> lstQueueName = new List<String>{'Feedback_Reviewers'};
         GroupsSelector gs = new GroupsSelector();         
         List<Group> groupLst =  gs.getQueueIdsbyDevName(new set<String> { 'TS_LIMS','CS_GC_Customer_Service'});
         System.Assert(!groupLst.isEmpty(),'List of group is not empty');
         List<Group> groupObj =  gs.getQueueIdbyDeveloperName(lstQueueName,'Queue');
         System.assert(groupObj[0].Id != null, 'No such Queue with DevName as Feedback Reviewers');                   
        test.stopTest();   
    }
}