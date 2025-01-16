/*
*  @Author: Gerardo Garcia
*  @Date: 2023-11-10
*  @Description: Class for Territories2 implementation
*  Modification Log:
*  ---------------------------------------------------------------------------------------------------------------------------
*       Developer                       Date(YY-MM-DD)                  Description
*       Gerardo Garcia                  2023-11-10                      Initial Version CMCM-817
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class TestTradeInProducts {
    private static final String TEST_NAME = 'test';
    private static final String TEST_NAME_2 = 'test2';
    private static final String SALES_USERNAME = 'salesUserTester@test.com';
    private static final String COMM_USERNAME = 'commUserTester@test.com';

    /**
     * @author Gerardo Garcia
     * @description Enum for DML operation type
     */
    private enum DmlType {
        INSERT_TYPE,
        UPDATE_TYPE,
        DELETE_TYPE
    }

    @TestSetup
    static void makeData(){
        Map<String, String> profiles = TestDataUser.getProfilesIds(new Set<String> {TestDataUser.PROFILE_ADMIN, 
            TestDataUser.PROFILE_SALES_REP, 
            TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER});

        User admin = TestDataUser.initStandardUser(profiles.get(TestDataUser.PROFILE_ADMIN));
        admin.LastName = TestDataUser.PROFILE_ADMIN;
        admin.Email = 'tester.testos@illumina.com';

        User salesRep = TestDataUser.initStandardUser(profiles.get(TestDataUser.PROFILE_SALES_REP));
        salesRep.Username = SALES_USERNAME;

        User commOps = TestDataUser.initStandardUser(profiles.get(TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER));
        commOps.Username = COMM_USERNAME;

        insert new List<User> {admin, salesRep, commOps};

        System.runAs(admin) {
            Account acc = TestDataAccount.initAccount();
            acc.Name = TEST_NAME;
            insert acc;

            SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct(TEST_NAME, 'USD', 'New');
            SVMXC__Installed_Product__c ip2 = TestDataFieldService.createInstalledProduct(TEST_NAME_2, 'USD', 'New');
            insert new List<SVMXC__Installed_Product__c> {ip, ip2};

            Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
            insert priceList;

            Opportunity opp = TestDataOpportunity.initOpportunity(acc);
            opp.Name = TEST_NAME;
            opp.RecordTypeName__c = 'Direct';
            opp.Sold_to_Distribution_Channel__c = 'Direct';
            opp.Transborder_Flag__c = true;
            opp.Price_List__c = priceList.Name;
            opp.Type = System.Label.OpportunityTypeConsortium;
            insert opp;

            Apttus_Proposal__Proposal__c quote = TestDataProposal.initProposal(acc.id, opp.id, TEST_NAME, priceList.id, true, 'Draft', 'None');
            insert quote;

            Trade_In_Product__c tip = new Trade_In_Product__c(
                Account__c = acc.id,
                Installed_Product__c = ip2.id,
                Quote_Proposal__c = quote.id
            );
            insert tip;
        }
    }

    /** Quotation Stages: Draft -> Approval Required -> In review -> Approved -> Generated -> Presented -> Accepted -> Denied */
    /** Quotation_Stages_Edit_Sales: Draft, Approval Required */
    // TEST INSERT SALES REP
    @IsTest
    private static void insertInvalidStageProfileSalesRepExpectError() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, true);

        updateQuotationStage(data.quotation, 'In review');

        DmlType opType = DmlType.INSERT_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, true), 'Error Message does not match');
    }

    @IsTest
    private static void insertValidStageProfileSalesRepExpectSuccess() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, true);

        updateQuotationStage(data.quotation, 'Approval Required');

        DmlType opType = DmlType.INSERT_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }

    //TEST UPDATE SALES REP
    @IsTest
    private static void updateInvalidStageProfileSalesRepExpectError() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, false);

        updateQuotationStage(data.quotation, 'In review');

        DmlType opType = DmlType.UPDATE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, true), 'Error Message does not match');
    }

    @IsTest
    private static void updateValidStageProfileSalesRepExpectSuccess() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, false);

        updateQuotationStage(data.quotation, 'Approval Required');

        DmlType opType = DmlType.UPDATE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }

    //TEST UPDATE SALES REP
    @IsTest
    private static void deleteInvalidStageProfileSalesRepExpectError() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, false);

        updateQuotationStage(data.quotation, 'In review');

        DmlType opType = DmlType.DELETE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, true), 'Error Message does not match');
    }

    @IsTest
    private static void deleteValidStageProfileSalesRepExpectSuccess() {
        User salesRep = getUser(SALES_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(salesRep, false);

        updateQuotationStage(data.quotation, 'Approval Required');

        DmlType opType = DmlType.DELETE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }
    

    /** Quotation Stages: Draft -> Approval Required -> In review -> Approved -> Generated -> Presented -> Accepted -> Denied */
    /** Quotation_Stages_Edit_Commercial_Ops: Draft, Approval Required, In Review, Approved, Generated, Presented */
    // TEST INSERT Comm Op
    @IsTest
    private static void insertInvalidStageCommOpProfileExpectError() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, true);

        updateQuotationStage(data.quotation, 'Accepted');

        DmlType opType = DmlType.INSERT_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, false), 'Error Message does not match');
    }

    @IsTest
    private static void insertValidStageProfileCommOpExpectSuccess() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, true);

        updateQuotationStage(data.quotation, 'Presented');

        DmlType opType = DmlType.INSERT_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }

    //TEST UPDATE Comm Op
    @IsTest
    private static void updateInvalidStageProfileCommOpExpectError() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, false);

        updateQuotationStage(data.quotation, 'Accepted');

        DmlType opType = DmlType.UPDATE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, false), 'Error Message does not match');
    }

    @IsTest
    private static void updateValidStageProfileCommOpExpectSuccess() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, false);

        updateQuotationStage(data.quotation, 'Presented');

        DmlType opType = DmlType.UPDATE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }

    //TEST DELETE Comm Op
    @IsTest
    private static void deleteInvalidStageProfileCommOpExpectError() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, false);

        updateQuotationStage(data.quotation, 'Accepted');

        DmlType opType = DmlType.DELETE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isFalse(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should not be a success');
        Assert.isTrue(hasErrorMsg(res.errors, false), 'Error Message does not match');
    }

    @IsTest
    private static void deleteValidStageProfileCommOpExpectSuccess() {
        User commOp = getUser(COMM_USERNAME);

        // Setup data for given user.
        WrapperData data = setupData(commOp, false);

        updateQuotationStage(data.quotation, 'Presented');

        DmlType opType = DmlType.DELETE_TYPE;
        ResultDML res;
        Test.startTest();
        res = databaseOperation(opType, data.user, data.target, data);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, 'user:' + data.user.Username + ' dml:' + opType + ' should be a success');
    }

    private static ResultDML databaseOperation(DmlType operation, User user, Trade_In_Product__c target, WrapperData data) {
        ResultDML res;
        System.runAs(user) {
            printPermissions(data);
            switch on operation {
                when INSERT_TYPE {
                    res = new ResultDML(Database.insert(target, false));
                }
                when UPDATE_TYPE {
                    res = new ResultDML(Database.update(target, false));
                }
                when else {
                    res = new ResultDML(Database.delete(target, false));
                }
            }
        }
        System.debug('result database ' + operation + ': ' + JSON.serializePretty(res));
        return res;
    }

    private static WrapperData setupData(User user, Boolean isNew) {
        Account acc = getAccount();
        SVMXC__Installed_Product__c ip =  getInstalledProduct( isNew ? TEST_NAME : TEST_NAME_2);
        Apttus_Proposal__Proposal__c quotation = getQuotation();
        Opportunity op = getOpportunity();
        
        Trade_In_Product__c target;
        if(isNew) {
            target = new Trade_In_Product__c(
                Account__c = acc.id,
                Installed_Product__c = ip.id,
                Quote_Proposal__c = quotation.id
            );
        } else {
            target = getTradeIn(ip.id);
        }

        insert new TAPS_InstalledProducts().createSharingRecord(ip.id, user.id);
        insert new TAPS_ApttusProposals().createSharingRecord(quotation.id, user.id);
        insert new TAPS_Opportunity().createSharingRecord(op.id, user.id);

        WrapperData data = new WrapperData(acc, ip, quotation, op);
        data.user = user;
        data.target = target;
        return data;
    }

    private static void updateQuotationStage(Apttus_Proposal__Proposal__c quotation, String quotationStatus) {
        quotation.Apttus_Proposal__Approval_Stage__c = quotationStatus;
        update quotation;
    }

    private static void printPermissions(WrapperData data) {
        System.debug('ids:' + JSON.serializePretty(data));
        System.debug('hasSalesProfile:' + TradeInProducts.hasSalesProfile());
        System.debug('hasCommOpsProfile:' + TradeInProducts.hasCommOpsProfile());

        List<UserRecordAccess> lstUserRecordAccess = [SELECT RecordId,MaxAccessLevel,HasAllAccess, 
                                                        HasDeleteAccess, 
                                                        HasEditAccess,
                                                        HasReadAccess, 
                                                        HasTransferAccess 
                                                    FROM UserRecordAccess 
                                                    WHERE UserId = :UserInfo.getUserId()
                                                    AND RecordId IN :data.getIds()];
        System.debug('lstUserRecordAccess:' + JSON.serializePretty(lstUserRecordAccess));
    }

    private static Boolean hasErrorMsg(List<Database.Error> errors, Boolean isSalesUser) {
        System.debug('Errors:' + errors);
        String expectedErrorMsg = isSalesUser ? Label.TradeIn_Product_Sales_Profile_Validation_Error : Label.TradeIn_Product_CommOps_Profile_Validation_Error;
        for( Database.Error err : errors) {
            if(err.getMessage().contains(expectedErrorMsg)) {
                return true;
            }
        }
        return false;
    }

    private static Account getAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = :TEST_NAME LIMIT 1];
    }

    private static SVMXC__Installed_Product__c getInstalledProduct(String name) {
        return [SELECT Id FROM SVMXC__Installed_Product__c WHERE Name = :name LIMIT 1];
    }

    private static Apttus_Proposal__Proposal__c getQuotation() {
        return [SELECT Id FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c =:TEST_NAME LIMIT 1];
    }

    private static User getUser(String lastNameOrUsername) {
        return [SELECT Id, Username FROM User WHERE LastName = :lastNameOrUsername OR Username = :lastNameOrUsername LIMIT 1];
    }

    private static Opportunity getOpportunity() {
        return [SELECT Id FROM Opportunity WHERE Name =:TEST_NAME LIMIT 1];
    }

    private static Trade_In_Product__c getTradeIn(String productId) {
        return [SELECT Id FROM Trade_In_Product__c WHERE Installed_Product__c = :productId];
    }

    /**
     * Test data container
     */
    private class WrapperData {
        Account account;
        SVMXC__Installed_Product__c installedProduct;
        Apttus_Proposal__Proposal__c quotation;
        Opportunity opportunity;
        Trade_In_Product__c target;
        User user;

        /**Constructor */
        public WrapperData(Account account, SVMXC__Installed_Product__c installedProduct, 
            Apttus_Proposal__Proposal__c quotation, Opportunity opportunity) {
            this.account = account;
            this.installedProduct = installedProduct;
            this.quotation = quotation;
            this.opportunity = opportunity;
        }

        /**
         * Get a list of relevant ids from gathered data
         */
        public List<Id> getIds() {
            return new List<Id> {this.account.Id, this.installedProduct.id, this.quotation.id, this.opportunity.id};
        }
    }

    /**Class that Wraps results from Database.insert/update/delete */
    private class ResultDML {
        boolean isSuccess;
        Database.Error[] errors;

        /**Constructor */
        public ResultDML(Database.SaveResult res) {
            this.isSuccess = res.isSuccess();
            this.errors = res.getErrors();
        }

        /**Constructor */
        public ResultDML(Database.DeleteResult res) {
            this.isSuccess = res.isSuccess();
            this.errors = res.getErrors();
        }
    }
}