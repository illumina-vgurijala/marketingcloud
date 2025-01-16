/**
 *    @author Monika
 *    @date   10-Nov-2020
 *    @description: Controller Class for LWC SubmitKnowledgeArticleApproval  
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Monika Parihar              27-Nov-2020           Original version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class SubmitKAApprovalController {  
    /*
    * @author Monika Parihar
    * @params Id knowledgeArticleId, string approvalComment
    * @returns boolean
    */ 
    @AuraEnabled  
     public static string submitApproval(Id knowledgeArticleId, String approvalComment){
         Map<String,String> mapWorkFlowValues = new Map<String,String>(); 
         Set<Id> setKnowledgeId = new Set<Id>();
         setKnowledgeId.add(knowledgeArticleId);
         try{
             List<Knowledge__kav> knowledgeArticleList  = new KnowledgeArticlesSelector().selectById(setKnowledgeId);
             for(Knowledge__kav objKnowledge :knowledgeArticleList){
                 mapWorkFlowValues.put(objKnowledge.Id, objKnowledge.Primary_WorkFlow__c);
             }
             if(!mapWorkFlowValues.isEmpty()){
                Map<String,String> mapWorkFlowQueueId = new Map<String,String>();
                Map<String,String> mapGroupNameId = new Map<String,String>();
                // get custom approval matrix record
                Id idKnowledgeMatrixApproval =  Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get(label.Knowledge_Approval_Matrix_Recordtype).getRecordTypeId();
                List <Custom_Approval_Matrix__c> lstCustomAppMatrix = new CustomApprovalMatrixSelector().returnCustomApprovalMatrixObj(mapWorkFlowValues.Values() , idKnowledgeMatrixApproval  );
                if(lstCustomAppMatrix.size()>0){
                    for(Custom_Approval_Matrix__c approvalMatrix : lstCustomAppMatrix){
                        mapWorkFlowQueueId.put(approvalMatrix.Name,approvalMatrix.Email_Queue__c);
                    }
                }
                // get queue record
                List<Group> groupList = new GroupsSelector().getQueueIdbyDeveloperName(mapWorkFlowQueueId.values(),Label.Queue);
                for(Group objGroup : groupList){
                     mapGroupNameId.put(objGroup.DeveloperName,objGroup.Id);
                }
                for(Id objKnowledgeId : mapWorkFlowValues.keyset()){
                    String strWorkFlowVal = mapWorkFlowValues.get(objKnowledgeId);
                    // submit for Approval  
                    SubmitKAApprovalController.submitApprovalProcess(objKnowledgeId, mapGroupNameId.get(mapWorkFlowQueueId.get(strWorkFlowVal)),approvalComment);   
                } 
             }
         }
         catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
         } 
         return 'success';
      }
     /*
     * @author Monika Parihar
     * @params Id knowledgeArticleId, string approvalComment
     * @returns void
     */ 
    public static void submitApprovalProcess(Id knowledgeArticleId,String grpObj,String approvalComment){          
         Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
         req.setComments(approvalComment);        
         req.setObjectId(knowledgeArticleId);
         req.setNextApproverIds(new Id[] {grpObj}); 
         Approval.process(req);
    }
}