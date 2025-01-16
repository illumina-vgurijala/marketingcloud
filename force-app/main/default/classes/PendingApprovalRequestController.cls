/**
 *    @author Rishab Wali
 *    @date   2020-08-14
 *    @description   DCP-40087 Controller Class for Pending Approval Request Component for Batch Approvals 
 *    Modification Log:
 *   ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Rishab Wali                    2020-08-14          Initial Version
 *    Nishan Shetty                  03-Jun-2022         Implementing Batch Manager Framework DCP-50962
 *    Jitesh Lakhwani                6-July-2022         Code Scan fixes of Comments
 *    ------------------------------------------------------------------------------------                  
 */
public without sharing class PendingApprovalRequestController {
    
    public static final string APPREQSTATUSASSIGNED = 'Assigned';
    public static final string APPREQSTATUSREASSIGNED = 'Reassigned';
    public static final string AGREEMENTOBJNAME = 'Agreement';
    public static final String STRINGBATCHAPPROVALSTATUSINPROGRESS = 'In Progress';
    public static final String BATCHINPROGRESS = 'BatchInProgress';
    public static final String CODEPARAMETERNAME = 'Tableau_Agreement_Metrics_Link';
    public static string taburl = '';
    public static string fieldApiName = 'Approver_Level_';
    public static string fieldApiSuffixName = '__r';

    /**
    *  @description: get all pending approvals in JSON String
    * @param : String objectname
    * @return : String
    **/
    @AuraEnabled
    public static String getPendingApprovals(String objectname)
    {
        try{
            Id idCurrentUser = UserInfo.getUserId();

            BatchApprovalTrackerSelector btchAppSelector = new BatchApprovalTrackerSelector();
            List<Batch_Approval_Tracker__c> lstBatchApprover = btchAppSelector.getBatchApprovals(idCurrentUser,AGREEMENTOBJNAME,new Set<String>{STRINGBATCHAPPROVALSTATUSINPROGRESS});

            if(!lstBatchApprover.isEmpty())
            {
                return JSON.serialize(BATCHINPROGRESS);
            }

            setUrlsFromCodeParam();

            List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = new List<Apttus_Approval__Approval_Request__c>();
            ApttusApprovalRequestsSelector approvalReqSelector = new ApttusApprovalRequestsSelector();
            lstApprovalRequest = approvalReqSelector.getApprovalRequestByLoggedInUser(objectname,idCurrentUser,new Set<String>{APPREQSTATUSASSIGNED,APPREQSTATUSREASSIGNED});
            Set<Id> setAgreementId = new Set<Id>();
            Map<Id,String> aggIdToUserNameMap = new Map<Id,String>();


            for(Apttus_Approval__Approval_Request__c apReq : lstApprovalRequest)
            {
                setAgreementId.add(apReq.Apttus_Approval__Related_Agreement__c);
                String fieldAPI = fieldApiName + String.valueOf(apReq.Apttus_Approval__Related_Agreement__r.Highest_Approver_Level_Discount__c) + fieldApiSuffixName;
                if(apReq.Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__c != null && apReq.Apttus_Approval__Related_Agreement__r.Highest_Approver_Level_Discount__c != null)
                {
                    String highestApproverName = (String) apReq.getsObject('Apttus_Approval__Related_Agreement__r').getsObject('Approval_Hierarchy_Discount__r').getsObject(fieldAPI).get('Name');
                    aggIdToUserNameMap.put(apReq.Apttus_Approval__Related_Agreement__c,highestApproverName);   
                }

            }
                        
            List<DataWrapper> dWrapList = new List<DataWrapper>();
            if(!lstApprovalRequest.isEmpty())
            {
                dWrapList = createWrapper(lstApprovalRequest,aggIdToUserNameMap);
            } 

            if(dWrapList.isEmpty())
            {
                return null;
            }
            return JSON.serialize(dWrapList);
        }
        Catch(Exception e)
        {
            System.debug('Error -- ' + e.getLineNumber() + ' -- ' + e.getMessage());
            return System.label.UI_Error_Message_Recall_Agreement;
        }
    }

    /**
    *  @description: This will create an record in Batch Approval Tracker and execute batch which will approve OR reject the approvals.
    * @param : String dataList , String approveOrReject
    * @return : Boolean
    **/
    @AuraEnabled
    public static boolean getRequestForApproveReject(String dataList , String approveOrReject)
    {
        try{
        Map<Id,String> appRequestIdToCommentsMap = new Map<Id,String>();
        List<DataWrapper> dataResp = (List<DataWrapper>)JSON.deserialize(dataList,List<DataWrapper>.class);
        System.debug('data --- ' + dataResp);
        for(DataWrapper dw : dataResp)
        {
            if(dw.comments == null)
            {
                dw.comments = '';
            }
            appRequestIdToCommentsMap.put(dw.appReqId,dw.comments);
        }

        Batch_Approval_Tracker__c objBatchApproval = new Batch_Approval_Tracker__c();
        objBatchApproval.Approval_Related_To__c = AGREEMENTOBJNAME;
        objBatchApproval.Submitted_At__c = DateTime.Now();
        objBatchApproval.Submitted_By__c = UserInfo.getUserId();
        objBatchApproval.Total_Number_of_Records_Requested__c = dataResp.size();
        objBatchApproval.Status__c = STRINGBATCHAPPROVALSTATUSINPROGRESS;
        objBatchApproval.Process_Type__c = approveOrReject;
        insert objBatchApproval;
        BatchApprovalRequests btchAppReq = new BatchApprovalRequests(appRequestIdToCommentsMap,approveOrReject,objBatchApproval.Id);
        //START DCP-50962
        ilib_BatchManager.executeBatch(btchAppReq,1);
        //END DCP-50962
        return true;
    }
    Catch(Exception e)
    {
       System.debug('Error -- ' + e.getLineNumber() + ' -- ' + e.getMessage());
       return false;   
    }
    }
    
    /*Set Tab Urls from Code Param MDT*/
    public static void setUrlsFromCodeParam()
    {
        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
        List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
        String codeParamValue = objCodeParam[0].Value__c;
        List<String> lstURL = new List<String>();
        if(!String.isBlank(codeParamValue) && codeParamValue.contains(';'))
        {
            lstUrl = codeParamValue.split(';');
        }
        if(!lstUrl.isEmpty())
        {
            taburl = Organizations.isProduction() ? lstUrl[1] : lstUrl[0];
        }
    }

    /*Creates Wrapper Data */
    public static List<DataWrapper> createWrapper(List<Apttus_Approval__Approval_Request__c> lstApprovalRequest,Map<Id,String> aggIdToUserNameMap)
    {
        String baseUrl = String.valueOf(URL.getSalesforceBaseUrl().toExternalForm());
        List<DataWrapper> dWrapList = new List<DataWrapper>();

        for(Apttus_Approval__Approval_Request__c appReq : lstApprovalRequest)
        {
            DataWrapper dwrap = new DataWrapper();
            dwrap.isChecked = false;
            dwrap.appReqId = appReq.Id;
            dwrap.agreementName = appReq.Apttus_Approval__Related_Agreement__r.Name;
            dwrap.agreementUrl = baseurl + '/' + appReq.Apttus_Approval__Related_Agreement__c;                
            dwrap.agreementRecordTypeName = appReq.Apttus_Approval__Related_Agreement__r.RecordType.Name;
            dwrap.accountName = appReq.Apttus_Approval__Related_Agreement__r.Apttus__Account__r.Name;
            dwrap.agreementMetricsLink = taburl + appReq.Apttus_Approval__Related_Agreement__c;
            dwrap.agreementNumber = appReq.Apttus_Approval__Related_Agreement__r.Apttus__FF_Agreement_Number__c;
            dwrap.requestName = appReq.Name;
            dwrap.requestUrl = baseurl + '/' + appReq.Id;
            dwrap.justification = appReq.Apttus_Approval__Related_Agreement__r.Discount_Justification__c;
            dwrap.comments = appReq.Apttus_Approval__Approver_Comments__c;
            if(appReq.Apttus_Approval__Related_Agreement__r.Highest_Discount_Requested__c != null)
            {
                dwrap.highestDiscount = String.valueOf(appReq.Apttus_Approval__Related_Agreement__r.Highest_Discount_Requested__c) + ' %'; 
            }
            if(appReq.Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__c != null && aggIdToUserNameMap.containsKey(appReq.Apttus_Approval__Related_Agreement__c))
            {
                dwrap.highestApproverRequired = aggIdToUserNameMap.get(appReq.Apttus_Approval__Related_Agreement__c);
                System.debug('Approver %^%^% ' + dwrap.highestApproverRequired);
            }
            dWrapList.add(dwrap);
        }
        System.debug('Wrapper ---- ' + dWrapList);
        return dWrapList;
    }

    /*Wrapper Class*/
    public class DataWrapper
    {
        @AuraEnabled public boolean isChecked;
        @AuraEnabled public String appReqId;   
        @AuraEnabled public String agreementName;
        @AuraEnabled public String agreementUrl;
        @AuraEnabled public String agreementRecordTypeName;
        @AuraEnabled public String agreementNumber;   
        @AuraEnabled public String accountName;
        @AuraEnabled public String agreementMetricsLink;
        @AuraEnabled public String requestName;   
        @AuraEnabled public String requestUrl;
        @AuraEnabled public String justification;   
        @AuraEnabled public String comments;
        @AuraEnabled public String highestDiscount;
        @AuraEnabled public String highestApproverRequired = '';
    }
}