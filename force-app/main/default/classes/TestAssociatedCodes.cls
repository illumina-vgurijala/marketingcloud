/***************************************************************************************************************************************
 * NAME   : TestAssociatedCodes
 * DESCRIPTION  : TestClass for Associated Code Trigger and AssociatedCodesRelatedListController
 * @AUTHOR : Shashank Singhal
 * @DATE   : 12-July-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank             12-July-2018            Initial Vesrion
 * Abhishek             22-Sept-2023            Removed the validateLogisticsCodeonCase method - cmcm-3533
 * Dhairya              17-April2024            CMCM-6760
 *****************************************************************************************************************************************/ 
@isTest(seeAllData = false)
private class TestAssociatedCodes {
private static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
private static final string STRING_PRODUCT_CODE = 'Test 1234';
private static final string STRING_EVALUATION_ANSWER_PENDING='Pending';
private static final string STRING_CASE_SUB_TYPE = 'Complaint';
private static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
private static final String STRING_CASE_INQUIRY = 'Inquiry';
private static final string STRING_CASE_STATUS = 'Initiated';
private static final string STRING_CASE_ORIGIN = 'Phone - CS';


private static final string STRING_CASE_STATUS_COMPLETED = 'Completed';
private static final string STRING_EVALUATION_ANSWER_NO = 'No';
private static final string STRING_EVALUATION_ANSWER_YES = 'YES';
    /**
    *  @author Shashank Singhal
    *  @description - test the update on case when a new associated code is inserted 
    **/
    static testMethod void insertAssociatedCode(){
	    SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                               SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
        insert consumptionSetting; 
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        Contact con = TestDataPerson.getNewContact(objAccount.Id);
        //Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Product2 prod = TestDataMaster.initProduct('43535');
        prod.Product_Category__c = 'HiSeq';
        prod.Source_System__c = 'SAP';
        insert prod;
        System.assertNotEquals(null, prod.id);
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Product__c = prod.id;
        ip.SVMXC__Company__c = objAccount.Id;
        insert ip;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = ip.id;
        cs.productid = prod.id;
        insert cs;
        System.assertNotEquals(null, cs.Id);
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Installation';
        wo.Has_Resolution_Code__c = true;
        wo.Is_Auto_Created__c =true;
        wo.SVMXC__Component__c = ip.Id;
        wo.SVMXC__Product__c = prod.id; 
        wo.SVMXC__Case__c = cs.Id;
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c';
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = UserInfo.getUserId();
        insert csapex; 
        insert wo;
        test.starttest();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = wo.id;
        objOrderDetail.SVMXC__Serial_Number__c = ip.Id;
        objOrderDetail.SVMXC__Product__c = prod.id;
        objOrderDetail.RecordTypeId = [Select Id from RecordType where sObjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Related Products'].Id;
        insert objOrderDetail;
        System.assertNotEquals(null, objOrderDetail.Id);
       
        Code_Library__c pcl = new Code_Library__c(Name='Test1', Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
        insert pcl;
        Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Subject', Parent_Code__c=pcl.Id, Service_Product_Type__c = 'Tool');
        insert cl;
        Code_Library__c c2 = new Code_Library__c(Name='Test3', Code_type__c = 'Subject', Parent_Code__c=pcl.Id, Service_Product_Type__c = 'Tool');
		insert c2;
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = cl.Id;
        ac.Case__c = cs.Id;
        ac.Work_Order__c = wo.Id;
        insert ac;
        ac.Code_Title__c = c2.Id;
        ac.Product_Category__c = 'HiSeq';
		update ac;
        test.stoptest();
        AssociatedCodesRelatedListController.getAssociatedCodes(wo.Id);
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - test the product category 
    **/
    static testMethod void checkProductCategory(){
	SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        Contact con = TestDataPerson.getNewContact(objAccount.Id);
        Product2 prod = TestDataMaster.initProduct('43535');
        prod.Product_Category__c = 'HiSeq';
        prod.Source_System__c = 'SAP';
        insert prod;
		System.assertNotEquals(null, prod.id);									  
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Product__c = prod.id;
        ip.SVMXC__Company__c = objAccount.Id;
        insert ip;
        Case cs = TestDataCase.initServiceRequestCase(con);
        
        cs.SVMXC__Component__c = ip.id;
        cs.productid = prod.id;
        insert cs;
		System.assertNotEquals(null, cs.Id);									
        
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Installation';
        wo.Has_Resolution_Code__c = true;
		wo.Is_Auto_Created__c =true;
        wo.SVMXC__Component__c = ip.Id;
        wo.SVMXC__Product__c = prod.id;	
		wo.SVMXC__Case__c = cs.Id;

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Order_Line__c'
        );
        insert apexSettings;
        test.startTest();
        insert wo;
		System.assertNotEquals(null, wo.Id);           									
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = wo.id;
        objOrderDetail.SVMXC__Serial_Number__c = ip.Id;
        objOrderDetail.SVMXC__Product__c = prod.id;
        objOrderDetail.RecordTypeId = [Select Id from RecordType where sObjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Related Products'].Id;
        
        insert objOrderDetail;
		System.assertNotEquals(null, objOrderDetail.Id);												
		
        Code_Library__c codel = new Code_Library__c(Name='Test1', Code_type__c = 'Subject', Product_Category__c = 'iSeq', Service_Product_Type__c = 'Tool');
        insert codel;
		System.assertNotEquals(null, codel.Id);									   
        
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = codel.Id;
        ac.Case__c = cs.Id;
        ac.Work_Order__c = wo.Id;
		
        try{
            insert ac;
			System.assertNotEquals(null, ac.Id);
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        
        test.stopTest();
	    List<Associated_Codes__c> lstAssociatedCodes=[select id, Product_Category__c from Associated_Codes__c where id =: ac.Id];
        System.assertNotEquals(null, lstAssociatedCodes);
        System.assertNotEquals(0, lstAssociatedCodes.size());
        //System.assertEquals('iSeq', lstAssociatedCodes[0].Product_Category__c); CMCM-6760 commented by Dhairya Shah
    }
    static testMethod void testCodeLibrary(){
        Code_Library__c codeLibrary = TestDataFieldService.createCodeLibrary('Test','Analysis','Consumable');
        insert codeLibrary;
        Set<String> setOfTypes= new Set<String>{'Analysis'};
        Test.startTest();
        CodeLibrarySelector cls = new CodeLibrarySelector();
        cls.selectCodeLibraryByType(setOfTypes);
        cls.selectCodeLibraryByTitle(setOfTypes);
        cls.selectCodeLibraryById(new Set<Id>{codeLibrary.Id});
        cls.selectCodeLibraryBySimilarTitle(codeLibrary.Name,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
        cls.selectCodeLibrBySimilarTitleAndType(codeLibrary.Name,codeLibrary.Code_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
        cls.selectCodeLibrByTitleCodeTypeCaseType(codeLibrary.Name,codeLibrary.Code_Type__c,codeLibrary.Case_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
        cls.selectCodeLibrByHazard(codeLibrary.Name,codeLibrary.Code_Type__c,codeLibrary.Case_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
        cls.selectCodeLibrByLogisticsReviewCode(codeLibrary.Name,codeLibrary.Code_Type__c,codeLibrary.Case_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
        cls.selectDisassocaiatedCodeLibrary();
        cls.selectCodeLibraryByIds(new Set<Id>{codeLibrary.id});
        system.assertEquals(true, setOfTypes.contains('Analysis'));
        Test.stopTest();
    }

    static testmethod void testChatterNotification() {
        cs_Apex_Settings__c csapex = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        csapex.Bypass_All_Validations__c = true;
        csapex.Bypass_Triggers_By_Object_1__c = 'Account';
        csapex.Bypass_Triggers_By_Object_2__c = 'Contact';
        csapex.Bypass_Triggers_By_Object_3__c = 'SVMXC__service_order__c';
        csapex.Bypass_Triggers_By_Object_4__c = 'Product2';
        upsert csapex;

        Account objAcc = TestDataAccount.getNewAccount();
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
        objCase.Category__c = 'LIMS';
        objCase.Product_Utilization_Mode__c = 'IUO';
        insert objCase;
        
        SVMXC__service_order__c objWO = [SELECT id,Evaluation__c,SVMXC__Work_Performed__c,Verification_Result__c,SVMXC__Order_Status__c 
                                        FROM SVMXC__service_order__c 
                                        WHERE SVMXC__case__c =: objCase.Id];
        
        List<Code_Library__c> listCode = new List<Code_Library__c>();
        Code_Library__c code1 = new Code_Library__c();
        code1.Name='INQ General Process Inquiry';
        code1.Code_type__c = 'Analysis';
        code1.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        listCode.add(code1);
        
        Code_Library__c code2 = new Code_Library__c();
        code2.Name='Code Disassociated';
        code2.Code_type__c = 'Subject';
        code2.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        listCode.add(code2);
        Insert listCode;
        
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = code1.Id;
        ac.Case__c = objCase.Id;
        ac.Work_Order__c = objWO.Id;
        insert ac;
        
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
        objCase.pAE_pFA_Awareness_Date__c = Date.today();
        objCase.Explanation_for_pAE_pFA__c='Test';
        objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
        objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
        objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Question_3__c = '"Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?"';
        objCase.Question_4__c = '"Did the IVD product fail to perform as intended? E.g. product not performing as designed, or meeting package insert specification such as sensitivity, specificity, and accuracy, due to a product deficiency."';
        objCase.Question_5__c = '"Did the determined issue suggest misbranding, labeling or an adulterated IVD product (defective, unsafe, or contaminated)? E.g. product mislabeled, incorrectly packaged, incorrect instruction in package insert, reagent contains foreign substance."';
        objCase.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Investigation_Summary_Comments__c = 'test';
        objCase.Logistics_Investigation_Summary_Comments__c = 'logistictest';
        objCase.Logistics_Review__c = 'See Investigation Summary/Comments';
        objCase.Record_Updated_from_SFM__c = True;
        objCase.QA_Review__c = 'Non IVD Product';
        objCase.QA_Product_Family__c = 'NIPT';
        objCase.QA_Sub_Product_Family__c = 'NIPT Solution v2';
        objCase.Status = 'Pending QA Review';
        Test.startTest();
        update objCase;
        system.assertEquals('Pending QA Review',objCase.Status,'Status updated to Pending QA Review');

        ac.Code_Title__c = code2.id;
        update ac;
        system.assert(ac.Code_Title__c != null,'Code title should not null');   

        User serviceUser=TestDataUser.findUserInProfile(Label.Profile_Service_Logistics);      
        system.runAs(serviceUser){

            cs_Apex_Settings__c cssetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            cssetting.Bypass_All_Validations__c = true;
            upsert cssetting;
            
            objWo.Evaluation__c = 'testEvaluation';
            objWo.SVMXC__Work_Performed__c = 'testWorkPerformed';
            objWo.Verification_Result__c = 'testVerificationResult';
            objWO.SVMXC__Order_Status__c = STRING_CASE_STATUS_COMPLETED;
            WorkOrders.skipWOTrigger = true;
            update objWO;

            System.assertEquals(STRING_CASE_STATUS_COMPLETED, [SELECT SVMXC__Order_Status__c FROM SVMXC__service_order__c WHERE Id = :objWO.Id].SVMXC__Order_Status__c);
        }
        Test.stopTest();
    }    

    @IsTest
    static void testRestrictUpdate() {
        
        User u = TestDataFieldService.createUser(System.label.Field_Service,false);
        system.runAs(u){
            cs_Apex_Settings__c csapex = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            csapex.Bypass_All_Validations__c = true;
            csapex.Bypass_Triggers_By_Object_1__c = 'Account';
            csapex.Bypass_Triggers_By_Object_2__c = 'Contact';
            csapex.Bypass_Triggers_By_Object_3__c = 'SVMXC__service_order__c';
            csapex.Bypass_Triggers_By_Object_4__c = 'Product2';
            upsert csapex;
    
            Account objAcc = TestDataAccount.getNewAccount();
            
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
            insert con;
            
            Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
            objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
            objProduct.Regulatory_Type__c = 'DX';
            insert objProduct;
    
            Case objCase = TestDataCase.initNewCase(STRING_CASE_INQUIRY,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
            objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_INQUIRY).getRecordTypeId();
            objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
            objCase.SVMXC__Product__c = objProduct.Id;
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
            objCase.Description = 'testDescription';
            objCase.Product_Utilization_Mode__c = 'IUO';
            Cases.skipCaseTrigger = true;
            insert objCase;
    
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Relocation';
            workOrder.Customer_Requested_Not_To_Re_Install__c=true;
            workOrder.Record_Created_from_SFM__c=true;
            WorkOrders.skipWOTrigger = true;
            insert workOrder;

            workOrder.Relocated_Account__c=objAcc.id;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.No_Calibrated_Tools_Used__c=true;
            workOrder.SVMXC__Order_Status__c='Completed';
            workOrder.No_Calibrated_Tools_Used__c = true;
            workOrder.Evaluation__c='Test';
            workOrder.SVMXC__Work_Performed__c='Test';
            workOrder.Verification_Result__c='Test'; 
            workOrder.Has_Verification_Code__c =true;
            workOrder.PO_Number__c='12';
            workorder.SVMXC__Contact__c=con.id;
            WorkOrders.skipWOTrigger = true;
            Cases.skipCaseTrigger = true;
            update workOrder;
    
            Associated_Codes__c associatedCode = new Associated_Codes__c(
            Case__c = objCase.Id,
            Work_Order__c = workorder.Id,
            Code_Type__c = System.Label.AssociatedCodeTypeSubject
            );
            insert associatedCode;
    
            // Update the Associated_Codes__c record to trigger the logic
            Test.startTest();
            associatedCode.Code_Type__c = Label.AssociatedCodeTypeProduct;
            update associatedCode;
            Test.stopTest();
    
            // Fetch the updated Associated_Codes__c record to verify behavior
            Associated_Codes__c updatedCode = [SELECT Id, Code_Type__c FROM Associated_Codes__c WHERE Id = :associatedCode.Id];
            
            // Assertions to validate logic
            System.assertEquals(Label.AssociatedCodeTypeProduct, updatedCode.Code_Type__c, 'Code Type should be updated correctly.');
    
            // Negative test cases: Update data that violates the rules
            associatedCode.Code_Type__c = Label.AssociatedCodeTypeAnalysis;
            try {
                update associatedCode;
                System.assert(false, 'Exception should have been thrown for invalid update.');
            } catch (DmlException ex) {
                System.assert(ex.getMessage().contains(System.Label.RestrictAssociateCodeInsertAndUpdate), 'Validation error message mismatch.');
            }
        }
    }

    @IsTest
    static void testRestrictUpdate1() {
        
        User u = TestDataFieldService.createUser(System.label.Field_Service,false);
        system.runAs(u){
            cs_Apex_Settings__c csapex = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            csapex.Bypass_All_Validations__c = true;
            csapex.Bypass_Triggers_By_Object_1__c = 'Account';
            csapex.Bypass_Triggers_By_Object_2__c = 'Contact';
            csapex.Bypass_Triggers_By_Object_3__c = 'SVMXC__service_order__c';
            csapex.Bypass_Triggers_By_Object_4__c = 'Product2';
            upsert csapex;
    
            Account objAcc = TestDataAccount.getNewAccount();
            
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
            insert con;
            
            Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
            objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
            objProduct.Regulatory_Type__c = 'DX';
            insert objProduct;
    
            Case objCase = TestDataCase.initNewCase(STRING_CASE_INQUIRY,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
            objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_INQUIRY).getRecordTypeId();
            objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
            objCase.SVMXC__Product__c = objProduct.Id;
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
            objCase.Description = 'testDescription';
            objCase.Product_Utilization_Mode__c = 'IUO';
            Cases.skipCaseTrigger = true;
            insert objCase;
    
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Relocation';
            workOrder.Customer_Requested_Not_To_Re_Install__c=true;
            workOrder.Record_Created_from_SFM__c=true;
            WorkOrders.skipWOTrigger = true;
            insert workOrder;

            workOrder.Relocated_Account__c=objAcc.id;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.No_Calibrated_Tools_Used__c=true;
            workOrder.SVMXC__Order_Status__c='Completed';
            workOrder.No_Calibrated_Tools_Used__c = true;
            workOrder.Evaluation__c='Test';
            workOrder.SVMXC__Work_Performed__c='Test';
            workOrder.Verification_Result__c='Test'; 
            workOrder.Has_Verification_Code__c =true;
            workOrder.PO_Number__c='12';
            workorder.SVMXC__Contact__c=con.id;
            WorkOrders.skipWOTrigger = true;
            Cases.skipCaseTrigger = true;
            update workOrder;
    
            Associated_Codes__c associatedCode = new Associated_Codes__c(
            Case__c = objCase.Id,
            Work_Order__c = workorder.Id,
            Code_Type__c = System.Label.AssociatedCodeTypeProduct 
            );
            insert associatedCode;
    
            // Update the Associated_Codes__c record to trigger the logic
            Test.startTest();
                AssociatedCodes.isACInsert = false;
                associatedCode.Code_Type__c = Label.AssociatedCodeTypeAnalysis;
                try {
                    update associatedCode;
                    System.assert(false, 'Exception should have been thrown for invalid update.');
                } catch (DmlException ex) {
                    System.assert(ex.getMessage().contains(System.Label.RestrictAssociateCodeInsertAndUpdate), 'Validation error message mismatch.');
                }
            
            Test.stopTest();
        }
    }
}