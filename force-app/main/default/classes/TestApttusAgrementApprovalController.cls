/**
*    @author      :Umesh Mor
*    @date        :2020-1-21
*    @description :Test class for ApttusAgrementApprovalController
*    Modification Log:
*     B Kamini          11 Feb 2020         DCP-33783: Added Custom setting Profile validation data setup 
*     Saswati           2nd April 2020      SonarQubeFix
*     Rishab Wali       18th June 2020      Update for DCP-38285
*     Joshith K         10 july 2020        testApttusAgreementwarningMessage
*     Arif,Dalali       28-Nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*     Gerardo Garcia    04-Jun-2024         DGP-107 Test for sorting agreement line items.
*    ---------------------------------
*
***/

@isTest
private class TestApttusAgrementApprovalController{  

    //Added constants for SonarQube issue fixes - Saswati
    public static final string STRLINETYPEMATERIALGROUP = 'Material Group 1';
    public static final string STRDISCOUNTTYPE = '% Discount';
    public static final string STRPAGEREFERENCE = 'Page.PreviewSubmitApprovals';
    public static final string STRAPPROVER = 'Test Approver';

    /**
    * @author : Umesh Mor
    * @description - Notification for Approval Email notification - DCP-31142,DCP-31177
    **/
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '234567';
        acc.Account_Group__c = 'Distributor';

        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '183456';
        insert new List<Account> { acc, acc2 };

        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '234567';
        objCMD2.ERP_Customer_Id__c = '183456';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL=57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement1.recordTypeId=recTypeId;
        insert oAgreement1;

        Apttus__AgreementLineItem__c oAgreementLI1 = initAgreementLineItem(oAgreement1);
        insert oAgreementLI1;

