/**
*    @author Adyasha Satapathy
*    @date   2021-06-06
*    @description  DCP-38810: Test Class for Prompt for Requoting based on comparison between estimate and debrief lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-06-06          Initial Version
*         Ashwin Kumar                 31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public with sharing class TestPromptReQuoteOnBillableWO {

    /**
    *   DCP-38810
	*	@author Adyasha
	**/
    @TestSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        
        // Add Products
        List<Product2> lstProducts = new List<Product2>();

        Product2 objProduct1 = TestDataMaster.initProduct('15013864');
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        Product2 objProduct3 = TestDataMaster.createProduct(false);  
        Product2 objProduct4 = TestDataMaster.createProduct(false);  
        lstProducts.add(objProduct1);
        lstProducts.add(objProduct2);
        lstProducts.add(objProduct3);
        lstProducts.add(objProduct4);

        insert lstProducts;

        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        //insert case		 
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        //insert Estimates work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Estimates', objCase.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c = WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES;
        insert workOrder;

        List<SVMXC__Service_Order_Line__c> lstEstimateLine = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Product__c = objProduct2.Id;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 2;
        lstEstimateLine.add(objOrderDetailPart1);

        SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart2.SVMXC__Product__c = objProduct3.Id;
        objOrderDetailPart2.SVMXC__Estimated_Quantity2__c = 1;
        lstEstimateLine.add(objOrderDetailPart2);

        SVMXC__Service_Order_Line__c objOrderDetailPart5 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart5.SVMXC__Product__c = objProduct1.Id;
        objOrderDetailPart5.SVMXC__Estimated_Quantity2__c = 2;
        objOrderDetailPart5.SVMXC__Line_Type__c = 'Labor';
        lstEstimateLine.add(objOrderDetailPart5);

        insert lstEstimateLine;
        
        //Convert work order to field service.
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId(); 
        workOrder.RecordTypeId = idWorkDetailRecordTypeId;
        workOrder.PO_Number__c = '11223';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Order_Status__c = 'Technician Onsite';
        update workOrder;

        cs.Bypass_All_Validations__c = false;
        cs.Bypass_All_Triggers__c = false;
        upsert cs cs_Apex_Settings__c.Id;

        //Create Debrief line items
        List<SVMXC__Service_Order_Line__c> lstDebriefLine = new List<SVMXC__Service_Order_Line__c>();
        
        SVMXC__Service_Order_Line__c objOrderDetailPart3 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,TestWorkDetails.STRING_USAGE_CONSUMPTION);
        objOrderDetailPart3.SVMXC__Product__c = objProduct3.Id;
        objOrderDetailPart3.SVMXC__Actual_Quantity2__c = 4;
        objOrderDetailPart3.SVMXC__Line_Type__c = 'Material Consumed';
        objOrderDetailPart3.SVMXC__Is_Billable__c = true;
        lstDebriefLine.add(objOrderDetailPart3);

        SVMXC__Service_Order_Line__c objOrderDetailPart4 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,TestWorkDetails.STRING_USAGE_CONSUMPTION);
        objOrderDetailPart4.SVMXC__Product__c = objProduct1.Id;
        objOrderDetailPart4.SVMXC__Line_Type__c = 'Labor';
        objOrderDetailPart4.Labor_Hours__c  = '4:30';
        objOrderDetailPart4.SVMXC__Is_Billable__c = true;
        lstDebriefLine.add(objOrderDetailPart4);

        SVMXC__Service_Order_Line__c objOrderDetailPart6 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,TestWorkDetails.STRING_USAGE_CONSUMPTION);
        objOrderDetailPart6.SVMXC__Product__c = objProduct4.Id;
        objOrderDetailPart6.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailPart6.SVMXC__Line_Type__c = 'Material Consumed';
        objOrderDetailPart6.SVMXC__Is_Billable__c = true;
        lstDebriefLine.add(objOrderDetailPart6);

        insert lstDebriefLine;
    }

    /**
    *   DCP-38810
    *   @author Adyasha 
    **/
    @isTest
    static void testWOUpdateToComplete(){
        String strErrorMessage = '';
        SVMXC__Service_Order__c existingWorkOrder = [SELECT Id, SVMXC__Case__c FROM SVMXC__Service_Order__c LIMIT 1];
        Test.startTest();
        try{

            SVMXC__Service_Order__c objWorkorder = new SVMXC__Service_Order__c(Id=existingWorkOrder.Id);
            objWorkorder.SVMXC__Order_Status__c = 'Completed';
            objWorkorder.Evaluation__c = 'evaluation';
            objWorkorder.SVMXC__Work_Performed__c = 'work performed';
            objWorkorder.Verification_Result__c = 'result';
            objWorkorder.Is_Service_Report_Generated__c = false;
            objWorkorder.Signature_Type__c = Label.WorkOrderSignatureTypeManualSign;
            objWorkorder.Manual_Sign_Captured__c = false;
            objWorkorder.Abandoned_Reason__c = 'No Customer Response';
            objWorkorder.SVMX_PS_Subject__c = 'subject';
            update objWorkorder;
            
        }
        catch(Exception e)
        {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(strErrorMessage.contains(Label.PromptReQuotingErrorMessageOnWorkOrderWorkDetail),'Incorrect Error:' + strErrorMessage);
    }

}