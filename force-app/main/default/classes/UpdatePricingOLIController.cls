/**
*    @author Rishab
*    @date   2021-June-03
*    @description    DCP-46927: Quote Optimization (Add Products to Opportunity Controller Test Class)
*    @Test Class  -  TestUpdatePricingOLIController
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                        03-06-2021          Initial Version
*         Prem Ranjan                   09-06-2021          DCP-47880 AC6 Pouplate Customer Specific Price and List Price from SAP
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class UpdatePricingOLIController {

    public static final string STR_BLANK = 'Blank'; 
    public static final string STRSUCCESS = 'success';
    public static final string STRERROR = 'error';
    public static final string EXCEPTION_LOG_NAME = 'UpdatePricingOLIController';
    public static List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();
    public static final Integer INTEGERVALUE2 = 2;
    public static string exceptionMessage = '*#';  

    /* Method to check record access */
    @AuraEnabled
    public static string checkRecordAccess(Id oppId){
        try {
            ilib_LogEvent.push(EXCEPTION_LOG_NAME + '.checkRecordAccess');
            Id currentUserId = UserInfo.getUserId();

            Boolean hasObjectEditAccess = Schema.sObjectType.Opportunity.isUpdateable();

            List<UserRecordAccess> lstUserAccess = new List<UserRecordAccess>();
            ilib_LogQuery logger = new ilib_LogQuery( EXCEPTION_LOG_NAME + 'UserRecordAccess');
            lstUserAccess = [ SELECT RecordId FROM UserRecordAccess WHERE UserId =: currentUserId 
                            AND RecordId =: oppId AND HasEditAccess = true LIMIT 1];
            logger.stop();
            if(!lstUserAccess.isEmpty() && hasObjectEditAccess)   
            {
                ilib_LogEvent.message('User Access to object  ' + hasObjectEditAccess);
                ilib_LogEvent.message('User Access to record  ' + !lstUserAccess.isEmpty());
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return STRSUCCESS;
            }  

            return STRERROR;

        } 
        catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    /* Method to get CSP from SAP */
    @AuraEnabled
    public static String getPricingDetails(Id oppId)
    {
        try 
        {
            ilib_LogEvent.push(EXCEPTION_LOG_NAME + '.getPricingDetails');
            OpportunitySelector oppSelector = new OpportunitySelector();
            List<Opportunity> lstOpportunity =  oppSelector.selectOpportunities(new Set<Id> {oppId});
            Id oppSoldToAccId = lstOpportunity[0].AccountId;
            Boolean boolQuotePresent = String.isNotBlank(lstOpportunity[0].First_Proposal_Id__c);

            String productIdJSONString = getProductIdSet(oppId);
            String strResult = '';

            if(boolQuotePresent) { return 'Quote Present Error'; }
            
            if(productIdJSONString != STR_BLANK){
            strResult = CustomerSpecificPricingController.getPricingData(oppSoldToAccId,productIdJSONString);
            }
            if(test.isRunningTest())
            {
                strResult = '{"SdCurr":null,"salesOrg":"US01","resp":[{"unitp":"4,085.00","mvgr1":"","matxt":"Autoloader2 Warranty Upgrade: SSP","matnr":"20020084","kunnr":"6000022795","konwa":"","isVisible":null,"custp":"4,085.00","bismt":""},{"unitp":"Request Quote","mvgr1":"","matxt":"Autoloader2 Warranty Upgrade: SSP","matnr":"20020085","kunnr":"6000022795","konwa":"","isVisible":null,"custp":"Request Quote","bismt":""}],"pricingDate":null,"Division":null,"DistChannel":null}';
            }

            if(String.isNotBlank(strResult))
            {
                ilib_LogEvent.message('SAP Result ' + strResult);
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return updateOppLineItems(strResult);
            }
            else { return STRERROR; }
            
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }

    }

    /*Method Description - Creates JSON String to pass to SAP */    
    public static String getProductIdSet(Id oppId)
    {
        OpportunityLineItemsSelector oppLineItemSelector = new OpportunityLineItemsSelector();
        lstOppLineItems = oppLineItemSelector.selectOpportunityLineItems(new Set<Id> {oppId});
        String jsonString = '[';

        if(!lstOppLineItems.isEmpty())
        {
            Integer lstSize = lstOppLineItems.size();
            Integer i = 0;
            for(OpportunityLineItem oli : lstOppLineItems)
            {
                i++;
                jsonString = jsonString + '{"id":"' + oli.Product2Id + '"}';
                if(i < lstSize)
                {
                    jsonString = jsonString + ',';
                }
            }
            jsonString = jsonString + ']'; //Dummy JSON '[{"id":"Product1Id"},{"id":"Product2Id"}]'
        }

        if(String.isNotBlank(jsonString))
        {
            return jsonString;
        }

        return STR_BLANK;
    }

    /* Method to update CSP value on Opp Line Items */
    public static string updateOppLineItems(String jsonRequest){
        try {
            CustomerSpecificPricingController.ResponseWrapperFinal pricingResp = (CustomerSpecificPricingController.ResponseWrapperFinal)JSON.deserialize(jsonRequest,CustomerSpecificPricingController.ResponseWrapperFinal.class);
            List<CustomerSpecificPricingController.MaterialData> matResponse = new List<CustomerSpecificPricingController.MaterialData>();
            Map<String,CustomerSpecificPricingController.MaterialData> materialNumberToDataMap = new Map<String,CustomerSpecificPricingController.MaterialData>();

            if(pricingResp.resp != null)
            {
                matResponse = pricingResp.resp;
                if(!matResponse.isEmpty())
                {
                    for(CustomerSpecificPricingController.MaterialData matresp : matResponse)
                    {
                        materialNumberToDataMap.put(matresp.matnr,matresp);
                    }
                }
            }
            Boolean lineItemsUpdated = false;
            if(!materialNumberToDataMap.isEmpty())
            {
                lineItemsUpdated = updateOLIValues(materialNumberToDataMap);
            }
            String returnResp = STRERROR;
            if(lineItemsUpdated)
            {
            returnResp = STRSUCCESS; 
            }
            if(exceptionMessage.length() > INTEGERVALUE2) { return exceptionMessage;}
            
            return returnResp;

        } 
        catch (Exception e) {    throw new AuraHandledException(e.getMessage()); }
    }

    /* Method to Update OLI Values */
    public static boolean updateOLIValues(Map<String,CustomerSpecificPricingController.MaterialData> materialDataMap)
    {
        try{
            ilib_LogEvent.push(EXCEPTION_LOG_NAME + '.updateOLIValues');
            for(OpportunityLineItem oli : lstOppLineItems)
            {
                if(materialDataMap.containsKey(oli.Product2.ProductCode))
                {
                    CustomerSpecificPricingController.MaterialData matData = materialDataMap.get(oli.Product2.ProductCode);
                    ilib_LogEvent.message('MatData - ' + matData);
                    //DCP-47880
                    if(matData.unitp == '' || matData.unitp == 'Request Quote'){
                        oli.List_Price__c  = 'Not Avail';                      
                    }
                    else
                    {
                        string unitPrice = matData.unitp.replaceAll(',' ,'');
                        oli.UnitPrice = Decimal.valueOf(unitPrice);
                        oli.List_Price__c  = String.valueOf(matData.unitp); 
						 OpportunityLineItems.isAutomation = true;
                    }
                    //DCP-47880
                    if(matData.custp == '' || matData.custp == 'Request Quote'){
                            oli.Customer_Specific_Price__c = 'Not Avail';                        
                    }
                    else 
                    {
                        string unitPrice = matData.custp.replaceAll(',' ,'');
                        oli.UnitPrice = Decimal.valueOf(unitPrice);
                        oli.Customer_Specific_Price__c = String.valueOf(matData.custp);
						 OpportunityLineItems.isAutomation = true;
                    }
                }   
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            update lstOppLineItems;
            return true;
        }
        Catch(Exception e)
        {
            exceptionMessage = exceptionMessage + e.getMessage();
            ApexExceptions.emit(EXCEPTION_LOG_NAME,lstOppLineItems[0].OpportunityId,e);
            return false;
        }
    }

}