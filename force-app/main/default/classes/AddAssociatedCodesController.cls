/**
*    @author Naomi Thammadi
*    @date   14-05-2019
*    @description    Class used to get information for the Lightning component - AddAssociatedCodes
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*      Developer                      Date                Description
*     NAOMI THAMMADI                 14-May-2018         Initial Version
*     Kushagra Desai                 11-May-2020         DCP-37793 : Hazard code addition.
*     Kushagra Desai                 10-Aug-2020         INC0282548 : Hypercare update to determine QA User
*     Shivani                        24-Aug-2021         DCP-47684 - Add Visibility of Code Types on Case/Work Order
*     Preetha                        09-Mar-2022         QACM-51 - Add Sub_Type__c based codes search in getSearchCodeList method
*     Vinay S Reddy                  20-Sep-2023         CMCM-1653- Add logic for making analysis code not mandatory for case category Logistics/Supply Chain
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class AddAssociatedCodesController {
    public static List<Associated_Codes__c> lAssociatedCodes=new List<Associated_Codes__c>();
    public static List<Code_Library__c> lCodeLibrary=new List<Code_Library__c>();
    //DCP-47684
    public static Map<String, Boolean> codesValidationMap = new Map<String, Boolean>();
    static final String PRODUCTTYPE_INSTRUMENT = 'Instrument';
    static final String REGULATORYTYPE_DX = 'DX';
    static final String REGULATORYTYPE_IUO = 'IUO';
    static final String REGULATORYTYPE_EUA = 'EUA';
    static final String SUBTYPE_ORDER = 'Order';
    static final String SUBTYPE_GENERAL = 'General';
    static final String QAREVIEW_NONIVDPRODUCT = 'Non IVD Product';
    static final String STRING_NO = 'No';
    static final String OBJECT_WORKORDER = 'SVMXC__Service_Order__c';
    static final String OBJECT_CASE = 'Case';
    //QACM-51
    public static boolean isCaseType    = false;
    public static boolean isCaseSubType = false;

    /**
*  @author  Naomi Thammadi
*  @description get all associated codes on the case or work order 
*  @return json of WrapObject
**/
    
    @AuraEnabled
    public static string getAssociatedCodes(Id strRecordId, String strFieldName, String strSortOrder){
        try{
            Set<id> setCaseIds=new set<id>();
            lAssociatedCodes=new List<Associated_Codes__c>();
            Schema.SObjectType sobjectType = strRecordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            Boolean bIsElevation = false;
            Boolean bLockCodes = false;
            
            //set default sorting
            if(strFieldName==null)
                strFieldName='Code_ID__c';
            if(strSortOrder==null)
                strSortOrder='ASC';
            
            //check if case is elevation
            if(sobjectName == OBJECT_CASE){
                List<Case> lstCase=new CasesSelector().selectCasesFromSetIds(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                if(!lstCase.isEmpty()){
                    if(lstCase[0].RecordType.Name=='Elevation') bIsElevation=true;
                    if(lstCase[0].Status==System.Label.CaseStatusCompleted || lstCase[0].Status==System.Label.CaseStatusClosed || lstCase[0].Status == 'Closed-Duplicate' ) bLockCodes=true;
                }
            }
            //get the case associated to the work order if action is performed from work order record
            else if(sobjectName == OBJECT_WORKORDER){
                List<SVMXC__Service_Order__c> lstWorkOrders=new WorkOrdersSelector().selectWorkOrderAndCaseInfo(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                if(!lstWorkOrders.isEmpty()){
                    if(lstWorkOrders[0].SVMXC__Case__c!=null) setCaseIds.add(lstWorkOrders[0].SVMXC__Case__c);
                    if(lstWorkOrders[0].SVMXC__Order_Status__c=='Completed' || lstWorkOrders[0].SVMXC__Order_Status__c=='Closed'|| lstWorkOrders[0].SVMXC__Order_Status__c=='Canceled') bLockCodes=true;
                }
            }
            system.debug('strFieldName: '+ strFieldName +' strSortOrder: '+strSortOrder);        
            //Query associated codes related to case or work order
            if(sobjectName == OBJECT_CASE){
                lAssociatedCodes = new AssociatedCodeSelector().selectActiveAssociatedCodesOnCase(new set<Id>{String.escapeSingleQuotes(strRecordId)}, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));
            }
            else if(sobjectName == OBJECT_WORKORDER){
                lAssociatedCodes=new AssociatedCodeSelector().selectActiveAssociatedCodesOnWOs(new set<Id>{String.escapeSingleQuotes(strRecordId)}, setCaseIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));
            }
            
            //get Search Radio button options
            Schema.DescribeFieldResult codeLibResult =Code_Library__c.Code_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = codeLibResult.getPicklistValues();
            
            system.debug('lAssociatedCodes: '+lAssociatedCodes);
            //instantiate the object
            WrapObject objWrapObject = new WrapObject();
            objWrapObject.lstAssociatedCodes = lAssociatedCodes;
            objWrapObject.bIsElevation=bIsElevation;
            objWrapObject.bLockCodes=bLockCodes;
            
            objWrapObject.lSearchOptions=new List<String>();
            // DCP-37793 : Hazard code addition.
            // INC0282548
			//bypass of field done by Shruti Karn for INC0296133
			ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
            if(UserInfo.getUserType() == Label.UserTypeStandard && Profiles.getQualityAssuranceProfileId().contains(userinfo.getProfileId()))
                objWrapObject.boolQAUser = true;
            else
                objWrapObject.boolQAUser = false;
            if(UserInfo.getUserType() == Label.UserTypeStandard && Profiles.getFieldServicelogisticsProfileId().contains(userinfo.getProfileId()))
                objWrapObject.boolLogisticsUser = true;            
            else
                objWrapObject.boolLogisticsUser = false;
           
            if(objWrapObject.boolQAUser && (OBJECT_CASE.equals(sobjectName) || (OBJECT_WORKORDER.equals(sobjectName)))){
                objWrapObject.lSearchOptions.add(Label.CodeLibraryCodeTypeHazard);
            }
             else if(objWrapObject.boolLogisticsUser && (OBJECT_CASE.equals(sobjectName) || (OBJECT_WORKORDER.equals(sobjectName)))){
                objWrapObject.lSearchOptions.add(Label.CodeLibraryCodeTypeLogisticsReviewCode);
             }

            else{
                objWrapObject.lSearchOptions.add('All');
                for( Schema.PicklistEntry f : ple)
                {
                    if(f.getLabel() != Label.CodeLibraryCodeTypeHazard)                       
                     if(f.getLabel() != Label.CodeLibraryCodeTypeLogisticsReviewCode)                         
                        objWrapObject.lSearchOptions.add(f.getLabel());
                    
                }
                if(UserInfo.getUserType() == Label.UserTypeStandard && Profiles.getSuperUserProfileId().contains(userinfo.getProfileId()) && (OBJECT_CASE.equals(sobjectName) || (OBJECT_WORKORDER.equals(sobjectName)))){
                    objWrapObject.lSearchOptions.add(Label.CodeLibraryCodeTypeHazard);
                        //DCP-43515
                    objWrapObject.lSearchOptions.add(Label.CodeLibraryCodeTypeLogisticsReviewCode);

                }  
            }
             
            
			ilib_SecurityUtils.bypassInternalFlsAndCrud = false;
            system.debug('objWrapObject.lSearchOptions '+objWrapObject.lSearchOptions);
            //DCP-37793 : Hazard code
            objWrapObject.mapLabels = new Map<String,String>{
                'AssociatedCodeTypeHazard' =>Label.AssociatedCodeTypeHazard,
                'CodeLibraryCodeTypeHazard' => Label.CodeLibraryCodeTypeHazard,
                'CodeLibraryCodeTypeLogistics' => Label.CodeLibraryCodeTypeLogisticsReviewCode,
                'UI_Error_Message_No_Code_Addition' => Label.UI_Error_Message_No_Code_Addition,
                'UI_Error_Message_No_Code_Found' => Label.UI_Error_Message_No_Code_Found,
                'UI_Error_Message_No_Active_Code' =>Label.UI_Error_Message_No_Active_Code,
                'UI_Search' => Label.UI_Search,
                'UI_Error_Message_System_Error' => Label.UI_Error_Message_System_Error,
                'UI_Error_Message_Restrict_Parent' => Label.UI_Error_Message_Restrict_Parent,
                'UI_Error_Message_Restrict_Non_Hazard' => Label.UI_Error_Message_Restrict_Non_Hazard
                

            };
            //create JSON
            return JSON.serialize(objWrapObject);
        }
        catch(Exception ee){
            throw new AuraHandledException('ERROR :  '+ ee.getMessage());   
        }
    }
    
    /**
*  @author  Naomi Thammadi
*  @description get all searched code libraries 
*  @return json of WrapObject
**/
    
    @AuraEnabled
    public static string getSearchCodeList(string codeTitle, string strCodeType, Id strRecordId, String strFieldName, String strSortOrder){
        try{
            Schema.SObjectType sobjectType = strRecordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            String strCaseType='';
            Set<id> setCaseIds=new set<id>();
            Set<Id> existingCodeLibIds=new Set<Id>();
            Boolean bLockCodes = false;
            //QACM-51 starts
            String strCaseSubType='';
            //Boolean checkCaseSubType = false;
            //Boolean checkCaseType = false;
            //QACM-51 ends
            
            //set default sorting
            if(strFieldName==null)
                strFieldName='Code_ID__c';
            if(strSortOrder==null)
                strSortOrder='ASC';
            if(codeTitle==null)
                codeTitle='';
            
            //Query for Case record type for correct search results
            if(sobjectName == OBJECT_CASE){
                List<Case> lstCases=new CasesSelector().selectCasesFromSetIds(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                if(!lstCases.isEmpty()){
                    strCaseType=lstCases[0].RecordType.Name;
                    strCaseSubType=lstCases[0].Sub_type__c;
                    if(lstCases[0].Status==System.Label.CaseStatusCompleted || lstCases[0].Status==System.Label.CaseStatusClosed || lstCases[0].Status == 'Closed-Duplicate' ) bLockCodes=true;
                }
            }
            else if(sobjectName == OBJECT_WORKORDER){
                List<SVMXC__Service_Order__c> lstWorkOrders=new WorkOrdersSelector().selectWorkOrderAndCaseInfo(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                if(!lstWorkOrders.isEmpty()){
                    if(lstWorkOrders[0].SVMXC__Case__c!=null){
                        strCaseType=lstWorkOrders[0].SVMXC__Case__r.RecordType.Name;
                        strCaseSubType = lstWorkOrders[0].SVMXC__Case__r.Sub_Type__c;//QACM-51
                        setCaseIds.add(lstWorkOrders[0].SVMXC__Case__c);
                    }
                    if(lstWorkOrders[0].SVMXC__Order_Status__c=='Completed' || lstWorkOrders[0].SVMXC__Order_Status__c=='Closed'|| lstWorkOrders[0].SVMXC__Order_Status__c=='Canceled') bLockCodes=true;
                }
            }
            
            system.debug('strFieldName: '+ strFieldName +' strSortOrder: '+strSortOrder+ ' strCaseType: '+strCaseType);
            //Query associated codes related to case or work order to exclude those code libraries from the search results
            if(sobjectName == OBJECT_CASE){
                for(Associated_Codes__c objAsCode: new AssociatedCodeSelector().selectActiveAssociatedCodesOnCase(new set<Id>{String.escapeSingleQuotes(strRecordId)}, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder))){
                    existingCodeLibIds.add(objAsCode.Code_Title__c);
                }
            }
            else if(sobjectName == OBJECT_WORKORDER){
                for(Associated_Codes__c objAsCode: new AssociatedCodeSelector().selectActiveAssociatedCodesOnWOs(new set<Id>{String.escapeSingleQuotes(strRecordId)}, setCaseIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder))){
                    existingCodeLibIds.add(objAsCode.Code_Title__c);
                }
            }
            
            system.debug('in getcodes - '+codeTitle + '   '+strCodeType);
            //Query Code library records with the given search string and other conditions
            lCodeLibrary=new List<Code_Library__c>();
            if(strCodeType == 'All' || strCodeType==null) {
                for(Code_Library__c objCodeLib: new CodeLibrarySelector().selectCodeLibraryBySimilarTitle(String.escapeSingleQuotes(codeTitle), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder))) {
                    //QACM-51 Starts 
                    if((objCodeLib.Code_Type__c == 'Subject' || objCodeLib.Code_Type__c == 'Analysis' || objCodeLib.Code_Type__c == 'Resolution') && checkCaseType(strCaseType,objCodeLib.Case_Type__c) == true) {
                        if(checkCaseSubType(strCaseType,strCaseSubType,objCodeLib) == true) {
							lCodeLibrary.add(objCodeLib);
                        }else if(string.isBlank(strCaseSubType)) {
                        	lCodeLibrary.add(objCodeLib);    
                        }
                    }else if(objCodeLib.Code_Type__c == 'Verification' || objCodeLib.Code_Type__c == 'Product') {
                        lCodeLibrary.add(objCodeLib);
                    }
                    isCaseType    = false;
                    isCaseSubType = false;
                }
            }
            //get thec odes for Case type and assoiciated subtype based code type
            else if((strCodeType == 'Subject' || strCodeType == 'Analysis' || strCodeType == 'Resolution')&& string.isNotBlank(strCaseType)) {
                if(string.isNotBlank(strCaseSubType)) {
                	lCodeLibrary=new CodeLibrarySelector().selectCodeLibrByCodeTypeAndSubType(String.escapeSingleQuotes(codeTitle),String.escapeSingleQuotes(strCodeType),String.escapeSingleQuotes(strCaseType),String.escapeSingleQuotes(strCaseSubType), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));
                }else if(string.isBlank(strCaseSubType)) {
                	lCodeLibrary=new CodeLibrarySelector().selectCodeLibrByTitleCodeTypeCaseType(String.escapeSingleQuotes(codeTitle),String.escapeSingleQuotes(strCodeType),String.escapeSingleQuotes(strCaseType), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));   
                }
        	}
            //QACM-51 ends
            else if(strCodeType=='Verification' || strCodeType=='Product'){
                lCodeLibrary=new CodeLibrarySelector().selectCodeLibrBySimilarTitleAndType(String.escapeSingleQuotes(codeTitle),String.escapeSingleQuotes(strCodeType), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));
            }
            // DCP-37793 : Hazard code addition
            else if(Label.CodeLibraryCodeTypeHazard.equals(strCodeType)){
                lCodeLibrary=new CodeLibrarySelector().selectCodeLibrByHazard(String.escapeSingleQuotes(codeTitle),String.escapeSingleQuotes(strCodeType),String.escapeSingleQuotes(strCaseType), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));           
            system.debug('lCodeLibrary: '+lCodeLibrary);
            }
            
            /**********************************/
            // DCP-43515 : Logistics Review Code
            // Deepika
            else if(Label.CodeLibraryCodeTypeLogisticsReviewCode.equals(strCodeType)){
                lCodeLibrary=new CodeLibrarySelector().selectCodeLibrByLogisticsReviewCode(String.escapeSingleQuotes(codeTitle),String.escapeSingleQuotes(strCodeType),String.escapeSingleQuotes(strCaseType), existingCodeLibIds, String.escapeSingleQuotes(strFieldName), String.escapeSingleQuotes(strSortOrder));
            system.debug('lCodeLibrary: '+lCodeLibrary);
            }
            //instantiate the object
            WrapObject objWrapObject = new WrapObject();
            objWrapObject.lstCodeLibrary = lCodeLibrary;
            objWrapObject.bLockCodes=bLockCodes;         
            
          
            /**************************************/
            
            //create JSON
            return JSON.serialize(objWrapObject); 
        }
        catch(Exception ee){
            throw new AuraHandledException('ERROR : '+ ee.getMessage());   
        }
    }
    
    /**
*  @author  Naomi Thammadi
*  @description add the selected code library as an associated code on the case or work order
*  @return json of list of WrapObject
**/
    
    @AuraEnabled
    public static string addAssociatedCodes(Id strRecordId, string strCodeId){
        try{
            system.debug('here in add assocodes Code=>'+strCodeId+' record=>'+strRecordId);
            Id caseId=null;
            Id workOrderId=null;
            lCodeLibrary=new List<Code_Library__c>();
            Schema.SObjectType sobjectType = strRecordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            //get the selected code library record
            lCodeLibrary=new CodeLibrarySelector().selectCodeLibraryByIds(new Set<id>{strCodeId});
            
            //get the case and work order id to assign them on the associated code
            if(sobjectName == OBJECT_CASE){
                List<Case> lstCases=new CasesSelector().selectCasesFromSetIds(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                //START Modified DCP-47684
                if(!lstCases.isEmpty()) {
                    caseId=lstCases[0].id;

                    set<Id> caseIdSet = new Set<Id>();
                    caseIdSet.add(caseId);

                    List<SVMXC__Service_Order__c> workOrderList = new WorkOrdersSelector().selectWorkOrderIdOnCase(caseIdSet);
                    
                    if(workOrderList.size() > 0){
                        workOrderId = workOrderList[0].Id;
                    }
                    
                }
                //END Modified DCP-47684
            }
            else if(sobjectName == OBJECT_WORKORDER){
                List<SVMXC__Service_Order__c> lstWorkOrders=new WorkOrdersSelector().selectWorkOrderAndCaseInfo(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                workOrderId=lstWorkOrders[0].id;
                if(!lstWorkOrders.isEmpty() && lstWorkOrders[0].SVMXC__Case__c!=null){
                    caseId=lstWorkOrders[0].SVMXC__Case__c;
                }
            }
            Associated_Codes__c objNewACode;
            List<Associated_Codes__c> lstACodesToInsert=new List<Associated_Codes__c>();
            if(strCodeId!=null && strRecordId!=null && lCodeLibrary!=null && lCodeLibrary[0]!=null){
                //add the associated code
                objNewACode=new Associated_Codes__c();
                objNewACode.Case_Type__c  = lCodeLibrary[0].Case_Type__c ;
                objNewACode.Case__c=caseId;
                objNewACode.Work_Order__c=workOrderId;
                objNewACode.Code_Description__c = lCodeLibrary[0].Code_Description__c  ;
                objNewACode.Code_Title__c  = lCodeLibrary[0].Id ;
                objNewACode.Code_Type__c   = lCodeLibrary[0].Code_Type__c  ;
                objNewACode.Parent_Code__c  = lCodeLibrary[0].Parent_Code__c  ;
                lstACodesToInsert.add(objNewACode);
                //add the parent code also if the selected code has a parent code associated
                if(objNewACode.Parent_Code__c!=null){
                    objNewACode=new Associated_Codes__c();
                    objNewACode.Case_Type__c  = lCodeLibrary[0].Parent_Code__r.Case_Type__c ;
                    objNewACode.Case__c=caseId;
                    objNewACode.Work_Order__c=workOrderId;
                    objNewACode.Code_Description__c = lCodeLibrary[0].Parent_Code__r.Code_Description__c  ;
                    objNewACode.Code_Title__c  = lCodeLibrary[0].Parent_Code__c ;
                    objNewACode.Code_Type__c   = lCodeLibrary[0].Parent_Code__r.Code_Type__c  ;
                    objNewACode.Parent_Code__c  = lCodeLibrary[0].Parent_Code__r.Parent_Code__c  ;
                    lstACodesToInsert.add(objNewACode);
                }
                insert lstACodesToInsert;
            }
            
            return getAssociatedCodes(strRecordId,null,null); 
        }
        catch(Exception ee){
            system.debug('Error : '+ee.getMessage()+'   ' +ee.getLineNumber());
            throw new AuraHandledException('Error : '+ ee.getMessage());   
        }
    }
    
    /**
*  @author  Naomi Thammadi
*  @description disassociate the selected associated code on the case or work order
*  @return json of list of WrapObject
**/
    
    @AuraEnabled
    public static string removeAssociatedCodes(Id strRecordId, Id strCodeId){
        try{
            system.debug('here in remove assocodes Code=>'+strCodeId+ ' on record=>'+strRecordId);
            lAssociatedCodes=new List<Associated_Codes__c>();
            Schema.SObjectType sobjectType = strRecordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            
            //get the selected associated code to disassociate
            lAssociatedCodes = new AssociatedCodeSelector().selectAssociatedCodes(new Set<Id>{strCodeId});
            //get the code disassociated code library record
            List<Code_Library__c> lstDisassociatedCode=new CodeLibrarySelector().selectDisassocaiatedCodeLibrary();
            system.debug('lstDisassociatedCode: '+lstDisassociatedCode);
            
            if(!lAssociatedCodes.isEmpty() && !lstDisassociatedCode.isEmpty()){
                //if the selected associated code has parent code, then get that associated code record on the case or work order
                if(lAssociatedCodes[0].Parent_Code__c!=null){
                    if(sobjectName == OBJECT_CASE){
                        lAssociatedCodes.addAll(new AssociatedCodeSelector().selectAssociatedCodesOnCase(strRecordId, lAssociatedCodes[0].Parent_Code__c) );
                    }
                    else if(sobjectName == OBJECT_WORKORDER){
                        lAssociatedCodes.addAll(new AssociatedCodeSelector().selectAssociatedCodesOnWO(strRecordId, lAssociatedCodes[0].Parent_Code__c) );
                    }
                }
                system.debug('lAssociatedCodes: '+lAssociatedCodes);
                
                //change the code title to Code Disassociated
                for(Associated_Codes__c objRemoveACode: lAssociatedCodes){
                    objRemoveACode.Code_Title__c=lstDisassociatedCode[0].id;
                }
                update lAssociatedCodes;
            }
            
            //create JSON
            return getAssociatedCodes(strRecordId,null,null);
        }
        catch(Exception ee){
            throw new AuraHandledException('ERROR : '+ ee.getMessage());   
        }
    }
    
    /**
*  @author  Naomi Thammadi
*  @description Wrapper class used on the lightning component to display data correctly
**/
    public class WrapObject{
        @AuraEnabled
        public List<Associated_Codes__c> lstAssociatedCodes;
        @AuraEnabled
        public List<Code_Library__c> lstCodeLibrary;
        @AuraEnabled
        public List<String> lSearchOptions;
        @AuraEnabled
        public Associated_Codes__c objInsertedCode;
        @AuraEnabled
        public Associated_Codes__c objDeletedCode;
        @AuraEnabled
        public String CodeName;
        @AuraEnabled
        public String CodeId;
        @AuraEnabled
        public String parentCodeName;
        @AuraEnabled
        public Boolean bIsElevation;
        @AuraEnabled
        public Boolean bLockCodes;
        @AuraEnabled
        public Boolean boolQAUser;
        @AuraEnabled
        public Boolean boolLogisticsUser;
        @AuraEnabled
        public Map<String,String> mapLabels;
    }
    
    /*******************************************************************************************************
    * @description DCP-47684 Check for Validations on Work Order for Associated Codes for Highlighting
    * @param workOrder SVMXC__Service_Order__c record
    * @param cRec Case record
    * @return
    * @example
    */
    private static void workOrderValidations(SVMXC__Service_Order__c workOrder, Case cRec) {
        Set<String> orderTypesToCheck = new Set<String> {Label.WorkOrderTypeProfessionalServices, Label.WorkOrderTypePreventativeMaintenance, 
                        Label.WorkOrderTypeInstallation, Label.WorkOrderTypeRelocation, Label.WorkOrderTypeTradeinEOL};
        
        //CheckCaseAssociatedToWO Validation Rule
        if(cRec != NULL && Label.CaseRecordTypeBusinessIssue.equals(cRec.RecordType.Name) 
            && String.isBlank(workOrder.Abandoned_Reason__c) 
            && new Set<String>{Label.CaseSubTypeComplaint, Label.CaseSubTypeGeneralIssue}.contains(cRec.Sub_Type__c)) {
            if(cRec.Category__c!=Label.CaseCategoryLogistics) {
                if(!cRec.Has_Analysis_Code__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeAnalysis, true);
                }
            }
            if(!cRec.Has_Resolution_Code__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeResolution, true);
            }
        }

        //CheckVerificationCodeOnWO Validation Rule
        if((orderTypesToCheck.contains(workOrder.SVMXC__Order_Type__c) 
            || (cRec != NULL && Label.WorkOrderTypeServiceActivities.equals(workOrder.SVMXC__Order_Type__c) 
                && Label.CaseRecordTypeBusinessIssue.equals(cRec.RecordType.Name) 
                && Label.CaseSubTypeComplaint.equals(cRec.Sub_Type__c))
            ) 
            && new Set<String>{Label.WorkOrderRecordTypeServiceSupport, Label.WorkOrderRecordTypeFieldService}.contains(workOrder.Record_Type__c)
            && workOrder.SVMXC__Product__c != null && PRODUCTTYPE_INSTRUMENT.equals(workOrder.SVMXC__Product__r.Service_Product_Type__c)
            && workOrder.SVMXC__Product__r.Regulatory_Type__c != NULL 
            && (workOrder.SVMXC__Product__r.Regulatory_Type__c.contains(REGULATORYTYPE_DX)
                || workOrder.SVMXC__Product__r.Regulatory_Type__c.contains(REGULATORYTYPE_EUA)
                || REGULATORYTYPE_IUO.equals(workOrder.SVMXC__Product__r.Regulatory_Type__c))
            && !workOrder.Has_Verification_Code__c) {
            codesValidationMap.put(Label.AssociatedCodeTypeVerification, true);
        }
    }

    /*******************************************************************************************************
    * @description DCP-47684 Check for Validations on Case for Associated Codes for Highlighting
    * @param cRec Case record
    * @return
    * @example
    */
    private static void caseValidations(Case cRec) {
        //CheckCaseTypeInquiry, CheckCaseTypeServiceRequest, CheckCodeOnComplaintToCompleteCase & CheckHazardCodePresent Validation Rule
        if(Label.CaseRecordTypeInquiry.equals(cRec.RecordType.Name)) {
            if(!new Set<String>{SUBTYPE_ORDER, SUBTYPE_GENERAL}.contains(cRec.Sub_Type__c) && !cRec.Has_Inquiry_Case_Subject_Code__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeSubject, true);
            }
        } else if(Label.CaseRecordTypeServiceRequest.equals(cRec.RecordType.Name)) {
            if(!cRec.Has_SR_Case_Subject_Code__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeSubject, true);
            }
        } else if(Label.CaseRecordTypeBusinessIssue.equals(cRec.RecordType.Name)) {
            if(!cRec.Has_BI_Case_Subject_Code__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeSubject, true);
            }
            if(!(QAREVIEW_NONIVDPRODUCT.equals(cRec.QA_Review__c) && STRING_NO.equals(cRec.PAE_PFA_Evaluation_Required__c)) 
                && Label.CaseStatusPendingQAReview.equals(cRec.Status) && !cRec.HasHazardCode__c) {
                codesValidationMap.put(Label.AssociatedCodeTypeHazard, true);
            }
        } 
    }

    /*******************************************************************************************************
    * @description DCP-47684 Check for Validations on Work Order/Case for Associated Codes for Highlighting
    * @param strRecordId id of the record where Associated Codes tab is opened
    * @return Map for Associated Codes
    * @example
    */
    @AuraEnabled
    public static string getValidationsMap(Id strRecordId) {
        try {
            Schema.SObjectType sobjectType = strRecordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();

            if(OBJECT_WORKORDER.equalsIgnoreCase(sobjectName)) {
                List<SVMXC__Service_Order__c> lstWorkOrders=new WorkOrdersSelector().selectWorkOrders(new set<Id>{String.escapeSingleQuotes(strRecordId)});
                
                if(lstWorkOrders != NULL && !lstWorkOrders.isEmpty()) {
                    Case cRec = lstWorkOrders[0].SVMXC__Case__r;
                    workOrderValidations(lstWorkOrders[0], cRec);
                    if(lstWorkOrders[0].SVMXC__Case__c != NULL) {
                        caseValidations(cRec); 
                    }
                }
            } else if (OBJECT_CASE.equalsIgnoreCase(sobjectName)) {
                List<Case> lstCases=new CasesSelector().selectCases(new set<Id>{String.escapeSingleQuotes(strRecordId)});

                if(lstCases != NULL && !lstCases.isEmpty()) {
                    if(lstCases[0].Work_Order__c != NULL) {
                        SVMXC__Service_Order__c workOrder = lstCases[0].Work_Order__r;
                        workOrderValidations(workOrder, lstCases[0]);
                    }
                    caseValidations(lstCases[0]);
                }
            }
            return JSON.serialize(codesValidationMap);
        } catch(Exception eMsg) {
            throw new AuraHandledException(Label.Error + ' : '+ eMsg.getMessage());   
        } 
    }

    /*******************************************************************************************************
    * @description QACM-51 Check for case type
    * @param caseRecordType,caseType
    * @return boolean
    */
    private static Boolean checkCaseType(String caseRecordType,String caseType){
        if(string.isNotBlank(caseRecordType) && string.isNotBlank(caseType) && caseRecordType == caseType){
            isCaseType = true;
        }
        return isCaseType;
    }

    /*******************************************************************************************************
    * @description QACM-51 Check for case subtype
    * @param caseType,caseSubType,subType
    * @return boolean
    */
    private static Boolean checkCaseSubType(String caseType,String caseSubType,Code_Library__c code){
        if(string.isNotBlank(caseType) && string.isNotBlank(code.Case_Type__c) && caseType == code.Case_Type__c){
            if((string.isNotBlank(caseSubType) && string.isNotBlank(code.Case_Sub_Type__c) && code.Case_Sub_Type__c.contains(caseSubType)) || string.isBlank(code.Case_Sub_Type__c)){
                isCaseSubType = true;
            }
        }
        return isCaseSubType;
    }
}