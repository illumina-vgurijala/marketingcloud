/**
*    @author Adyasha Satapathy
*    @date   2021-05-10 
*    @description    DCP-38809: Test class for data setup for creation of Work Order 
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Adyasha Satapathy       2021-05-10          Initial Version
*         Akshay Mohan            2021-06-03          DCP-46834 Product & Work order setup
*         Ashwin Kumar            2022-03-31          DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestDataBillableFlowQueueable
{
    public static final String STRING_WORK_ORDER_RECORD_TYPE_ESTIMATES = 'Estimates';
    public static final String PRICE_LIST_TYPE = '01';
    public static final String PRICE_LIST_CURRENCY = 'USD';
    public static final string PRICE_LIST = '01-AMR-USD';
    public static final string COMPANY_CODE = 'US01';
    public static final string TRACKING_SERIALIZED = 'Serialized';
    public static final string SERVICE_PRODUCT_TYPE_SPARE = 'Spare';
    public static final string SERVICE_PRODUCT_STATUS_AVAILABLE = 'Available';

    /**for codescan making test method
     *  @author      : Adyasha Satapathy
     *  @description : Method to create Workorder data
     **/
    @isTest
    public static SVMXC__Service_Order__c getWorkOrder()
    {
        SVMXC__Service_Order__c objWorkOrder;
        
        Territory2 objTerritory = TestTerritoryPlanStrategyController.getTerritory();
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        //Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        insert objAccount;
        
        System.runAs(objAdminUser)
        {
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTerritory.Id,objAccount.Id); 
            UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTerritory.Id,objAdminUser.id);
            insert objUTA;
        }
        //Create contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(COMPANY_CODE,'01','177','00',false);
        accSalesArea.Account__c = objAccount.Id;
        accSalesArea.Price_List_Type__c=PRICE_LIST_TYPE;
        accSalesArea.CurrencyIsoCode = PRICE_LIST_CURRENCY;
        accSalesArea.Price_List__c = PRICE_LIST;
        accSalesArea.Contract_Number__c = '345678_US010100';
        accSalesArea.Company_Code__c = COMPANY_CODE;

        insert accSalesArea;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert priceList;

        Product2 toolProduct = TestDataMaster.initProduct('IL-SER-TRAVEL-Z1','Tools');//DCP-46834: Changes on product setup
        toolProduct.IsActive = true;
        toolProduct.SVMXC__Tracking__c = TRACKING_SERIALIZED;
        toolProduct.SVMXC__Stockable__c = true;
        toolProduct.SVMXC__Enable_Serialized_Tracking__c = true;
        toolProduct.Service_Product_Type__c  = SERVICE_PRODUCT_TYPE_SPARE;
        toolProduct.Material_Group__c = '41';
        toolProduct.Material_Number__c = '20029031';
        toolProduct.RMA_Required__c = true;

        insert new List<Product2>{toolProduct};

        PricebookEntry pbe1 = initPriceBookEntry(toolProduct.Id, 200,PRICE_LIST_CURRENCY);
        insert new List<PricebookEntry>{pbe1};

        System.runAs(objAdminUser)
        {
            SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(toolProduct.Id);
            insert workOrderIP;

            cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            setting.Bypass_All_Validations__c = true;
            upsert setting;

            SVMXC__Site__c location = new SVMXC__Site__c();
            location.Name = 'Test Location 1';
            location.SVMXC__Account__c = objAccount.Id;
            location.SVMXC__Stocking_Location__c = true;
            insert location;

            //Insert Product Stock
            SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
            serializedProdStock.SVMXC__Location__c = location.Id;
            serializedProdStock.SVMXC__Product__c = toolProduct.Id;
            serializedProdStock.SVMXC__Status__c = SERVICE_PRODUCT_STATUS_AVAILABLE;
            serializedProdStock.SVMXC__Quantity2__c = 6;
            insert serializedProdStock;

            Profile profile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(profile.Id);
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c = true;
            upsert cs cs_Apex_Settings__c.Id;

            //Create Case
            Case objCaseTest = TestDataCase.initServiceRequestCase(objContact);
            insert objCaseTest;

            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(objAdminUser.id,'Primary Field Application Scientist',serviceTeam.id);
            technician.SVMXC__Email__c='a@b.com';
            technician.Preferred_Service_Report_Language__c='Japanese';
            insert technician;

            Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(objAccount.id,'Field Service Manager',technician.id);
            insert accToFieldSupport;

           Test.startTest();
            //Create WorkOrder
            objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_ESTIMATES, objCaseTest.Id, TestPartsOrderLines.STRING_WORK_ORDER_STATUS_INITIATED);
            objWorkOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeServiceActivities;//DCP-46834: Changes on WO setup
            objWorkOrder.SVMXC__Company__c = objAccount.Id;
            objWorkOrder.SVMXC__Contact__c = objContact.Id;
            objWorkOrder.OwnerId = UserInfo.getUserId();
            objworkOrder.SVMXC__Group_Member__c = technician.id;
            objworkOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable;//DCP-46834: Changes on WO setup
            insert objWorkOrder;

            cs.Bypass_All_Validations__c = false;
            cs.Bypass_All_Triggers__c = false;
            upsert cs cs_Apex_Settings__c.Id;
            //Create WorkDetail
            Id idEstimateRT = SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Estimate').getRecordTypeId();
            SVMXC__Service_Order_Line__c objWorkDetail1= TestDataFieldService.createWorkDetail(objworkOrder.Id,workOrderIP.Id);
            objWorkDetail1.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail1.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail1.SVMXC__Line_Type__c = 'Labor';
            objWorkDetail1.SVMXC__Product__c=toolProduct.id;
            objWorkDetail1.RecordTypeId=idEstimateRT;//DCP-46834: set record type
            
            SVMXC__Service_Order_Line__c objWorkDetail2= TestDataFieldService.createWorkDetail(objworkOrder.Id,workOrderIP.Id);
            objWorkDetail2.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail2.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail2.SVMXC__Line_Type__c = 'Travel';
            objWorkDetail2.SVMXC__Product__c=toolProduct.id;
            objWorkDetail2.RecordTypeId=idEstimateRT;//DCP-46834: set record type
            
            insert new List<SVMXC__Service_Order_Line__c>{objWorkDetail1,objWorkDetail2};
            Test.stopTest();
            System.assert(String.isNotBlank(objWorkDetail1.Id),'work order not inserted');//for codescan
            setting.Bypass_All_Validations__c = false;
            update setting;
        }
        return objWorkOrder;
     
   }
     /**
     *  @author      : Adyasha Satapathy
     *  @description : Method to create Opportunity for further creation of Quote
     **/
   public static Opportunity createOpportunityFromWorkOrder(Id workOrderId, Id productId)
   {
        SVMXC__Service_Order__c objWorkOrder = new WorkOrdersSelector().selectWorkOrderWithWorkDetails(new Set<Id>{workOrderId})[0];
        User objAdminUser = new UsersSelector().selectUsersByNames(new Set<String>{CreateOpportunityAutomation.STRING_GIS_ILLUMINA_USER})[0];
        String strRecordTypeId = Opportunities.RECORD_TYPE_MAP.get(Label.FieldServices).getRecordTypeId();
        String strSerialNumber = String.isBlank(objWorkOrder.Installed_Product_Serial_Number__c) ? '' : ' - ' + objWorkOrder.Installed_Product_Serial_Number__c;
        
        Opportunity objOpportunityToInsert = TestDataOpportunity.initOpportunity2(objWorkOrder.SVMXC__Company__c);
        
        objOpportunityToInsert.Name = objWorkOrder.Name + ' - ' + CreateOpportunityAutomation.OPP_NAME_BILLABLE_SERVICE + strSerialNumber;
        objOpportunityToInsert.Type = Label.OpportunityTypeBillableService;
        objOpportunityToInsert.CloseDate = Date.today().addDays(90);
        objOpportunityToInsert.Product_Interest__c = Label.OpportunityProductInterestBreakFix;
        objOpportunityToInsert.StageName = Label.OpportunityStageDevelop;
        objOpportunityToInsert.Probability = Decimal.valueOf(50);
        objOpportunityToInsert.Amount = 0;
        objOpportunityToInsert.Work_Order__c = workOrderId;
        objOpportunityToInsert.OwnerId = objAdminUser.Id;
        objOpportunityToInsert.Price_List__c = PRICE_LIST;
        objOpportunityToInsert.RecordTypeId = strRecordTypeId;

        insert objOpportunityToInsert;
        Opportunity opp = [SELECT id, Price_List__c FROM Opportunity WHERE Id = :objOpportunityToInsert.Id];
        System.debug('@@@@ objOpportunityToInsert price list ->'+opp.Price_List__c);
        OpportunityContactRole objContactRole = new OpportunityContactRole();
        objContactRole.ContactId = objWorkOrder.SVMXC__Contact__c;
        objContactRole.IsPrimary = true;
        objContactRole.Role = Label.Power_Sponsor_Contact_Role;
        objContactRole.OpportunityId = objOpportunityToInsert.Id;
        insert objContactRole;
        
        if(String.isNotBlank(productId)){
            PricebookEntry objPbe = [Select Id from PricebookEntry WHERE Product2Id =:productId];
            OpportunityLineItem oli = TestDataMaster.createOpportunityProduct(objOpportunityToInsert.Id, objPbe.Id, false);
            oli.Work_Detail_Line__c = objWorkOrder.SVMXC__Service_Order_Line__r.get(0).Id;
            oli.Serial_Number__c =  objWorkOrder.Installed_Product_Serial_Number__c;
            insert oli;
        }
        

        return objOpportunityToInsert;
   }
     /**
     *  @author      : Adyasha Satapathy
     *  @description : Method to create Pricebook
     **/
     public static PricebookEntry initPriceBookEntry(Id productId,Double price, String currencyCode){
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        return new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = productId,
            UnitPrice = price,
            UseStandardPrice = false,
            IsActive = true,
            CurrencyIsoCode = currencyCode
        );
     }
}