/**
*  @date   2024-06-12
*  @description    Reapproval handler for Quotation
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
-TestTAPS_ApttusProposals
-TestOpportunities
-TestApttusOrders
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Kumar Gaurav       14-Jun-2024   Initial Development for DGP-31
*      Kumar Gaurav       24-Jul-2024   CMCM-9219
*      Sai Pasumarthy     11-Sep-2024   DGP-956
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class ApttusProposalReapprovalHandler {
    private static final String LOG_TITLE = 'ApttusProposalReapprovalHandler.';
    
    
    public static Map<string, Reapproval_Reference__c> quoteIdtoReapprovalRefMap = new Map<string, Reapproval_Reference__c>();
    public static final string STATUSFINALIZED = 'Finalized';
    /*
*@author Kumar Gaurav
*@Param -> List<Apttus_Proposal__Proposal__c> newProposals, Map<Id,SObject> newProposalMap, Map<Id,SObject> oldProposalMap
*@description -> Evaluates and updates flag on quote for reapproval
*/
    public static void evaluateLinesForReapproval(List<Apttus_Proposal__Proposal__c> newProposals, Map<Id,SObject> newProposalMap, Map<Id,SObject> oldProposalMap){
        ilib_LogEvent.push(LOG_TITLE+'.evaluateLinesForReapproval()');
        List<Apttus_Proposal__Proposal__c> firstCycleQuotes = new List<Apttus_Proposal__Proposal__c>();
        List<Apttus_Proposal__Proposal__c> nextCycleQuotes = new List<Apttus_Proposal__Proposal__c>();
        //-- Segregate quotes as initial submission for approval or submitted for reapproval
        Map<id,Apttus_Proposal__Proposal__c> proposaMap = (Map <id,Apttus_Proposal__Proposal__c>)newProposalMap;
        
        for (Apttus_Proposal__Proposal__c proposalObj : newProposals) {
            Apttus_Proposal__Proposal__c oldProposalObj = (Apttus_Proposal__Proposal__c) oldProposalMap.get(proposalObj.Id);
            ilib_LogEvent.info('oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c --> '+oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c);
            ilib_LogEvent.info('proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c --> '+proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c);
            if(oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c != proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c)
            {
                evaluateLinesForReapprovalProcessing(firstCycleQuotes,nextCycleQuotes,oldProposalObj, proposalObj,newProposalMap);
            }
            
        }
        ilib_LogEvent.info('firstCycleQuotes --> '+firstCycleQuotes);
        ilib_LogEvent.info('nextCycleQuotes --> '+nextCycleQuotes);
        
        if(!firstCycleQuotes.isEmpty()) 
            processLineItemData(firstCycleQuotes, newProposalMap, true);
        
        if(!nextCycleQuotes.isEmpty()) 
            processLineItemData(nextCycleQuotes, newProposalMap, false);
        ilib_LogEvent.pop();
        
        
    }
    
    private static void evaluateLinesForReapprovalProcessing(List<Apttus_Proposal__Proposal__c> firstCycleQuotes,List<Apttus_Proposal__Proposal__c> nextCycleQuotes,Apttus_Proposal__Proposal__c oldProposalObj,Apttus_Proposal__Proposal__c proposalObj,Map<Id,SObject> newProposalMap)
    {
        ilib_LogEvent.push(LOG_TITLE+'.evaluateLinesForReapprovalProcessing()');
        //Cycle 1
        ilib_LogEvent.info('nextCycleQuotes --> '+nextCycleQuotes);
        ilib_LogEvent.info('newProposalMap --> '+newProposalMap);
        if (oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c == null && proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c != null) {
            ilib_LogEvent.info('First cycle');
            firstCycleQuotes.add(proposalObj);
        }
        
        //Cycle 2
        ilib_LogEvent.info('New Apttus_QPConfig__ConfigurationFinalizedDate__c --> '+proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c);
        ilib_LogEvent.info('Old Apttus_QPConfig__ConfigurationFinalizedDate__c --> '+oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c);
        if (oldProposalObj != null && oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c != null 
            && proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c != null 
            && proposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c != oldProposalObj.Apttus_QPConfig__ConfigurationFinalizedDate__c) {
                //Find diff and stamp flag
                ilib_LogEvent.info('next cycle');
                nextCycleQuotes.add(proposalObj);
            }
        
        
        ilib_LogEvent.pop();
    }
    private static void processLineItemData(List<Apttus_Proposal__Proposal__c> quoteList, Map<Id,SObject> newProposalMap, boolean isFirstCycle) {
        ilib_LogEvent.push(LOG_TITLE+'.processLineItemData()');
        ilib_LogEvent.info('isFirstCycle'+isFirstCycle);
        //Set<Id> proposalIds = new Set<Id>();
        //Map<Id, Id> quoteConfigMap = new Map<Id, Id>();
        if (newProposalMap != null && newProposalMap.size() > 0){
            //Change to select by Id
            for (Reapproval_Reference__c reApprovRef:new ReapprovalReferenceSelector().selectByQuoteId(newProposalMap.keySet()) ){
                quoteIdtoReapprovalRefMap.put(reApprovRef.Quote_Proposal_Id__c,reApprovRef);
                System.debug(quoteIdtoReapprovalRefMap);
            }
        }
        
        buildQuoteConfigMap(quoteList,quoteIdtoReapprovalRefMap);
        
        ilib_LogEvent.pop();
    }
    private static void buildQuoteConfigMap(List<Apttus_Proposal__Proposal__c> quoteList,Map<string, Reapproval_Reference__c> quoteIdtoReapprovalRefMap )
    {
        
        ilib_LogEvent.push(LOG_TITLE+'.buildQuoteConfigMap()');
        Set <Id> quoteConfigIdSet = new Set<Id>();
        Set<Id> proposalIds = new Set<Id>();
        Map<Id, Id> quoteConfigMap = new Map<Id, Id>();
        ilib_LogEvent.info('quoteIdtoReapprovalRefMap'+quoteIdtoReapprovalRefMap);
        for (Apttus_Proposal__Proposal__c proposalObj : quoteList) {
            proposalIds.add(proposalObj.Id);
        }
        List <Apttus_Config2__ProductConfiguration__c> configList = selectFinalizedProductConfigurationByQuotIds(proposalIds);
        for(Apttus_Config2__ProductConfiguration__c config : configList) {
            quoteConfigMap.put(config.Apttus_QPConfig__Proposald__c, config.Id);
            quoteConfigIdSet.add(config.id);
        }
        
        
        ilib_LogEvent.info('Quote-Config Map --> '+quoteConfigMap);
        buildConfigLIMap(quoteConfigMap,quoteConfigIdSet,quoteIdtoReapprovalRefMap);
        ilib_LogEvent.pop();
    }
    private static void buildConfigLIMap(Map<Id,Id> quoteConfigMap,Set <Id> quoteConfigIdSet,Map<string, Reapproval_Reference__c> quoteIdtoReapprovalRefMap)
    {
        ilib_LogEvent.push(LOG_TITLE+'.buildConfigLIMap()');
        //-- Construct a Configuration Id to LineItem List map
        Map<Id, List<Apttus_Config2__LineItem__c>> configLIMAP = new Map<Id, List<Apttus_Config2__LineItem__c>>();
        
        for(Apttus_Config2__LineItem__c li : new ApttusLineItemsSelector().selectLineItemsByConfigIds(quoteConfigIdSet)) {
            if(configLIMAP.isEmpty() || (!configLIMAP.isEmpty() && !configLIMAP.containsKey(li.Apttus_Config2__ConfigurationId__c))) 
                configLIMAP.put(li.Apttus_Config2__ConfigurationId__c, new List<Apttus_Config2__LineItem__c>{li});
            else if(!configLIMAP.isEmpty() && configLIMAP.containsKey(li.Apttus_Config2__ConfigurationId__c)) {
                List<Apttus_Config2__LineItem__c> tempList = configLIMAP.get(li.Apttus_Config2__ConfigurationId__c);
                if(tempList != null) {
                    tempList.add(li);
                    configLIMAP.put(li.Apttus_Config2__ConfigurationId__c, tempList);
                }
            }
        }
        ilib_LogEvent.info('configLIMAP --> '+configLIMAP);
        buildDataWrapperList(configLIMAP,quoteConfigMap,quoteIdtoReapprovalRefMap);
        ilib_LogEvent.pop();
        //return updatedQRRs;
    }
    private static void buildDataWrapperList(Map<Id, List<Apttus_Config2__LineItem__c>> configLIMAP,Map<Id, Id> quoteConfigMap,Map<String, Reapproval_Reference__c> quoteIdtoReapprovalRefMap)
        
    {
        ilib_LogEvent.push(LOG_TITLE+'.buildDataWrapperList()');
        List<Reapproval_Reference__c> updatedQRRs = new List<Reapproval_Reference__c>();
        Reapproval_Reference__c qrr = new Reapproval_Reference__c();
        ilib_LogEvent.info('quoteConfigMap'+quoteConfigMap);
        for(string key : quoteConfigMap.keySet()) {
            ilib_LogEvent.info('line 3567'+key);
            ilib_LogEvent.info('line 3568'+quoteConfigMap.get(key));
            if(quoteIdtoReapprovalRefMap.containskey(key) && quoteIdtoReapprovalRefMap.get(key) != null){
                qrr = (Reapproval_Reference__c) quoteIdtoReapprovalRefMap.get(key);
            }
            else{
                qrr.Quote_Proposal_Id__c= key;
            }
            ilib_LogEvent.info('line 3584'+qrr);
            //List<Reapproval_Reference__c> updatedQRRs = new List<Reapproval_Reference__c>();
            List<DataWrapper> wrapperList = new List<DataWrapper>();
            if(!configLIMAP.isEmpty() && quoteConfigMap.get(key) != null && configLIMAP.containsKey(quoteConfigMap.get(key))) {
                for(Apttus_Config2__LineItem__c li : configLIMAP.get(quoteConfigMap.get(key))) {
                    String liNumber = li.Apttus_Config2__LineNumber__c != null ? String.valueOf(li.Apttus_Config2__LineNumber__c) : '';
                    DataWrapper data = new DataWrapper(li.Name, li.Apttus_Config2__Quantity__c, li.Apttus_Config2__Term__c, li.Apttus_Config2__AdjustmentAmount__c, li.Apttus_Config2__ProductId__r.ProductCode, liNumber);
                    wrapperList.add(data);
                }
                String jsonLI = JSON.serialize(wrapperList);    
                ilib_LogEvent.info('JSON --> '+jsonLI);
                ilib_LogEvent.info(qrr.Current_Line_Data__c);
                if (string.isBlank(qrr.Current_Line_Data__c) || (qrr.Current_Line_Data__c != null && qrr.Current_Line_Data__c != jsonLI)){
                    qrr.Current_Line_Data__c = jsonLI;
                    
                }
                updatedQRRs.add(qrr);
                ilib_LogEvent.info('updatedQRRs'+updatedQRRs);
                
            }
            ilib_LogEvent.info('updatedQRRs'+updatedQRRs);
        }
        reapprovalResponseAssignment(quoteConfigMap,quoteIdtoReapprovalRefMap,qrr,updatedQRRs);
        ilib_LogEvent.pop();
    }
    private static void reapprovalResponseAssignment(Map<Id, Id> quoteConfigMap,Map<string, Reapproval_Reference__c> quoteIdtoReapprovalRefMap,Reapproval_Reference__c qrr,List<Reapproval_Reference__c> updatedRRs)
    {
        ilib_LogEvent.push(LOG_TITLE+'.reapprovalResponseAssignment()');
        ilib_LogEvent.info('updatedRRs'+updatedRRs);
        Map<integer,String> salesApprovalLevelMap = new Map<integer,String>();
        Map<integer,String> financeApprovalLevelMap = new Map<integer,String>();
        ilib_LogEvent.info('quoteConfigMap --> '+quoteConfigMap);
        ilib_LogEvent.info('quoteIdtoReapprovalRefMap --> '+quoteIdtoReapprovalRefMap);
        String level= 'Level_';
        //8 should be moved to a label
        for (integer i=2;i<=8;i++) {
            salesApprovalLevelMap.put(i , level+''+i+'_Data_Changed__c');
        }
        for (integer i=2;i<=5;i++) {
            financeApprovalLevelMap.put(i , level+''+i+'_Finance_Data_Changed__c');
        } 
        ilib_LogEvent.info('salesApprovalLevelMap --> '+salesApprovalLevelMap);
        ilib_LogEvent.info('financeApprovalLevelMap --> '+financeApprovalLevelMap);
        ilib_LogEvent.info('qrr --> '+qrr);
        
        Reapproval_Reference__c reapprovalResponse = new Reapproval_Reference__c();
        String levelLineData  = '';
        String financeLevelLineData = '';
        Boolean financeFlag = true;
        for (integer i=2;i<=8;i++)
        {            
            if (qrr != null)
            {
                levelLineData = (String)qrr.get(level+''+i+'_Line_Data__c');
            }
            system.debug('levelLineData'+levelLineData);
            system.debug('qrr.Current_Line_Data__c'+qrr.Current_Line_Data__c);
            String newString = '';
            
            if(qrr.Current_Line_Data__c != null && levelLineData != null) {
                newString = qrr.Current_Line_Data__c;
                FinanceFlag = false;
                buildDataMap(newString,levelLineData,salesApprovalLevelMap,financeApprovalLevelMap,qrr,i,FinanceFlag); 
            }
        }
        for (integer i=2;i<=5;i++)
        {            
            if (qrr != null)
            {
                financeLevelLineData = (String)qrr.get(level+''+i+'_Finance_Line_Data__c');
            }
            ilib_LogEvent.info('levelLineData'+financeLevelLineData);
            String newFinanceString = '';
            if(qrr.Current_Line_Data__c != null && financeLevelLineData != null) {
                newFinanceString = qrr.Current_Line_Data__c;
                FinanceFlag = true;
                buildDataMap(newFinanceString,financeLevelLineData,salesApprovalLevelMap,financeApprovalLevelMap,qrr,i,FinanceFlag); 
            }
        }
        
        
        ilib_LogEvent.info('updatedRRs'+updatedRRs);
        if (!updatedRRs.isEmpty()){
            Database.upsert(updatedRRs);
        }
        ilib_LogEvent.pop();
        
    }
    /* This methods checks the current line data and data for the approval level and creates the map*/
    private static void buildDataMap(string newstring,string levelLineData,Map<integer,String> salesApprovalLevelMap,Map<integer,String> financeApprovalLevelMap,Reapproval_Reference__c qrr,integer i,Boolean financeFlag)
    {
        Map <String, DataWrapper> newstateDataMap= new Map <String,Datawrapper>(); 
        String originalString = levelLineData.unescapeHtml4();
        ilib_LogEvent.info('originalString --> '+originalString);
        ilib_LogEvent.info('newString --> '+newString);
        List <DataWrapper> originalState = (List<DataWrapper>)JSON.deserialize(originalString, List<DataWrapper>.class);
        for (DataWrapper newStateDataWrapper : (List<DataWrapper>)JSON.deserialize(newString, List<DataWrapper>.class))
        {
            newstateDataMap.put (newStateDataWrapper.key,newStateDataWrapper);
        } 
        
        ilib_LogEvent.info('originalState --> '+originalState);
        ilib_LogEvent.info('newstateDataMap --> '+newstateDataMap);
        updateReapprovalResponse(originalState,newstateDataMap,salesApprovalLevelMap,financeApprovalLevelMap,qrr,i,FinanceFlag);
    }
    /*
This method checks if all the data parameter are not equal to the old datawrapper the data is changed
*/
    private static void updateReapprovalResponse(List <DataWrapper> originalstateData,Map <String, DataWrapper> newstateDataMap,Map<integer,String> salesApprovalLevelMap,Map<integer,String> financeApprovalLevelMap,Reapproval_Reference__c qrr,integer i,boolean financeFlag)
    {
        ilib_LogEvent.push(LOG_TITLE+'.updateReapprovalResponse()');
        //Comparision can be done in efficient way using Class Object methods.
        ilib_LogEvent.info('originalState'+originalstateData);
        ilib_LogEvent.info('originalState.size'+originalstateData.size());
        ilib_LogEvent.info('newstateDataMap.values'+newstateDataMap.values());
        ilib_LogEvent.info('newstateDataMap.values.size()'+newstateDataMap.values().size());
        if(!originalstateData.isEmpty() && !newstateDataMap.values().isEmpty()) {
            if(originalstateData.size() != newstateDataMap.values().size()) {
                if (salesApprovalLevelMap.containsKey(i) && FinanceFlag == false){
                    qrr.put(salesApprovalLevelMap.get(i),true);
                }
                if (FinanceApprovalLevelMap.containsKey(i) && FinanceFlag == true){
                    qrr.put(FinanceApprovalLevelMap.get(i),true);
                }
            }
        
            else {
                for (DataWrapper oldDataObj : originalstateData)
                {
                    
                    Datawrapper newDataObj = newstateDataMap.get(oldDataObj.key);
                    ilib_LogEvent.info('newDataObj'+newDataObj);
                    ilib_LogEvent.info('oldDataObj'+oldDataObj);
                    if (newDataObj != null && oldDataObj != null)
                    {
                        if(oldDataObj.key != null && oldDataObj.key.equalsIgnoreCase(newDataObj.key) 
                           &&((oldDataObj.quantity != null && newDataObj.quantity != null && oldDataObj.quantity != newDataObj.quantity)||
                              (oldDataObj.terms != null && newDataObj.terms != null && oldDataObj.terms != newDataObj.terms)||
                              (oldDataObj.totalDiscount != null && newDataObj.totalDiscount != null && oldDataObj.totalDiscount > newDataObj.totalDiscount)
                             )){
                                 if (salesApprovalLevelMap.containsKey(i) && FinanceFlag == false){
                                     qrr.put(salesApprovalLevelMap.get(i),true);
                                     ilib_LogEvent.info('line 277 Sales+'+i);
                                     break;
                                 }
                                 if (FinanceApprovalLevelMap.containsKey(i) && FinanceFlag == true){
                                     qrr.put(FinanceApprovalLevelMap.get(i),true);
                                     ilib_LogEvent.info('line 282 Finance+'+i);
                                     break;
                                 }
                             }else{
                                 if (salesApprovalLevelMap.containsKey(i) && FinanceFlag == false){
                                     qrr.put(salesApprovalLevelMap.get(i),false);
                                     ilib_LogEvent.info('line 288 Sales'+i);
                                 }
                                 if (FinanceApprovalLevelMap.containsKey(i) && FinanceFlag == true){
                                     qrr.put(FinanceApprovalLevelMap.get(i),false);
                                     ilib_LogEvent.info('line 292 Finance'+i);
                                 }
                                 
                             }
                    }
                } 
            }

        
        ilib_LogEvent.pop();
    }
}
    
    /**
* 
*@author Kumar Gaurav
*@description -> Create wrapper for the line item details
*/
    public class DataWrapper {
        Public String lineItem;
        Public Decimal quantity;
        Public Decimal terms;
        Public Decimal totalDiscount;
        Public String key;
        /**
* 
*@author Kumar Gaurav
*@description -> Assigning values to the wrapper
*/
        public DataWrapper(String li, Decimal qty, Decimal term, Decimal discount, String prodCode, String liNumber) {
            this.lineItem = li;
            this.quantity = qty;
            this.terms = term;
            this.totalDiscount = discount;
            this.key = prodCode+'_'+liNumber;
        }
    }
    
    /**
*  @author  Kumar Gaurav
*  @description DCP-31 find the finalized product configuration for Proposal
*  @return List of Product Configuration with Line Item Records
@  @param set of Proposal ids
**/
    private static List<Apttus_Config2__ProductConfiguration__c> selectFinalizedProductConfigurationByQuotIds(Set<Id> setProposalIds)
    {
        ilib_LogEvent.push(LOG_TITLE+'.selectFinalizedProductConfigurationByQuotIds()');
        List <Apttus_Config2__ProductConfiguration__c> prodConfigList = new List <Apttus_Config2__ProductConfiguration__c>([Select id,Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__Status__c =: STATUSFINALIZED AND Apttus_QPConfig__Proposald__c IN: setProposalIds]);
        ilib_LogEvent.pop();
        return prodConfigList;
        //<---End DGP-31--->
    }
    
}