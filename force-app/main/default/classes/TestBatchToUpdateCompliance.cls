/**
*    @author Gopi
*    @date   2023-08-01
*    @description  BatchToUpdateCompliance test class.
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Gopi                        01 Aug 2023            BatchToUpdateCompliance test class
*             Gerardo                     17 Aug 2023            Add additional cases for test
*             Gerardo                     15 Nov 2023            Modify tests to be independent from today and period values.
*    ----------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestBatchToUpdateCompliance{

    private static final String OPP_NAME1 = 'opp1';
    private static final String OPP_NAME2 = 'opp2';
    private static final String OPP_NAME3 = 'opp3';
    private static final String OPP_NAME4 = 'opp4';
    private static final User SYS_ADMIN = TestDataUser.findUserInProfile('System Administrator');
    
    private static final List<String> LST_OF_LASTMOD_STAGES = Code_Parameter__mdt.getInstance('Opp_Last_Mod_Noncompliance_Stages').Value__c.split(';'); //(Qualify, Develop, Prove, Negotiate & Resolve, Finalize)
    private static final List<String> LST_OF_NOREVRECTERM_STAGES = Code_Parameter__mdt.getInstance('Opp_No_RevRec_Noncompliance_Stages').Value__c.split(';'); //(Prove, Negotiate & Resolve, Finalize)

    public static Date today = Date.newInstance(2023, 11, 15);
    public static List<Period> periodRecs = getPeriods(
        Date.newInstance(2023, 10, 02), Date.newInstance(2023, 12, 31),
        Date.newInstance(2024, 01, 01), Date.newInstance(2024, 03, 31),
        Date.newInstance(2024, 04, 01), Date.newInstance(2024, 06, 30)
    );

    @testSetup
    private static void setup() {
        Account acc1 = TestDataAccount.getAccount('Territory Account');
        acc1.Territory_Region__c = 'China';
        acc1.ERP_Customer_Id__c = '123456';
        acc1.OwnerId = UserInfo.getUserId();
        insert acc1; 

        System.debug('===Periods:' + periodRecs);
        System.debug('===today:' + today);

        Period firstPeriod = periodRecs[0];
        Period seconPeriod = periodRecs[1];

        System.runAs(SYS_ADMIN) {
            List<Opportunity> lstOpp = new List<Opportunity>();

            //LMD_CDP_NRRT
            Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
            opp1.Name = OPP_NAME1;
            opp1.Transborder_Flag__c = true;
            opp1.Distributor__r = acc1; 
            opp1.Product_Type__c = 'Instrument';
            opp1.Rev_Rec_Terms__c = '';
            opp1.StageName = 'Prove';
            opp1.Compliance_Last_Modified_Date__c = today.addDays(-1 * Integer.valueOf(System.Label.Opp14DaysDue));
            opp1.CloseDate = today.addDays(-5);
            lstOpp.add(opp1);
            
            //LMD_CDP
            Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
            opp2.Name = OPP_NAME2;
            opp2.Transborder_Flag__c = true;
            opp2.Distributor__r = acc1; 
            opp2.Product_Type__c = 'Instrument';
            opp2.Rev_Rec_Terms__c = '';
            opp2.StageName = 'Develop';
            opp2.Compliance_Last_Modified_Date__c = today.addDays(-1 * Integer.valueOf(System.Label.Opp14DaysDue));
            opp2.CloseDate = today.addDays(-5);
            lstOpp.add(opp2);
            
            //LMD
            Opportunity opp3 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
            opp3.Name = OPP_NAME3;
            opp3.Transborder_Flag__c = true;
            opp3.Distributor__r = acc1; 
            opp3.Product_Type__c = 'Instrument';
            opp3.Rev_Rec_Terms__c = 'ACD: Acceptance Upon Delivery';
            opp3.StageName = 'Prove';
            opp3.Compliance_Last_Modified_Date__c = today.addDays(-1 * Integer.valueOf(System.Label.Opp30DaysDue));
            opp3.CloseDate = seconPeriod.StartDate.addDays(5);
            lstOpp.add(opp3);

            //Already have expected result, no changes required
            Opportunity opp4 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
            opp4.Name = OPP_NAME4;
            opp4.Transborder_Flag__c = true;
            opp4.Distributor__r = acc1; 
            opp4.Product_Type__c = 'Instrument';
            opp4.Rev_Rec_Terms__c = '';
            opp4.StageName = 'Prove';
            opp4.Compliance_Last_Modified_Date__c = today.addDays(-1 * Integer.valueOf(System.Label.Opp14DaysDue));
            opp4.CloseDate = firstPeriod.StartDate.addDays(5);
            opp4.Non_Compliance_Reason__c = 'Last Modified Date;Close Date in the Past;No Rev Rec Terms';
            lstOpp.add(opp4);

            insert lstOpp;
        }
    }

    static testMethod void testBatch(){

        Test.startTest();
            BatchToUpdateCompliance objBatch = new BatchToUpdateCompliance();
            Database.executeBatch(objBatch); 
        Test.stopTest(); 
        
        Opportunity opp = getOpportunity(OPP_NAME1);
        logOpportunity(opp);
        Assert.areEqual('Last Modified Date;Close Date in the Past;No Rev Rec Terms', opp.Non_Compliance_Reason__c ,'Compliance reason not populated!');
    }

    @IsTest
    private static void verifyFillComplianceLastModifiedDateWhileIsNull() {
        // For historical opportunities that still having null value in ComplianceLastModifiedDate it should have value after run batch.
        Opportunity opp = getOpportunity(OPP_NAME1);
        opp.Compliance_Last_Modified_Date__c = null;
        opp.Non_Compliance_Reason__c = 'Close Date in the Past;No Rev Rec Terms';
        update opp;

        Opportunity res;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                res = BatchToUpdateCompliance.fillComplianceInOpportunity(LST_OF_LASTMOD_STAGES, LST_OF_NOREVRECTERM_STAGES, periodRecs, opp);
            }
        Test.stopTest(); 

        logOpportunity(res);

        Assert.isNotNull(res ,'You should get a result Opportunity!.');
        Assert.areEqual(opp.LastModifiedDate, res.Compliance_Last_Modified_Date__c ,'Compliance_Last_Modified_Date__c should be filled with Last Modified Date!');
    }

    @IsTest
    private static void testFillComplianceInOpportunityLMDandCDPandNRRT() {

        Opportunity opp = getOpportunity(OPP_NAME1);

        Opportunity res;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                res = BatchToUpdateCompliance.fillComplianceInOpportunity(LST_OF_LASTMOD_STAGES, LST_OF_NOREVRECTERM_STAGES, periodRecs, opp);
            }
        Test.stopTest(); 

        logOpportunity(res);

        Assert.areEqual('Last Modified Date;Close Date in the Past;No Rev Rec Terms', res.Non_Compliance_Reason__c ,'Compliance reason not populated!');
    }

    @IsTest
    private static void testFillComplianceInOpportunityLMDandCDP() {

        Opportunity opp = getOpportunity(OPP_NAME2);

        Opportunity res;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                res = BatchToUpdateCompliance.fillComplianceInOpportunity(LST_OF_LASTMOD_STAGES, LST_OF_NOREVRECTERM_STAGES, periodRecs, opp);
            }
        Test.stopTest(); 
        
        logOpportunity(res);

        Assert.areEqual('Last Modified Date;Close Date in the Past', res.Non_Compliance_Reason__c ,'Compliance reason not populated!');
    }

    @IsTest
    private static void testFillComplianceInOpportunityLMD() {

        Opportunity opp = getOpportunity(OPP_NAME3);

        Opportunity res;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                res = BatchToUpdateCompliance.fillComplianceInOpportunity(LST_OF_LASTMOD_STAGES, LST_OF_NOREVRECTERM_STAGES, periodRecs, opp);
            }
        Test.stopTest();

        logOpportunity(res);

        Assert.areEqual('Last Modified Date', res.Non_Compliance_Reason__c ,'Compliance reason not populated!');
    }

    @IsTest
    private static void testFillComplianceInOpportunityShouldBeNull() {

        Opportunity opp = getOpportunity(OPP_NAME4);

        Opportunity res;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                res = BatchToUpdateCompliance.fillComplianceInOpportunity(LST_OF_LASTMOD_STAGES, LST_OF_NOREVRECTERM_STAGES, periodRecs, opp);
            }
        Test.stopTest();

        Assert.areEqual(null, res ,'Should get null');
    }

    @IsTest
    private static void testUpdateOppsByIds(){
        Opportunity opp = getOpportunity(OPP_NAME1);
        List<String> opps =  new List<String> {opp.id};

        List<Opportunity> results;
        Test.startTest();
            System.runAs(SYS_ADMIN) {
                results = BatchToUpdateCompliance.updateOppsByIds(opps);
            }
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 updated opportunity');
    }

    private static Opportunity getOpportunity(String name) {
        Opportunity opp = [SELECT Id,Compliance_Last_Modified_Date__c,StageName, Amount_USD__c,Rev_Rec_Terms__c,Product_Type__c,LastModifiedDate,CloseDate,Non_Compliance_Reason__c FROM Opportunity WHERE Name = :name LIMIT 1];
        return opp;
    }

    private static void  logOpportunity(Opportunity res) {
        System.debug('Product_Type__c - ' + res.Product_Type__c + ' Rev_Rec_Terms__c - ' + res.Rev_Rec_Terms__c);
        System.debug('opp.Non_Compliance_Reason__c - ' + res.Non_Compliance_Reason__c);
    }

    private static List<Period> getPeriods(Date st1st, Date end1st, Date st2nd, Date end2nd, Date st3rd, Date end3rd) {
        return new List<Period> { new Period(QuarterLabel = 'Q(4) FY 2023', StartDate = st1st, EndDate = end1st),
            new Period(QuarterLabel = 'Q(1) FY 2024', StartDate = st2nd, EndDate = end2nd),
            new Period(QuarterLabel = 'Q(2) FY 2024', StartDate = st3rd, EndDate = end3rd)
        };
    }

}