/*
* @Author: Rishab Wali
* @Date: 30-05-2020
* @Description : Test Class for Web Service Class for Async Call Real Time Pricing.
* --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * Rishab Wali              30-05-2020                  DCP-34910 Test Class for Web Service for Async call Real Time Pricing
 * Prabhsimran Singh        11-06-2020                  DCP-37888 Test Class for Web Service for Generate Async call Real Time Pricing
 * Bharath Varma            08-06-2022                  TASK0768041 - Added test method to cover the QtValidF and QtValidT population in RelatimepricingRequestDirectUC 
 * Saddam                   08-Dec-2022             Codescan Fix , Varaible naming convention. 
 * Jitesh Lakhwani          10-Jan-2023                 Codescan issues
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * 
*/
@isTest
public class TestRealTimePricingResponseReciever {

    public static final String PROMOTION_JSON = '[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
    public static String strLineItemNumber ='LI-0001';
    public static final String POSTURL = '/services/apexrest/ValidateAsyncInterface';
    public static final String HTTPPOST = 'Post';
    public static final String JSONREQPART1 = '{"d":{"__metadata":{},"Vbeln":"4139089","DocType":"ZQT","SalesOrg":"US01","DistrChan":"01","Division":"00","QtValidT":"/Date(1572048000000)/","QtValidF":"/Date(1538956800000)/","PriceList":"","HCurr":"USD","PriceDate":"/Date(1538956800000)/","PoMethod":"SFDC","ZzapQuot":"';
    public static final String JSONREQPART2 = '","Zzoppid":"0061D000003x8N3QAI","Incoterms1":"","ZzmyilmnEmail":"ppatil2@illumina.com","Zstatus":"","Pmnttrms":"NT00","OrdReason":"ZOP","UsageInd":"W_N","ZzpromoCode1":"","ZzpromoCode2":"","ZzpromoCode3":"","ZzpromoChannel1":"","ZzpromoChannel2":"","ZzpromoChannel3":"","Cstcndgrp2":"","ZdName":"Pradeep Patil","ZdTelephone":"7645682","ZdEmail":"ppatil2@illumina.com","FileContent":"","EvSalesDocument":"4139089","NAVHDRTOCND":{"results":[{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART3 = '","SapItmNumber":"000070","CondType":"YD04","CondValue":"100.000000000","Calctypcon":"N"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART4 = '","SapItmNumber":"000000","CondType":"YB02","CondValue":"0.000000000","Calctypcon":"N"}]},"NAVHDRTOITM":{"results":[{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART5 = '","SapItmNumber":"000070","Material":"15061065S","TargetQty":"1.000","BillFreq":"","ContractStart":"/Date(1538956800000)/","ContractEnd":"/Date(1570406400000)/","ReasonRej":"","Zzsoftwareid":"New - Subscription On Premise","Zzbundleid":"01t1D000001a46NQAQ","UnitPrice":"83,263.00","ExtendedValue":"83,263.00","SubtotPp4":"0.000000000","SubtotPp4Pu":"0.000000000","SubtotPp4Per":"0.00"}]},"NAVHDRTOPRT":{"results":[{"__metadata":{},"PartnRole":"SP","PartnNumb":"6000001937","ItmNumber":"000000","Name":"","Country":"","Telephone":""},{"__metadata":{},"PartnRole":"SE","PartnNumb":"4739","ItmNumber":"000000","Name":"","Country":"","Telephone":""}]},"NAVHDRTORET":{"results":[{"__metadata":{},"Type":"A","Message":"ORDER_HEADER_IN has been processed successfully"},{"__metadata":{},"Type":"S","Message":"ITEM_IN has been processed successfully"},{"__metadata":{},"Type":"S","Message":"SCHEDULE_IN has been processed successfully"},{"__metadata":{},"Type":"X","Message":"Quotation 4139089 has been saved"}]},"NAVHDRTOTXT":{"results":[{"__metadata":{},"TextId":"ZLQT","TextLine":"X|';
    public static final String JSONREQPART6 = '|validate","Langu":"EN"},{"__metadata":{},"TextId":"ZQ09","TextLine":"","Langu":"EN"},{"__metadata":{},"TextId":"ZQ19","TextLine":"","Langu":"EN"}]},"NAVHDRTOINP":{"__deferred":{}},"NAVHDRTOCFGSBLOB":{"__deferred":{}},"NAVHDRTOCFGSINST":{"__deferred":{}},"NAVHDRTOCFGSPARTOF":{"__deferred":{}},"NAVHDRTOCFGSREF":{"__deferred":{}},"NAVHDRTOCFGSREFINST":{"__deferred":{}},"NAVHDRTOCFGSVAL":{"__deferred":{}},"NAVHDRTOCFGSVK":{"__deferred":{}},"NAVHDRTOKEYS":{"__deferred":{}},"NAVHDRTOLOGSWT":{"__deferred":{}},"NAVHDRTOSENDER":{"__deferred":{}},"NAVHDRTOPARADD":{"__deferred":{}},"NAVHDRTOPARCNG":{"__deferred":{}},"NAVHDRTOGTSLOGS":{"results":[{"__metadata":{},"ItemNumber":"000010","ZzapPosnr":"';
    public static final String JSONREQPART7 = '","ServStah":"","QualStah":"","ServicText":"Embargo Check","ServStai":"LECEMB","QualStai":"EMB2","StatusText":"Released / Checked","CheckInd":"B"},{"__metadata":{},"ItemNumber":"000010","ZzapPosnr":"';
    public static final String JSONREQPART8 = '","ServStah":"","QualStah":"","ServicText":"Embargo Check","ServStai":"LECEMB","QualStai":"CON4B","StatusText":"Released / Checked","CheckInd":"B"},{"__metadata":{},"ItemNumber":"000010","ZzapPosnr":"';
    public static final String JSONREQPART9 = '","ServStah":"","QualStah":"","ServicText":"Embargo Check","ServStai":"LECEMB","QualStai":"SPL2","StatusText":"Released / Checked","CheckInd":"B"}]},"NAVHDRTOITEMCOND":{"results":[{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART10 = '","ItmNumber":"000070","KonvKschl":"ZPNP","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART11 = '","ItmNumber":"000070","KonvKschl":"ZFXP","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART12 = '","ItmNumber":"000070","KonvKschl":"ZB02","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART13 = '","ItmNumber":"000070","KonvKschl":"ZCNP","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART14 = '","ItmNumber":"000070","KonvKschl":"ZD10","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART15 = '","ItmNumber":"000070","KonvKschl":"ZDSK","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART16 = '","ItmNumber":"000070","KonvKschl":"YD04","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART17 = '","ItmNumber":"000070","KonvKschl":"ZL01","KonhKnumaPi":"","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"},{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART18 = '","ItmNumber":"000070","KonvKschl":"ZSIP","KonhKnumaPi":"NEWBEE","KonvKoaid":"","KonvKbetr":"83263.000","KonvKrech":"C","KonvKwert":"83263.000","Krate":"83263.000"}]},"NAVHDRTOEXP":{"results":[{"__metadata":{},"ZSubtotal":"83,263.00","ZTotalTax":"3,237.89","ZTotalFreight":"1,665.26","ZTotalDiscount":"0.00","ZOrderTotal":"88,166.15","ZTotalFreightDisc":"0.00","IsQuoteSuccess":"X","IsGtsSuccess":"X","IsAttachSuccess":""}]},"NAVHDRTOFAPIAO":{"results":[{"__metadata":{},"FapiaoTypeCode":"1","FapiaoTypeDesc":""},{"__metadata":{},"FapiaoTypeCode":"1","FapiaoTypeDesc":"上海增值税普通发票"}]},"NAVHDRTOCFGSREF":{"results":[{"__metadata":{},"ZzapPosnr":"';
    public static final String JSONREQPART19 = '","ConfigId":"1"}]},"NAVHDRTOCFGSINST":{"results":[{"__metadata":{},"InstId":"1","ConfigId":"1"}]},"NAVHDRTOCFGSVAL":{"results":[{"__metadata":{},"Value":"1234","InstId":"1","Charc":"PRODUCTNAME","ConfigId":"1"}]}}}';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getNewAccount();
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '123456';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.BillingCountryCode = 'US';
        acc4.BillingStateCode = 'AK';
        acc4.ERP_Customer_Id__c = '567891';
        acc4.Account_Group__c = 'Sold To';
        //Fapiao
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '6000022795';
        acc5.Account_Group__c = 'Sold To';

        
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        lstAcc.add(acc4);
        lstAcc.add(acc5);
        insert lstAcc;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc2.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc3.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = 'US01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};
        // DCP-25908 : Payment term
        Account_Relationship__c objSoldToPayer = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Gryffy',
                                                                            Relationship__c=Label.AccountGroupPayer,
                                                                            Account_Sales_Area__c=acc2SalesArea.Id);
        insert objSoldToPayer;
        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        List<Customer_Master_Data__c> lstCMD = new List<Customer_Master_Data__c>();
        lstCMD.add(objCMDUC);
        lstCMD.add(objCMDSoldTo);
        lstCMD.add(objCMDDist);
        insert lstCMD;
        Contact con = TestDataPerson.getNewContact(acc.Id);
        con.email = 'axs@scs.com';

        System.debug('contss-'+con);

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        opp2.Price_List__c = priceList.Name;
        opp2.Consortium__c = consortium.Id;
        opp2.Type = 'Consortium';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstopp.add(opp2);

        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc2.Id;
        opp3.Distributor__c = acc3.Id;
        opp3.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp3.Are_Products_Added_by_Channel_Partner__c = true;
        lstopp.add(opp3);

        Opportunity opp5 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp5);
        insert lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Promotion_JSON__c=PROMOTION_JSON;
        //Proposal.Apttus_QPConfig__BillToAccountId__c = objCMDUC.id;
        Proposal.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Promotion_JSON__c=PROMOTION_JSON;
        Proposal2.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal2);

        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc2.id, opp3.id, 'Test Proposal3', priceList.id, true, 'Draft', 'None');
        proposal3.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal3.Apttus_Proposal__Proposal_Name__c = 'Test Proposal3';
        proposal3.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal3.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal3);

        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc5.id, opp5.id, 'Test Proposal4', priceList.id, true, 'Draft', 'None');
        proposal4.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal4.Apttus_Proposal__Proposal_Name__c = 'Test Proposal4';
        proposal4.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal4.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal4);

        insert lstProp;
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method to check Response success
    */
    @isTest
    public static void testResponseReceiverSuccess()
    {
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name,Validation_In_Progress__c from Apttus_Proposal__Proposal__c][0];
        
        Test.startTest();
        objQuotation.Validation_In_Progress__c = true;
        
        update objQuotation;
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = TestDataProposal.getNewCart(objQuotation);
        objProductConfig.Validation_Number__c = 1;
        update objProductConfig;
        
        String stringReq = createJSON(objQuotation.Id,objQuotation.Name,objProductConfig.Id,String.valueOf(0));
        
        RestRequest req = new RestRequest();
		req.httpMethod = HTTPPOST;
		req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(StringReq);

        RestContext.request = req;
        RealTimePricingResponseReciever.updateCart();
        test.stopTest();
        System.assert(!String.isBlank(RestContext.request.requestBody.toString()), 'Rest Body is not null');
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method to check outdated Response Scenario
    */
    @isTest
    public static void testOutdatedResponseScenario()
    {
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name from Apttus_Proposal__Proposal__c][0];
        
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objProductConfig = TestDataProposal.getNewCart(objQuotation);
        objProductConfig.Validation_Number__c = 1;
        
        update objProductConfig;
        
        String stringReq = createJSON(objQuotation.Id,objQuotation.Name,objProductConfig.Id,String.valueOf(objProductConfig.Validation_Number__c));
        
        RestRequest req = new RestRequest();
		req.httpMethod = HTTPPOST;
		req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(StringReq);

        RestContext.request = req;
        RealTimePricingResponseReciever.updateCart();
        test.stopTest();
        System.assert(!String.isBlank(RestContext.request.requestBody.toString()), 'Rest Body is not empty');
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method to check exception
    */
    @isTest
    public static void testExceptionAsync()
    {
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name from Apttus_Proposal__Proposal__c][0];
        
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objProductConfig = TestDataProposal.getNewCart(objQuotation);
        objProductConfig.Validation_Number__c = 1;
        
        update objProductConfig;
        
        String stringReq = createJSON(objQuotation.Id,objQuotation.Name,objProductConfig.Id,'a');
        
        RestRequest req = new RestRequest();
		req.httpMethod = HTTPPOST;
		req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(StringReq);

        RestContext.request = req;
        RealTimePricingResponseReciever.updateCart();
        test.stopTest();
        System.assert(!String.isBlank(RestContext.request.requestBody.toString()), 'Rest Body is not Empty');
    }

    private static String createJSON(Id objQuotationId , String objQuotationName ,Id objProductConfigId , String valNum)
    {
        return JSONREQPART1 + objQuotationName + JSONREQPART2 + strLineItemNumber + JSONREQPART3 + strLineItemNumber + JSONREQPART4 + strLineItemNumber + JSONREQPART5 + valNum + '-'+ objProductConfigId+'*'+objQuotationId + JSONREQPART6 + strLineItemNumber + JSONREQPART7 +strLineItemNumber + JSONREQPART8 + strLineItemNumber + JSONREQPART9 + strLineItemNumber + JSONREQPART10 + strLineItemNumber + JSONREQPART11 + strLineItemNumber + JSONREQPART12 + strLineItemNumber + JSONREQPART13 + strLineItemNumber + JSONREQPART14 + strLineItemNumber + JSONREQPART15 + strLineItemNumber + JSONREQPART16 + strLineItemNumber + JSONREQPART17 + strLineItemNumber + JSONREQPART18 + strLineItemNumber + JSONREQPART19 ;        
    }
    /*
    *@author: Rishab Wali
    *@Desc: Test method  for generate large cart response.
    */
    @isTest
    public static void testGenerateAsyncResponse()
    {
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name,generate_in_progress__c,Last_Validation_Id__c from Apttus_Proposal__Proposal__c][0];
        
        Test.startTest();        
        objQuotation.Last_Validation_Id__c = 1;
        objQuotation.generate_in_progress__c = true;
        
        update objQuotation;
        
        String stringReq = '{"d":{"__metadata":{},"Vbeln":"4269239","DocType":"ZQT","SalesOrg":"US01","DistrChan":"01","Division":"00","QtValidT":"/Date(1594425600000)/","QtValidF":"/Date(1591660800000)/","PriceList":"01","HCurr":"USD","PriceDate":"/Date(1591660800000)/","PoMethod":"SFDC","ZzapQuot":"'+objQuotation.Name+'"';
        stringReq += ',"Zzoppid":"0062i000003DX6XAAW","Incoterms1":"DDP","Incoterms2":"Customer Door","ZzmyilmnEmail":"","Zstatus":"Approved","Pmnttrms":"NT30","OrdReason":"ZOP","UsageInd":"W_Y","ZzpromoCode1":"","ZzpromoCode2":"","ZzpromoCode3":"","ZzpromoChannel1":"","ZzpromoChannel2":"","ZzpromoChannel3":"","Cstcndgrp2":"","CustGrp2":"","RefDocL":"","ZdName":"Rishab Wali","ZdTelephone":"7889485492","ZdEmail":"","PguidPurch":"","FileContent":"","EvSalesDocument":"4269239",';
        stringReq += '"NAVHDRTOEXP":{"results":[{"__metadata":{"id":"","uri":"https://","type":"ZQ2C_INT_QUOTE_CONV_SRV.EXPORT"},"ZSubtotal":"","ZTotalTax":"","ZTotalFreight":"","ZTotalDiscount":"","ZOrderTotal":"","ZTotalFreightDisc":"","IsQuoteSuccess":"","IsGtsSuccess":"","IsAttachSuccess":""}]},';
        stringReq += '"NAVHDRTOFAPIAO":{"results":[{"__metadata":{"id":"","uri":"https://","type":"ZQ2C_INT_QUOTE_CONV_SRV.IT_FAPIAO_DETAILS"},"FapiaoTypeCode":"","FapiaoTypeDesc":""}]},';
        stringReq += '"NAVHDRTOGTSLOGS":null,';
        stringReq += '"NAVHDRTOTXT":{"results":[{"__metadata":{"id":"","uri":"","type":"ZQ2C_INT_QUOTE_CONV_SRV.IT_QUOTATION_TEXT"},"TextId":"ZQ09","TextLine":"","Langu":"EN"},{"__metadata":{"id":"","uri":"","type":"ZQ2C_INT_QUOTE_CONV_SRV.IT_QUOTATION_TEXT"},"TextId":"ZLQT","TextLine":"X|0-'+objQuotation.Id+'|generate","Langu":"EN"},{"__metadata":{"id":"","uri":"","type":"ZQ2C_INT_QUOTE_CONV_SRV.IT_QUOTATION_TEXT"},"TextId":"ZQ19","TextLine":"","Langu":"EN"},{"__metadata":{"id":"","uri":"","type":"ZQ2C_INT_QUOTE_CONV_SRV.IT_QUOTATION_TEXT"},"TextId":"ZPPM","TextLine":"","Langu":"EN"}]}}}';
        RestRequest req = new RestRequest();
		req.httpMethod = 'POST';
		req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/ValidateAsyncInterface';
        req.requestBody = Blob.valueOf(stringReq);

        RestContext.request = req;
        RealTimePricingResponseReciever.updateCart();
        test.stopTest();
        System.assert(!String.isBlank(RestContext.request.requestBody.toString()), 'Rest Body is not empty');
    }
    
    /*
    *@author: Rishab Wali
    *@Desc: Test method  to cover the QtValidF and QtValidT population in RelatimepricingRequestDirectUC
    */
    @isTest
    public static void testValidFromAndToDirectUC(){
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id,Name,Validation_In_Progress__c from Apttus_Proposal__Proposal__c][0];
        
        Test.startTest();
        // When both start date and end date are null
        objQuotation.Apttus_Proposal__ExpectedStartDate__c = null;
        objQuotation.Apttus_Proposal__ExpectedEndDate__c = null;
        update objQuotation;
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = TestDataProposal.getNewCart(objQuotation);
        objProductConfig.Validation_Number__c = 1;
        update objProductConfig;

        set<id> setConfigIds = new Set<id>{objProductConfig.Id};
        Apttus_Config2__ProductConfiguration__c objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];
        List<Apttus_Config2__LineItem__c> lstLineItems = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id>{objConfiguration.id}); //INC0321438
            
        String rtpRequest = RealtimePricingRequestDirectUC.createJSONForDirectUC(objConfiguration, lstLineItems);
        // Test class Fix
        new LineItemWrapper(new Apttus_Config2__LineItem__c());
        RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper rtpRequestJSON = (RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper) JSON.deserialize(rtpRequest, RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper.class);
        System.assertEquals(rtpRequestJSON.QtValidF,rtpRequestJSON.QtValidT, 'From Date and To Date are not equal');

        // when start date is not null and end date is null
        objQuotation.Apttus_Proposal__ExpectedStartDate__c = System.Today();
        objQuotation.Apttus_Proposal__ExpectedEndDate__c = null;
        update objQuotation;

        objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];

        rtpRequest = RealtimePricingRequestDirectUC.createJSONForDirectUC(objConfiguration, lstLineItems);
        rtpRequestJSON = (RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper) JSON.deserialize(rtpRequest, RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper.class);
        System.assertEquals(rtpRequestJSON.QtValidF, rtpRequestJSON.QtValidT, 'From Date and To Date are not equal');

        // when start date is null and end date is not null
        objQuotation.Apttus_Proposal__ExpectedStartDate__c = null;
        objQuotation.Apttus_Proposal__ExpectedEndDate__c = System.Today();
        update objQuotation;

        objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];

        rtpRequest = RealtimePricingRequestDirectUC.createJSONForDirectUC(objConfiguration, lstLineItems);
        rtpRequestJSON = (RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper) JSON.deserialize(rtpRequest, RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper.class);
        System.assertEquals(rtpRequestJSON.QtValidF,rtpRequestJSON.QtValidT, 'From Date and To Date are not equal');

        // when start date and end date are not null
        objQuotation.Apttus_Proposal__ExpectedStartDate__c = System.Today();
        objQuotation.Apttus_Proposal__ExpectedEndDate__c = System.Today()+1;
        update objQuotation;

        objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];

        rtpRequest = RealtimePricingRequestDirectUC.createJSONForDirectUC(objConfiguration, lstLineItems);
        rtpRequestJSON = (RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper) JSON.deserialize(rtpRequest, RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper.class);
        Datetime today = (Datetime)System.today();
        Datetime tomorrow = (Datetime)(System.today() + 1);
        System.assertEquals('\\'+'/Date(' + today.getTime() + ')'+'\\'+'/', rtpRequestJSON.QtValidF, 'From Date is not populated as expected');
        System.assertEquals('\\'+'/Date(' + tomorrow.getTime() + ')'+'\\'+'/', rtpRequestJSON.QtValidT, 'To Date is not populated as expected');

        test.stopTest();

    }
}