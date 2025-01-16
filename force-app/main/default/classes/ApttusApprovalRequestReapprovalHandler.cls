/**
*  @date   2024-06-12
*  @description    Reapproval handler for Quotation
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
   -TestApttusApprovalRequestReapproval
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Kumar Gaurav       14-Jun-2024   Initial Development
*      Sai Pasumarthy     11-Sep-2024   DGP-956
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class ApttusApprovalRequestReapprovalHandler {
    public static integer level2 = 2;
    public static integer level8 = 8;
    public static integer level3 = 3;
    public static integer level5 = 5;
        /*
    *@author Kumar Gaurav
    *@Param -> List<Apttus_Proposal__Proposal__c> newProposals, Map<Id,SObject> newProposalMap, Map<Id,SObject> oldProposalMap
    *@description -> Evaluates and updates flag on quotes for reapproval
    */
	public static void evaluateLinesForReapproval(List <Apttus_Approval__Approval_Request__c> lstApprovalRequest)
    {
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, Reapproval_Reference__c> quoteIdtoReapprovalRefMap = new Map<Id, Reapproval_Reference__c>();
        List<Reapproval_Reference__c> updatedReapprovRefs = new List<Reapproval_Reference__c>();
        for (Apttus_Approval__Approval_Request__c req:lstApprovalRequest){
            quoteIds.add(req.Apttus_QPApprov__ProposalId__c);
        }
        if (quoteIds != null && quoteIds.size() > 0){
            quoteIdtoReapprovalRefMap = getquoteIdtoReapprovalRefMap(quoteIds);
        }
        Map<string,String> salesApprovalLevelMap = new Map<string,String>();
        Map<string,String> financeApprovalLevelMap = new Map<string,String>();
        for (integer i=level2;i<=level8;i++) {
            salesApprovalLevelMap.put('Sales Level '+i, 'Level_'+i+'_Line_Data__c');
            salesApprovalLevelMap.put((i-1).toString(), 'Level_'+i+'_Line_Data__c');
        }
        for (integer i=level2;i<=level5;i++) {
            financeApprovalLevelMap.put('Finance Level '+i, 'Level_'+i+'_Finance_Line_Data__c');
        }
        String approved = 'Approved'; 
        for(Apttus_Approval__Approval_Request__c approvalRequest : lstApprovalRequest){
            updatedReapprovRefs = updateReapprovalReference(approvalRequest,salesApprovalLevelMap,financeApprovalLevelMap,quoteIdtoReapprovalRefMap,approved);
        }
        ilib_LogEvent.info('updatedReapprovRefs -->: '+updatedReapprovRefs);
        if(updatedReapprovRefs != null && updatedReapprovRefs.size() > 0){
            Database.update(updatedReapprovRefs);
        }
        ilib_LogEvent.pop(); 
    }
    private static Map<Id, Reapproval_Reference__c> getquoteIdtoReapprovalRefMap(Set <Id> quoteIds)
    {
        Map<Id, Reapproval_Reference__c> quoteIdtoReapprovalRefMap = new Map<Id, Reapproval_Reference__c>();
        for (Reapproval_Reference__c reApprovRef: new ReapprovalReferenceSelector().selectByQuoteId(quoteIds)){
            quoteIdtoReapprovalRefMap.put(reApprovRef.Quote_Proposal_Id__c,reApprovRef);
        }
        Return quoteIdtoReapprovalRefMap;
    }
    
    private static List<Reapproval_Reference__c> updateReapprovalReference(Apttus_Approval__Approval_Request__c approvalRequest,
        Map<string,String> salesApprovalLevelMap,Map<string,String> financeApprovalLevelMap,
        Map<Id, Reapproval_Reference__c> quoteIdtoReapprovalRefMap,String approved)
    {
        List<Reapproval_Reference__c> updatedReapprovRefs = new List<Reapproval_Reference__c>();
        ilib_LogEvent.info('Apttus_Approval__Approval_Status__c -->: '+approvalRequest.Apttus_Approval__Approval_Status__c);
        ilib_LogEvent.info('Apttus_Approval__StepLabel__c -->: '+approvalRequest.Apttus_Approval__StepLabel__c);
        ilib_LogEvent.info('quoteIdtoReapprovalRefMap'+quoteIdtoReapprovalRefMap);
        if (quoteIdtoReapprovalRefMap.containsKey(approvalRequest.Apttus_QPApprov__ProposalId__c) && approvalRequest.Apttus_Approval__Approval_Status__c == approved
           && !approvalRequest.Apttus_Approval__AutoReapprove__c){
            Reapproval_Reference__c reApprovRef = (Reapproval_Reference__c) quoteIdtoReapprovalRefMap.get(approvalRequest.Apttus_QPApprov__ProposalId__c);

            if (salesApprovalLevelMap.containsKey(approvalRequest.Apttus_Approval__StepLabel__c)){
                ilib_LogEvent.info('salesApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c)'+salesApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c));
                reApprovRef.put(salesApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c),reApprovRef.Current_Line_Data__c);
            }
            if (FinanceApprovalLevelMap.containsKey(approvalRequest.Apttus_Approval__StepLabel__c)){
                ilib_LogEvent.info('FinanceApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c)'+FinanceApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c));
                reApprovRef.put(FinanceApprovalLevelMap.get(approvalRequest.Apttus_Approval__StepLabel__c),reApprovRef.Current_Line_Data__c);
            }
            updatedReapprovRefs.add(reApprovRef);
        }
        ilib_LogEvent.info('updatedReapprovRefs'+updatedReapprovRefs);
        Return updatedReapprovRefs;
    }
}