        List<Apttus_Approval__Approval_Request__c> lstobjAppReq = new List<Apttus_Approval__Approval_Request__c>();
        Apttus_Approval__Approval_Request__c objApprovalRequest1 = TestDataAgreement.initAgreementApprovalRequest(oAgreement1.Id);
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataAgreement.initAgreementApprovalRequest(oAgreement1.Id); //Update for DCP-38285
        lstobjAppReq.add(objApprovalRequest1);
        lstobjAppReq.add(objApprovalRequest2);//Update for DCP-38285
        insert lstobjAppReq;
    }

    @isTest
    static void testDisplayAgreements() {
        Test.startTest();
        Apttus__APTS_Agreement__c agreement = getAgreement();

        Test.setCurrentPageReference(new PageReference(STRPAGEREFERENCE));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);
        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = getApprovalRequests(agreement.Id);
        objController.objApprovalRequest = lstApprovalRequest.get(0);
        objController.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = STRAPPROVER;
        objController.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        update objController.objApprovalRequest;
        objController.getLoadAgreementRecord();
        objController.getLoadAgreementData();
        new ApprovalRequestWrapper(1, 'Test', lstApprovalRequest.get(0), 'Xyz', 'AMR', true, false, false);
        Test.stopTest();

        Apttus__AgreementLineItem__c oAgreementLI1 = getAgreementLineItem(agreement.id).get(0);

        Assert.areEqual('AIM', oAgreementLI1.Material_Group_1__c,'Incorrect Material Group');
        Assert.areEqual(oAgreementLI1.Discount_Type__c , STRDISCOUNTTYPE,'Incorrect Discount Type');
    }

    @isTest
    static void testAgreementWrapperConstructors() {
        Test.startTest();
        Apttus__APTS_Agreement__c agreement = getAgreement();

        Test.setCurrentPageReference(new PageReference(STRPAGEREFERENCE));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);
        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = getApprovalRequests(agreement.Id);
        objController.objApprovalRequest = lstApprovalRequest.get(0);
        objController.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = STRAPPROVER;
        objController.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        update objController.objApprovalRequest;
        objController.getLoadAgreementRecord();
        objController.getLoadAgreementData(); 
        objController.getLoadAgreementOpenOfferRecord();           
        new ApprovalRequestWrapper(1,'Test',lstApprovalRequest.get(0),'Xyz','AMR', false, true, false);

        Test.stopTest();

        Apttus__AgreementLineItem__c oAgreementLI1 = getAgreementLineItem(agreement.id).get(0);

        Assert.areEqual('AIM', oAgreementLI1.Material_Group_1__c,'Material Group Incorrect');
        Assert.areEqual(oAgreementLI1.Discount_Type__c, STRDISCOUNTTYPE,'Discount Type Incorrect');
        Assert.areEqual(1, objController.lstAgreementLineItem.size(), 'List size incorrect');
    }

    @isTest
    static void testAgreementsWrapper() {
        Test.startTest();

        Apttus__APTS_Agreement__c agreement = getAgreement();

        Test.setCurrentPageReference(new PageReference(STRPAGEREFERENCE));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);

        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = getApprovalRequests(agreement.Id);

        objController.lstApprovalRequest = lstApprovalRequest; //Update for DCP-38285
        objController.objApprovalRequest = lstApprovalRequest.get(0);
        objController.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = STRAPPROVER;
        objController.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Approved';
        objController.strEmailType ='APPROVALEMAIL';
        update objController.objApprovalRequest;
        objController.getLoadAgreementRecord();
        objController.getLoadAgreementData();
        new ApprovalRequestWrapper(1,'Test',lstApprovalRequest.get(0),'Xyz','AMR',false,false,true);
        Test.stopTest();
        System.assertEquals(1, objController.lstChanlPrtnNonQuotaAgrmentLinItem.size(),'Incorrect List Size');
     }

     @isTest
     static void testApttusAgreementwarningMessage() {

        Test.startTest();
        Apttus__APTS_Agreement__c agreement = getAgreement();
        List<Apttus__AgreementLineItem__c> lstAgreementlines=new List<Apttus__AgreementLineItem__c>();
        //create lines more than 50 to limit the email alert to show 50 lines on discount desc
        for(integer i=0; i<55; i++){
            Apttus__AgreementLineItem__c agreementLine = initAgreementLineItem(agreement);
            lstAgreementlines.add(agreementLine);
        }
        insert lstAgreementlines;

        Test.setCurrentPageReference(new PageReference(STRPAGEREFERENCE));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);

        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = getApprovalRequests(agreement.Id);
        objController.objApprovalRequest = lstApprovalRequest.get(0);
        objController.getLoadAgreementRecord();
        objController.previewAgreements();
        Test.stopTest();

        Assert.isTrue(objController.showWarning, 'Warning did not return true');
    }

    @IsTest
    private static void testSortingAgreementLines() {

        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = true;
        upsert cs;

        Apttus__APTS_Agreement__c agreement = getAgreement();

        // UNORDERED agreement lines.
        //Agreement line that comes from setup
        //oAgreementLI1.Discount__c = 12.23;
        //oAgreementLI1.Priority__c = null;
        //oAgreementLI1.Max_Discount_Guidance__c = null;

        Apttus__AgreementLineItem__c agreementLine0 = initAgreementLineItem(agreement);
        agreementLine0.Discount_In_Percent__c  = 0.20;
        agreementLine0.Max_Discount_Guidance__c = 0.00;
        agreementLine0.Priority__c = 2;

        Apttus__AgreementLineItem__c agreementLine1 = initAgreementLineItem(agreement);
        agreementLine1.Discount_In_Percent__c = 0.9;
        agreementLine1.Max_Discount_Guidance__c = 70.00;
        agreementLine1.Priority__c = 3;

        Apttus__AgreementLineItem__c agreementLine2 = initAgreementLineItem(agreement);
        agreementLine2.Discount_In_Percent__c = 0.50;
        agreementLine2.Max_Discount_Guidance__c = 10.00;
        agreementLine2.Priority__c = 3;

        Apttus__AgreementLineItem__c agreementLine3 = initAgreementLineItem(agreement);
        agreementLine3.Discount_In_Percent__c = 0.2;
        agreementLine3.Max_Discount_Guidance__c = 10.00;
        agreementLine3.Priority__c = 1;

        Apttus__AgreementLineItem__c agreementLine4 = initAgreementLineItem(agreement);
        agreementLine4.Discount_In_Percent__c = 0.2;
        agreementLine4.Max_Discount_Guidance__c = 10.00;
        agreementLine4.Priority__c = 2;

        Apttus__AgreementLineItem__c agreementLine5 = initAgreementLineItem(agreement);
        agreementLine5.Discount_In_Percent__c = 0.2;
        agreementLine5.Max_Discount_Guidance__c = 0.00;
        agreementLine5.Priority__c = 2;

        insert new List<Apttus__AgreementLineItem__c> {agreementLine0, agreementLine1, agreementLine2, agreementLine3, agreementLine4, agreementLine5};

        List <Apttus__AgreementLineItem__c> unOrdered = getAgreementLineItem(agreement.id);
        System.debug('UN-Ordered Ag. Line Items:');
        printLineItems(unOrdered);

        Test.startTest();

        Test.setCurrentPageReference(new PageReference(STRPAGEREFERENCE));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);

        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = getApprovalRequests(agreement.Id);
        objController.objApprovalRequest = lstApprovalRequest.get(0);
        objController.getLoadAgreementRecord();
        objController.previewAgreements();
        Test.stopTest();

        List <Apttus__AgreementLineItem__c> res = objController.lstAgreementLineItem;
        System.debug(JSON.serializePretty(res));

        System.debug('Ordered Ag. Line Items:');
        printLineItems(res);

        Assert.areEqual(7, res.size(), 'Number of Agreement Line Items does not match. It should be 7!');
        // Confirming sorting:
        Assert.areEqual(unOrdered.get(4).Name, res.get(0).Name, '1st item does not match');
        Assert.areEqual(unOrdered.get(5).Name, res.get(1).Name, '2nd item does not match');
        Assert.areEqual(unOrdered.get(1).Name, res.get(2).Name, '3rd item does not match');
        Assert.areEqual(unOrdered.get(6).Name, res.get(3).Name, '4th item does not match');
        Assert.areEqual(unOrdered.get(2).Name, res.get(4).Name, '5th item does not match');
        Assert.areEqual(unOrdered.get(3).Name, res.get(5).Name, '6th item does not match');
        Assert.areEqual(unOrdered.get(0).Name, res.get(6).Name, '7th item does not match');
    }

    private static void printLineItems(List <Apttus__AgreementLineItem__c> res) {
        String log = '';
        for(Apttus__AgreementLineItem__c record : res) {
            log += 'Name:' + record.Name + ' Priority:' + record.Priority__c + ' Discount_Beyond_Threshold__c:' + record.Discount_Beyond_Threshold__c + '\n';
        }
        System.debug(log);
    }

    private static Apttus__AgreementLineItem__c initAgreementLineItem(Apttus__APTS_Agreement__c agreement) {
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(agreement.id);
        oAgreementLI1.Line_Type__c = STRLINETYPEMATERIALGROUP;
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = STRDISCOUNTTYPE;
        oAgreementLI1.Discount__c = 12.23;
        oAgreementLI1.Customer_ERP_Number__c = '234567';
        oAgreementLI1.Sales_Org__c = 'US01';
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode = 'USD';
        oAgreementLI1.Material_Group_1__c = 'AIM';
        oAgreementLI1.Apttus_CMConfig__StartDate__c = System.today()+5;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = System.today()+28;
        return oAgreementLI1;
    }

    private static Apttus__APTS_Agreement__c getAgreement() {
        return [SELECT Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' LIMIT 1];
    }

    private static List<Apttus__AgreementLineItem__c> getAgreementLineItem(Id agreementId) {
        return [SELECT Id, Name, Material_Group_1__c, Discount_Type__c, Apttus__AgreementId__c, Priority__c, Discount__c, Discount_In_Percent__c, Sales_Approval_Threshold__c, Discount_Beyond_Threshold__c FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c = :agreementId LIMIT 100];
    }

    private static List<Apttus_Approval__Approval_Request__c> getApprovalRequests(id agreementId) {
        return [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_Approval__Related_Agreement__c = :agreementId LIMIT 5];
    }
}