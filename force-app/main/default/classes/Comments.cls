/*
*  @Author:
*  @Date: 
*  @Description:
*    @Test Class for above 90% coverage.
      -TestTAPS_Comments
*    @Test Class for atleast 75% coverage.
      -TestTAPS_Comments
*  Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Shivani Jain                  01-April-2022          DCP-49914 Optimize WeChat case and follower management in SFDC.
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class Comments extends ilib_SObjectDomain {

    static final string TYPE_WECHAT = 'WeChat Comment';  //DCP-49914

    /*
     * Constructor for Account Plans
     */
    public Comments(List<Comment__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {

    /*
     * Constructor for Account Plans
     */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Comments(sObjectList);
        }
    }
    

    /*
     * Description - onAfterInsert method
     */
    public override void onAfterInsert()
    {
        asynCallsOnCommentInsert((List<Comment__c>)records); //DCP-49914
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    }
	
    /*
     * Description - onAfterUpdate method
     */
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId', 'Work_Order__c' };
        TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
        if (idsThatNeedRecalculation.size() > 0)
        tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
    }

    /*******************************************************************************************************
    * @description DCP-49914 Method to call logic that will run in async
    * @param objComment Comment Record
    */
    private static void asynCallsOnCommentInsert(List<Comment__c> commentRecs) { 
        Set<Admin_Operation__e> setAdminOperations = new Set<Admin_Operation__e>();

        for(Comment__c objComment : commentRecs) {
            if(objComment.Type__c == TYPE_WECHAT && objComment.Case__c != NULL) {
                setAdminOperations.add(new Admin_Operation__e(Name__c = 'UpdateWeChatCases_CommentManager', Related_Record__c = objComment.Case__c));
                setAdminOperations.add(new Admin_Operation__e(Name__c = 'PerformAdminActions_CommentManager', Related_Record__c = objComment.Id));
            }

        }

        if(!setAdminOperations.isEmpty()) {
            EventBus.publish(new List<Admin_Operation__e>(setAdminOperations));  
        }

    } 
}
