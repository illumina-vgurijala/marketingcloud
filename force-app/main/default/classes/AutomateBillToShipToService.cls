/**
 * @author Akshay Mohan 
 * @date   12-Sep-2018
 * @description    Class to handle defaulting of Bill to and Ship to on a quote
 * 90% code coverage : TestApttusApprovals, TestApttusAssetLineItems, TestApttusCartErrorPageController, TestApttusCheckCatalystDiscount, TestApttusGetPromotionsController, 
                       TestApttusMobileCreateQuote, TestApttusOrderLineItems, TestApttusPreviewQuotationsAndApprovals,
                       TestApttusTerminateAssetRenewals, TestApttusValidationCallback, TestAutomateBillToShipToService, TestConsortiumAccounts
 * 75% code coverage : TestApttusApprovals, TestApttusAssetLineItems, TestApttusCartErrorPageController, TestApttusCheckCatalystDiscount, TestApttusGetPromotionsController, 
                       TestApttusMobileCreateQuote, TestApttusOrderLineItems, TestApttusPreviewQuotationsAndApprovals,
                       TestApttusTerminateAssetRenewals, TestApttusValidationCallback, TestAutomateBillToShipToService, TestConsortiumAccounts                      
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Akshay Mohan             12-Sep-2018         Original
*   Rahul Sharma             18-Sep-2018         Changed setProposalValue To Public
*   Rahul Sharma             25-Sep-2018         Modified idToProposal To return map
*   Akshay Mohan             26-Sep-2018         Sales Area logic change for defaulting
*   Rahul Sharma             29-Nov-2018         Incoterms1 defaulting for Ship To Selection
*   Akshay Mohan             09-Apr-2018         DCP-24588 Allow search for payers
*   Govind Dubey             06-Aug-2019         INC0196974 set quote's payment terms from payer rather than bill to
*   Roopal Verma             08-Nov-2018         DCP-28541 Default Bill To/ Ship To
*      KD                    29-June-2021        DCP-46226 : Payment term defaulting for Greater china.
*   Nishan Shetty            22-April-2022       CodeScan Fix:Avoid Literals in If condition
*   Aman Tyagi               5-Apri-2022         CodeScan Fixes   
*   Bharath Varma            18-May-2022         INC0395756 - Added logic to populate Incoterm value based on Ship To's Sales Area 
*   Iram Malik               14-Jul-2022         Codescan Fixes
*   Biswajeet Sahoo          29-Aug-2022         [CMSI-201] Instrumentation of code
*   Prem Ranjan              20-Feb-2023         CodeScan Fixes (APEX) Variable Naming Conventions
*-----------------------------------------------------------------------------------          
*/
public class AutomateBillToShipToService {
    private static Set<String> setPaymentDefaultCountryBreakFix = new Set<String>{'China','Macau','Taiwan','Hong Kong'};
    private static Set<String> setPaymentDefaultCountryRelocation = new Set<String>{'Macau','Taiwan','Hong Kong'};
    private static final String PAYMENT_TERM_FIELDAPI = 'Apttus_Proposal__Payment_Term__c';
    public static final String PAYMENT_TERM_NT00 = 'NT00';
    public static final String PAYMENT_TERM_PP00 = 'PP00';
    
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final Integer INTEGER_TWO = 2;
    private static final String LOG_TITLE = 'AutomateBillToShipToService';    //CMSI-201
    //End CodeScan Fix


    public static final String PAYER = 'Payer__c';
    public static final String BILL_TO= 'Bill_To__c';
    /** 
     *  @author Akshay Mohan 
     *  @description Update the Quotes based on of Ultimate Consignee(Ship To) and Account(Bill To) 
     *  @param Map<String,List<Apttus_Proposal__Proposal__c>> soldToERPIdToProposal
     *  @param Map<String,List<Apttus_Proposal__Proposal__c>> ucERPIdToProposal
     *  @return List<Apttus_Proposal__Proposal__c>
     **/
    public static Map<Id,Apttus_Proposal__Proposal__c> setBillToShipTo(Map<String,List<Apttus_Proposal__Proposal__c>> soldToERPIdToProposal,
                                                                      Map<String,List<Apttus_Proposal__Proposal__c>> ucERPIdToProposal,
                                                                      Map<String,List<Account_Sales_Area__c>> ucERPToDistSalesArea,
                                                                      Map<String,String> soldToERPToSAERP,
                                                                      Map<String,String> ucERPToSAERP,
                                                                      Map<String,String> accountERPToCountry,
                                                                      Map<Id, Opportunity> mapIdToOpportunity)
    {
        ilib_LogEvent.push(LOG_TITLE+'.setBillToShipTo()');           //CMSI-201

        //store consolidated Account Ids
        Set<String> setAccountKeys = new Set<String>();
        Set<String> setDirectRecordTypes = new Set<String>{Label.OpportunityRTDirectFieldServices,
                                                            Label.OpportunityRTDirectReOrder,
                                                            Label.OpportunityRTDirectStandard};
        setAccountKeys.addAll(soldToERPIdToProposal.keySet());
        setAccountKeys.addAll(ucERPIdToProposal.keySet());
        ilib_LogEvent.info('setAccountKeys: ' + setAccountKeys);            //CMSI-201
        ilib_LogEvent.info('soldToERPToSAERP: ' + soldToERPToSAERP);        //CMSI-201
        ilib_LogEvent.info('ucERPToSAERP: ' + ucERPToSAERP);                //CMSI-201
        String incoTerm1;

        //ideally this should never happen but just checking for safety and avoiding extra SOQL if some unkown scenario comes
        if (setAccountKeys.isEmpty())
        {
            ilib_LogEvent.pop();
            return null;
        }

        List<String> lstRelations = new List<String>();
        if(!soldToERPIdToProposal.keySet().isEmpty()){
            lstRelations.add(Label.AccountRelationshipBillTo);
            lstRelations.add(CustomerMasterDatas.GROUP_PAYER);
        }
        if(!ucERPIdToProposal.keySet().isEmpty())
            lstRelations.add(Label.AccountRelationshipShipTo);
        ilib_LogEvent.info('lstRelations: ' + lstRelations);           //CMSI-201
        //Map to store the field name with value
        Map<String,Object> keyToValue;
        Map<String,Object> keyToNull; 
        Map<Id,Apttus_Proposal__Proposal__c> idToProposal = new Map<Id,Apttus_Proposal__Proposal__c>();
        
    
        Map<String, List<Account_Relationship__c>> soldToERPIdToRelationship = new Map<String, List<Account_Relationship__c>>(),
                                                  ucERPIdToRelationship = new Map<String, List<Account_Relationship__c>>(),
                                                  soldToERPToDefaultRel = new Map<String, List<Account_Relationship__c>>(),
                                                  ucERPIdToDefaultRel = new Map<String, List<Account_Relationship__c>>();             // DCP-28541 : Added to store default relationships
        Map<String,String> soldToERPToPayerERP = new Map<String,String>(),
            payerERPToCMDId = new Map<String,String>();
        Map<String, List<Apttus_Proposal__Proposal__c>> erpASAToProposals = new Map<String, List<Apttus_Proposal__Proposal__c>>();

        // loop through account relationships given some IDs and relationship types
        for (Account_Relationship__c objRelationship :
            new AccountRelationshipsSelector().selectByAccountIdRelationship(setAccountKeys, lstRelations)
        ) {
            // in loop for one relationship

            String strERPIdAccount = objRelationship.ERP_Customer_Id__c, // sold to account ERP
                strASAERP = soldToERPToSAERP.get(strERPIdAccount); // sold to sales area ERP
            ilib_LogEvent.message('Sold To strASAERP' + strASAERP);

            // this relationship is in the same sales area as the opportunity's sold to
            Boolean booIsTransactionSalesArea = (strASAERP == objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c);

            // IF this rel is a payer
            // this rel is in the same sales area as the opportunity's sold to
            // this rel sold to has proposals
            //DCP-24588: if relationship is Payer and it is in the Sold To change map
            if (soldToERPIdToProposal.containsKey(strERPIdAccount)
                    && booIsTransactionSalesArea
                    && CustomerMasterDatas.GROUP_PAYER.equals(objRelationship.Relationship__c))
            {
                for (Apttus_Proposal__Proposal__c objProposal : soldToERPIdToProposal.get(strERPIdAccount))
                {

                    // if this sold to is acting as a payer, set the payer value
                    if (objRelationship.ERP_Customer_Id__c == objRelationship.Related_ERP_Customer_Id__c)
                    {
                        ilib_LogEvent.message('set payer 1 ' + objRelationship.Account_Sales_Area__r.Customer_Master_Data__r.Id);
                        setProposalValue(idToProposal, objProposal, PAYER, objRelationship.Account_Sales_Area__r.Customer_Master_Data__r.Id);
                        // SET PAYMENT TERM on each quote
                        // DCP-46226
                        setProposalValue(idToProposal, objProposal, PAYMENT_TERM_FIELDAPI,getPaymentTermOverride(mapIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c),objRelationship.Account_Sales_Area__r.Term_Of_Payment__c));
                    }

                    // if sold to is not the payer
                    // keep a map of sold to to payer for later
                    if (objRelationship.ERP_Customer_Id__c != objRelationship.Related_ERP_Customer_Id__c)
                    {
                        soldToERPToPayerERP.put(strERPIdAccount, objRelationship.Related_ERP_Customer_Id__c);
                        String asaKey = objRelationship.Related_ERP_Customer_Id__c + '_' + getSalesAreaFromERP(objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c);
                        if (erpASAToProposals.containsKey(asaKey))
                            erpASAToProposals.get(asaKey).add(objProposal);     
                        else    
                            erpASAToProposals.put(asaKey, new List<Apttus_Proposal__Proposal__c> {objProposal} );
                    }
                }
            }

            // build map of sold to ERP to Bill To relationships
            // if this rel is in the same sales area as the opportunity's sold to
            // if relationship is Bill To and it is in the Sold To change map
            if (soldToERPIdToProposal.containsKey(strERPIdAccount) && booIsTransactionSalesArea
                    && Label.AccountRelationshipBillTo.equals(objRelationship.Relationship__c))
            {
                if (soldToERPIdToRelationship.containsKey(strERPIdAccount))
                    soldToERPIdToRelationship.get(strERPIdAccount).add(objRelationship);
                else
                    soldToERPIdToRelationship.put(strERPIdAccount, new List<Account_Relationship__c>{objRelationship});
				if (objRelationship.Default_Partner__c == true){        //DCP-28541 : To store default relationship
                    if(soldToERPToDefaultRel.containsKey(strERPIdAccount))
                        soldToERPToDefaultRel.get(strERPIdAccount).add(objRelationship);
                    else
                        soldToERPToDefaultRel.put(strERPIdAccount, new List<Account_Relationship__c>{objRelationship});   
                }
            }

            // now we are considering the UC ERP
            strASAERP = ucERPToSAERP.get(strERPIdAccount);
            // this relationship is in the same sales area as the opportunity's sold to
            booIsTransactionSalesArea = strASAERP == objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
            ilib_LogEvent.message('UC strASAERP'+strASAERP);

            // if this rel is ship to
            // and this relationship is in the same sales area as the opportunity's sold to
            // and this UC ERP is in the map of changed values (for indirect I think)
            // if relationship is Ship To and it is in the UC change map
            if (ucERPIdToProposal.containsKey(strERPIdAccount)
                    && booIsTransactionSalesArea
                    && Label.AccountRelationshipShipTo.equals(objRelationship.Relationship__c))
            {
                // set incoterm
                incoTerm1 = objRelationship.Account_Sales_Area__r.Inco_Term_1__c;
                ilib_LogEvent.message('incoTerm1: '+incoTerm1);

                // build map of UC ERP to relationships
                if (ucERPIdToRelationship.containsKey(strERPIdAccount))
                    ucERPIdToRelationship.get(strERPIdAccount).add(objRelationship);
                else
                    ucERPIdToRelationship.put(strERPIdAccount, new List<Account_Relationship__c>{objRelationship});
				if (objRelationship.Default_Partner__c == true){                                                                                                               //DCP-28541 : To store default relationship
                    if(ucERPIdToDefaultRel.containsKey(strERPIdAccount))
                        ucERPIdToDefaultRel.get(strERPIdAccount).add(objRelationship);
                    else
                        ucERPIdToDefaultRel.put(strERPIdAccount, new List<Account_Relationship__c>{objRelationship});   
                }
            }
        }
        ilib_LogEvent.info('soldToERPToPayerERP: ' + soldToERPToPayerERP);                      //CMSI-201
        ilib_LogEvent.info('soldToERPIdToRelationship: ' + soldToERPIdToRelationship);          //CMSI-201
        ilib_LogEvent.info('ucERPIdToRelationship: ' + ucERPIdToRelationship);                  //CMSI-201
		ilib_LogEvent.info('soldToERPToDefaultRel: ' + soldToERPToDefaultRel);                  //CMSI-201
        ilib_LogEvent.info('ucERPIdToDefaultRel: ' + ucERPIdToDefaultRel);                      //CMSI-201

        // if sold to is not the payer
        // map payer ERP to Payer CMD
        if (!soldToERPToPayerERP.isEmpty())
        {
            for (Customer_Master_Data__c objCMD : new CustomerMasterDataSelector()
                        .selectByAccountERPId(new Set<String>(soldToERPToPayerERP.values())))
            {
                payerERPToCMDId.put(objCMD.ERP_Customer_Id__c, objCMD.Id);
            }
        }

        //maps to store the sold to and UC which have no CMD records related to as bill to or Ship To
        Map<String, List<Apttus_Proposal__Proposal__c>> singleSoldToERPIdToProposals = new Map<String, List<Apttus_Proposal__Proposal__c>>();

        //map to store Sales Area ERP Id for Bill To with list of proposals
        Map<String, List<Apttus_Proposal__Proposal__c>> saERPIdBillToToProposal = new  Map<String, List<Apttus_Proposal__Proposal__c>>();
        Set<String> setFoundBillToERPIds = new Set<String>();

        //map to store the updates on Proposal records since same Apttus_Proposal__Proposal__c record maybe in Sold To and UC maps
        Set<String> setUCERPSalesArea = new Set<String>();

        //set bill to based on relationships found
        for (String strERPId : soldToERPIdToProposal.keySet())
        {
            if (soldToERPToPayerERP.containsKey(strERPId))
                for (Apttus_Proposal__Proposal__c objProposal : soldToERPIdToProposal.get(strERPId))
                {
                    ilib_LogEvent.message('set payer 2 ' + payerERPToCMDId.get(soldToERPToPayerERP.get(strERPId)));
                    setProposalValue(idToProposal, objProposal,PAYER, payerERPToCMDId.get(soldToERPToPayerERP.get(strERPId)));
                }

            List<Account_Relationship__c> lstRelationShips = soldToERPIdToRelationship.get(strERPId);
			List<Account_Relationship__c> lstDefaultRel = soldToERPToDefaultRel.get(strERPId);                                                      //DCP-28541 Populate ship to if a default ship to found
            ilib_LogEvent.message('lstRelationShips'+lstRelationShips);
			Boolean isDefaultLstNull;
			if(lstDefaultRel == null || lstDefaultRel.isEmpty())                                                                                    //DCP-28541 Populate bill to if a default bill to found
                isDefaultLstNull = true;
            else
                isDefaultLstNull = false;

            if (lstRelationShips == null || lstRelationShips.isEmpty())
            {
                //if no eligible relationships found then default to sold to account CMD
                addListToMap(singleSoldToERPIdToProposals,strERPId,soldToERPIdToProposal.get(strERPId));  
            }
            else if(lstRelationShips.size() == 1 || (!isDefaultLstNull  && lstRelationShips.size() > 1 && lstDefaultRel.size() == 1))               //DCP-28541 Populate bill to if a default bill to found
            {
                Account_Relationship__c accRelationship = new Account_Relationship__c();
                if (lstRelationShips.size() == INTEGER_ONE){
                    //if only 1 record found then default it
                    accRelationship = lstRelationShips[0];
                }else if(lstRelationShips.size() > 1 && lstDefaultRel.size() == 1){
                    //if multiple relationships but one default record found
                    accRelationship = lstDefaultRel[0];
                }
                Customer_Master_Data__c objCMD = accRelationship.Account_Sales_Area__r.Customer_Master_Data__r;
                String strBillToERP = accRelationship.Related_ERP_Customer_Id__c;
                Boolean booBillToAGIsSoldTo= objCMD!=null 
                                            && CustomerMasterDatas.GROUP_SOLD_TO.equals(objCMD.Account_Group__c)
                                            && objCMD.ERP_Customer_Id__c == strBillToERP;
                if (objCMD == null || objCMD.ERP_Customer_Id__c != strBillToERP)
                {
                    addListToMap(singleSoldToERPIdToProposals,strBillToERP,soldToERPIdToProposal.get(strERPId));
                    setFoundBillToERPIds.add(strBillToERP);
                }
                else
                    for(Apttus_Proposal__Proposal__c objProposal : soldToERPIdToProposal.get(strERPId))
                    {
                        setProposalValue(idToProposal,objProposal,BILL_TO,objCMD.Id);
                        //set payer & payment terms based on bill to. if payer is different will be set again later
                        ilib_LogEvent.message('set payer 3 ' + objCMD.Id);
                        setProposalValue(idToProposal, objProposal, PAYER, objCMD.Id);
                        // DCP-46226
                        setProposalValue(idToProposal,objProposal,PAYMENT_TERM_FIELDAPI,getPaymentTermOverride(mapIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c),accRelationship.Account_Sales_Area__r.Term_Of_Payment__c));
                    }

                String strASAERPId = accRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
                String strBillToSAERP = strBillToERP+'_' + getSalesAreaFromERP(strASAERPId);
                soldToERPToSAERP.put(strBillToERP, strBillToSAERP);

                if (String.isNotBlank(strASAERPId) && !booBillToAGIsSoldTo)//If account group is sold to no need to query for payer separately
                    addListToMap(saERPIdBillToToProposal,strBillToSAERP,soldToERPIdToProposal.get(strERPId));
            }
            else
            {
                string strERPASAId = lstRelationShips[0].Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
                //blank out Bill To since multiple options found
                for (Apttus_Proposal__Proposal__c objProposal : soldToERPIdToProposal.get(strERPId))
                {
                    setProposalValue(idToProposal, objProposal, BILL_TO, null);
                    //if Bill To is becoming null payer should also become null
                    ilib_LogEvent.message('set payer 4 - null');
                    setProposalValue(idToProposal, objProposal, PAYER, null);
                    setProposalValue(idToProposal, objProposal, PAYMENT_TERM_FIELDAPI, null);
                    if (erpASAToProposals.containsKey(soldToERPToPayerERP.get(strERPId) + '_' + getSalesAreaFromERP(strERPASAId)))
                        erpASAToProposals.remove(soldToERPToPayerERP.get(strERPId) + '_' + getSalesAreaFromERP(strERPASAId));
                }
            }
        }
        ilib_LogEvent.info('singleSoldToERPIdToProposals: ' + singleSoldToERPIdToProposals);            //CMSI-201
        ilib_LogEvent.info('setFoundBillToERPIds: ' + setFoundBillToERPIds);                            //CMSI-201

        Map<String,List<Apttus_Proposal__Proposal__c>> singleUCERPIdToProposal = new Map<String,List<Apttus_Proposal__Proposal__c>>();
        //set ship to based on relationships found
        keyToNull = new Map<String,Object>{'Ship_To__c' => null, 'Inco_Term_1__c' => null};
        for(String strERPId : ucERPIdToProposal.keySet()){
            List<Account_Relationship__c> lstRelationShips = ucERPIdToRelationship.get(strERPId);
            List<Account_Relationship__c> lstDefaultRel = ucERPIdToDefaultRel.get(strERPId);                                                        //DCP-28541 Populate ship to if a default ship to found
            ilib_LogEvent.message('lstRelationShipsUC'+ lstRelationShips);

            Boolean isDefaultLstNull;
			if(lstDefaultRel == null || lstDefaultRel.isEmpty())                                                                                    //DCP-28541 Populate ship to if a default ship to found
            isDefaultLstNull = true;
            else
            isDefaultLstNull = false;
            if(lstRelationShips == null || lstRelationShips.isEmpty()){//if no eligible relationships found then default to sold to account CMD
                addListToMap(singleUCERPIdToProposal,strERPId,ucERPIdToProposal.get(strERPId));
                setUCERPSalesArea.add(ucERPToSAERP.get(strERPId));
            }else if(lstRelationShips.size()==1 || (!isDefaultLstNull  && lstRelationShips.size() > 1 && lstDefaultRel.size() == 1)){                //DCP-28541 Populate ship to if a default ship to found

                Account_Relationship__c accRelationship = new Account_Relationship__c();
                if (lstRelationShips.size() == INTEGER_ONE){
                    //if only 1 record found then default it
                    accRelationship = lstRelationShips[0];
                }else if(lstRelationShips.size() > 1 && lstDefaultRel.size() == 1){
                    //if multiple relationships but one default record found
                    accRelationship = lstDefaultRel[0];
                }
                ilib_LogEvent.message('accRelationship--11'+accRelationship);
                Customer_Master_Data__c objCMD = accRelationship.Account_Sales_Area__r.Customer_Master_Data__r;
                //if(objCMD.Mark_For_Deletion__c == false){
                    ilib_LogEvent.message('objCMD'+objCMD);
                    String strShipToERP = accRelationship.Related_ERP_Customer_Id__c;
                    keyToValue = new Map<String,Object>{'Ship_To__c' => objCMD.Id, 'Inco_Term_1__c' => incoTerm1};
                    ilib_LogEvent.message('-keyToValue-'+ keyToValue);
                    ilib_LogEvent.message('strShipToERP'+ strShipToERP);
                    ilib_LogEvent.message('accountERPToCountry.get(strShipToERP)'+accountERPToCountry.get(strShipToERP));
                    if(objCMD == null || objCMD.ERP_Customer_Id__c != strShipToERP || 
                        (objCMD.Country__c !=accountERPToCountry.get(strShipToERP) && String.isNotBlank(accountERPToCountry.get(strShipToERP)) )) {
                        addListToMap(singleUCERPIdToProposal,strShipToERP,ucERPIdToProposal.get(strERPId));
                        // INC0395756 - Added logic to populate Incoterm value based on Ship To's Sales Area 
                        setUCERPSalesArea.add(strShipToERP + '_' + getSalesAreaFromERP(accRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c));
                    }
                    else{
                        for(Apttus_Proposal__Proposal__c objProposal : ucERPIdToProposal.get(strERPId)){
                            if(!setDirectRecordTypes.contains(objProposal.Opportunity_Record_Type__c)) {
                                if(objProposal.Direct_Sale_to_Ultimate_Consignee__c){
                                    String strASAERPId = accRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
                                    incoTerm1 = accRelationship.Account_Sales_Area__r.Inco_Term_1__c;
                                    if(String.isNotBlank(strASAERPId)){
                                        Boolean boolUCSAUnderDistributorSA = false;
                                        String strUCSalesArea = getSalesAreaFromERP(strASAERPId);
                                        ilib_LogEvent.message('strUCSalesArea--->' +strUCSalesArea);
                                        if(ucERPToDistSalesArea.containsKey(strERPId)){
                                            for(Account_Sales_Area__c asa : ucERPToDistSalesArea.get(strERPId)){
                                                if(strUCSalesArea == getSalesAreaFromERP(asa.ERP_Account_Sales_Area_Id__c))
                                                    boolUCSAUnderDistributorSA = true;
                                            }
                                        }
                                        if(!boolUCSAUnderDistributorSA){
                                            setFieldProposalValue(idToProposal,objProposal,keyToNull);
                                        }else{
                                            setFieldProposalValue(idToProposal,objProposal,keyToValue);
                                        }
                                    }
                                }   
                                else{
                                    setFieldProposalValue(idToProposal,objProposal,keyToValue); 
                                }
                            }
                            else{
                                ilib_LogEvent.message('Check 1 relationship');
                                setFieldProposalValue(idToProposal,objProposal,keyToValue); 
                            }
                        }   
                    }
               // }
            }else{//blank out Ship To since multiple options found
            for(Apttus_Proposal__Proposal__c objProposal : ucERPIdToProposal.get(strERPId)){
                setFieldProposalValue(idToProposal,objProposal,keyToNull);
            }
        }
    }
        setAccountKeys = new Set<String>();
        setAccountKeys.addAll(singleSoldToERPIdToProposals.keySet());
        setAccountKeys.addAll(singleUCERPIdToProposal.keySet());
        ilib_LogEvent.info('setAccountKeys: ' + setAccountKeys);             //CMSI-201
        ilib_LogEvent.info('singleUCERPIdToProposal: ' + singleUCERPIdToProposal);     //CMSI-201
        ilib_LogEvent.info('setUCERPSalesArea: '+ setUCERPSalesArea);             //CMSI-201

        Map<String,Account_Sales_Area__c> strERPIdToASA = new Map<String,Account_Sales_Area__c>();

        if(!setUCERPSalesArea.isEmpty()){
            List<Account_Sales_Area__c> lstTransactionSalesArea = new List<Account_Sales_Area__c>(new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setUCERPSalesArea));  
            if(!lstTransactionSalesArea.isEmpty()){
                for(Account_Sales_Area__c asa:lstTransactionSalesArea){
                    strERPIdToASA.put(asa.Account__r.ERP_Customer_Id__c,asa);
                }
            }
        }
        ilib_LogEvent.info('strERPIdToASA: '+strERPIdToASA);                        //CMSI-201
        
        Map<String,List<Apttus_Proposal__Proposal__c>> billToSAToProposals = new Map<String,List<Apttus_Proposal__Proposal__c>>();
        if(!setAccountKeys.isEmpty())//if no single scenarios found avoid query
        {
            for(Customer_Master_Data__c objCMD : new CustomerMasterDataSelector()
                                                    .selectByAccountERPId(setAccountKeys))
            {
                Boolean booAGIsSoldTo = CustomerMasterDatas.GROUP_SOLD_TO.equals(objCMD.Account_Group__c);
                if(singleSoldToERPIdToProposals.containsKey( objCMD.ERP_Customer_Id__c )){
                    for(Apttus_Proposal__Proposal__c objProposal : singleSoldToERPIdToProposals.get(objCMD.ERP_Customer_Id__c)){
                        setProposalValue(idToProposal,objProposal,BILL_TO,objCMD.Id);
                        ilib_LogEvent.message('set payer 5 ' + objCMD.Id);
                        setProposalValue(idToProposal, objProposal, PAYER, objCMD.Id);//set payer value to bill to by default. if different payer exists will be set later
                    }
                    billToSAToProposals.put(soldToERPToSAERP.get(objCMD.ERP_Customer_Id__c),
                                            singleSoldToERPIdToProposals.get(objCMD.ERP_Customer_Id__c));
                    //if not found in below set means no relationship was found for this CMD earlier and Bill To found is not a sold to
                    if(!setFoundBillToERPIds.contains(objCMD.ERP_Customer_Id__c) && !booAGIsSoldTo)
                        addListToMap(saERPIdBillToToProposal,soldToERPToSAERP.get(objCMD.ERP_Customer_Id__c)
                                    ,singleSoldToERPIdToProposals.get(objCMD.ERP_Customer_Id__c));  
                }
                if(singleUCERPIdToProposal.containsKey( objCMD.ERP_Customer_Id__c ) && 
                    (objCMD.Country__c == accountERPToCountry.get(objCMD.ERP_Customer_Id__c) || String.isBlank(accountERPToCountry.get(objCMD.ERP_Customer_Id__c))) )
                    for(Apttus_Proposal__Proposal__c objProposal : singleUCERPIdToProposal.get(objCMD.ERP_Customer_Id__c))
                    {
                        setProposalValue(idToProposal,objProposal,'Ship_To__c',objCMD.Id);
                        if(strERPIdToASA.containsKey(objCMD.ERP_Customer_Id__c))
                            setProposalValue(idToProposal,objProposal,'Inco_Term_1__c',strERPIdToASA.get(objCMD.ERP_Customer_Id__c).Inco_Term_1__c);
                    }
            }
        }

        ilib_LogEvent.info('@@@erpASAToProposals:' + erpASAToProposals);              //CMSI-201
        setPayer(saERPIdBillToToProposal, idToProposal, erpASAToProposals, soldToERPToDefaultRel,mapIdToOpportunity);
        ilib_LogEvent.info('idToProposal: ' + idToProposal);                         //CMSI-201

        ilib_LogEvent.pop();
        return idToProposal;
    }
    
    /**
     *  @author Akshay Mohan 
     *  @description Set Payer 
     *  @param Map<String,List<Apttus_Proposal__Proposal__c>> saERPIdBillToToProposal
     *  @param Map<Id,Apttus_Proposal__Proposal__c> idToProposal
     *  @return void
     **/
     public static void setPayer(Map<String, List<Apttus_Proposal__Proposal__c>> saERPIdBillToToProposal,
                                Map<Id, Apttus_Proposal__Proposal__c> idToProposal,
                                Map<String, List<Apttus_Proposal__Proposal__c>> erpASAToProposals,
                                Map<String, List<Account_Relationship__c>> soldToERPToDefaultRel,
                                Map<Id, Opportunity> mapIdToOpportunity)
    {
        // get payer related to default bill to
        List<Account_Relationship__c> billToPayerRels = new AccountRelationshipsSelector().selectByASAERPWithRelationship(saERPIdBillToToProposal.keySet(), CustomerMasterDatas.GROUP_PAYER);
        Map<String, Account_Relationship__c> billToKeyToPayerRel = new Map<String, Account_Relationship__c>();
        Set<String> payerKeys = new Set<String>();
        for (Account_Relationship__c rel : billToPayerRels)
        {
            billToKeyToPayerRel.put(rel.ERP_Customer_Id__c, rel);
            payerKeys.add(rel.Related_ERP_Customer_Id__c);
        }
        List<Customer_Master_Data__c> payerCmds = new CustomerMasterDataSelector().selectByAccountERPId(payerKeys);
        Map<String, Id> payerKeyToId = new Map<String, Id>();
        for (Customer_Master_Data__c cmd : payerCmds)
            payerKeyToId.put(cmd.Erp_Customer_Id__c, cmd.Id);

        if (!saERPIdBillToToProposal.isEmpty())
        {
            ilib_LogEvent.info('saERPIdBillToToProposal: ' + saERPIdBillToToProposal);             //CMSI-201
            for (Account_Relationship__c objRel : billToPayerRels)
            {
                String strERPASAId = objRel.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
                for (Apttus_Proposal__Proposal__c objProposal : saERPIdBillToToProposal.get(strERPASAId))
                {
                    if (objRel.Related_ERP_Customer_Id__c == objRel.Account_Sales_Area__r.Customer_Master_Data__r.ERP_Customer_Id__c)
                    {
                        ilib_LogEvent.message('set payer 6 ' + objRel.Account_Sales_Area__r.Customer_Master_Data__c);
                        setProposalValue(idToProposal, objProposal, PAYER, objRel.Account_Sales_Area__r.Customer_Master_Data__c);
                    }
                    // DCP-46226
                    setProposalValue(idToProposal,objProposal,PAYMENT_TERM_FIELDAPI,getPaymentTermOverride(mapIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c),objRel.Account_Sales_Area__r.Term_Of_Payment__c));
                }

                if (objRel.Related_ERP_Customer_Id__c != objRel.Account_Sales_Area__r.Customer_Master_Data__r.ERP_Customer_Id__c)
                    addListToMap(erpASAToProposals,objRel.Related_ERP_Customer_Id__c+'_'+getSalesAreaFromERP(strERPASAId),saERPIdBillToToProposal.get(strERPASAId));
            }
        }

        if (!erpASAToProposals.isEmpty())
        {
            // collect ERP Ids of Bill To records
            Set<Id> billToIds = new Set<Id>();
            for (String soldToAsaKey : erpASAToProposals.keySet())
            {
                billToIds.addAll(UtilsCollection.getSetOfIds(erpASAToProposals.get(soldToAsaKey), BILL_TO));
            }
            ilib_LogEvent.info('billToIds: ' + billToIds);             //CMSI-201
            // query the CMD for Bill Tos and map
            Map<Id, Customer_Master_Data__c> idToBillToCMD = new Map<Id, Customer_Master_Data__c>();
            List<Customer_Master_Data__c> billToCMDs = new CustomerMasterDataSelector().selectById(billToIds);
            for (Customer_Master_Data__c cmd : billToCMDs)
                idToBillToCMD.put(cmd.Id, cmd);
            ilib_LogEvent.info('idToBillToCMD: ' + idToBillToCMD);                    //CMSI-201

            List<Account_Sales_Area__c> lstASA = new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(erpASAToProposals.keySet());
            for (Account_Sales_Area__c objASA : lstASA)
            {
                for (Apttus_Proposal__Proposal__c objProposal : erpASAToProposals.get(objASA.ERP_Account_Sales_Area_Id__c))
                {
                    if (objProposal.Bill_To__c != null)
                    {
                        // if the bill to is a sold to or distributor, use that as the payer
                        Customer_Master_Data__c billToCMD = idToBillToCMD.get(objProposal.Bill_To__c);
                        if (billToCMD != null && (billToCMD.Account_Group__c == Accounts.GROUP_SOLD_TO || billToCMD.Account_Group__c == Accounts.GROUP_DISTRIBUTOR))
                        {
                            ilib_LogEvent.message('set payer 7 ' + billToCMD.Id);
                            setProposalValue(idToProposal, objProposal, PAYER, billToCMD.Id);
                            // NOTE: terms already set at "set payer 1" where sold to is used as payer
                            continue;
                        }
                        // if the bill to is not a sold to/distributor, use any bill to relationship found
                        else
                        {
                            ilib_LogEvent.message('set payer 8 ' + objASA.Customer_Master_Data__r.Id);
                            setProposalValue(idToProposal, objProposal, PAYER, objASA.Customer_Master_Data__r.Id);
                            // DCP-46226
                            setProposalValue(idToProposal,objProposal,PAYMENT_TERM_FIELDAPI,getPaymentTermOverride(mapIdToOpportunity.get(objProposal.Apttus_Proposal__Opportunity__c),objASA.Term_Of_Payment__c));
                            if (soldToERPToDefaultRel.containsKey(objProposal.Sold_To_ERP_Number__c))
                            {
                                for (Account_Relationship__c rel : soldToERPToDefaultRel.get(objProposal.Sold_To_ERP_Number__c))
                                {
                                    if (rel.Relationship__c == CustomerMasterDatas.GROUP_BILL_TO)
                                    {
                                        // this is the default bill to rel
                                        String payerKey = billToKeyToPayerRel.get(rel.Related_ERP_Customer_Id__c).Related_ERP_Customer_Id__c;
                                        Id payerId = payerKeyToId.get(payerKey);
                                        ilib_LogEvent.message('default payerKey ' + payerKey);
                                        ilib_LogEvent.message('set payer 9 ' + payerId);
                                        setProposalValue(idToProposal, objProposal, PAYER, payerId);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     *  @author Akshay Mohan 
     *  @description Set values on proposal based on insert scenario or update 
     *  @param Map<String,List<Apttus_Proposal__Proposal__c>> keyToProposals
     *  @param String strKey
     *  @param List<Apttus_Proposal__Proposal__c> lstProposals
     *  @return void
     **/
    public static void addListToMap(Map<String,List<Apttus_Proposal__Proposal__c>> keyToProposals,String strKey,
                                        List<Apttus_Proposal__Proposal__c> lstProposals){
        if(keyToProposals.containsKey(strKey))
            keyToProposals.get(strKey).addAll(lstProposals);
        else
            keyToProposals.put(strKey, lstProposals);
    }
    
    /**
     *  @author Akshay Mohan 
     *  @description Set values on proposal based on insert scenario or update 
     *  @param Map<Id,Apttus_Proposal__Proposal__c> idToProposal
     *  @param Apttus_Proposal__Proposal__c objProposal
     *  @param String strField
     *  @param String strValue
     *  @return void
     **/
    public static void setProposalValue(Map<Id,Apttus_Proposal__Proposal__c> idToProposal,
                                    Apttus_Proposal__Proposal__c objProposal,String strField,Object oValue){
        if(objProposal.get(strField)!=oValue){//set values only if there is a change to avoid unneccessary updates
            if(String.isNotBlank(objProposal.Id)){//will happen only for insert
                if(!idToProposal.containsKey(objProposal.Id))
                    idToProposal.put(objProposal.Id,objProposal);
                idToProposal.get(objProposal.Id).put(strField,oValue);
            }else
                objProposal.put(strField,oValue);
        }
        
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To get Sales area from ERP ID
    *  @param        : String strASA ERP ID of Sales Area
    *  @return       : String
    */
    public static String getSalesAreaFromERP(String strASA){
        List<String> lstSalesAreaSplit = strASA.split('_');
        String strSalesAreaWithoutERP;
        if(lstSalesAreaSplit.size()==INTEGER_TWO)
            strSalesAreaWithoutERP= lstSalesAreaSplit[1];
        return strSalesAreaWithoutERP;
    }

    /**
     *  @author Rahul Sharma 
     *  @description Set values on proposal based on field and value
     *  @param Map<Id,Apttus_Proposal__Proposal__c> idToProposal
     *  @param Apttus_Proposal__Proposal__c objProposal
     *  @param Map<String,Object> strToValue
     *  @return void
     **/
    public static void setFieldProposalValue(
        Map<Id, Apttus_Proposal__Proposal__c> idToProposal,
        Apttus_Proposal__Proposal__c objProposal,
        Map<String, Object> keyToValue)
    {
        ilib_LogEvent.message('keyToValue: '+keyToValue);
        for(String key: keyToValue.keyset()){
            setProposalValue(idToProposal,objProposal,key,keyToValue.get(key));
        }
    }
    /*
    *  @author       : KD
    *  @description  : DCP-46226 :To get Default payment term for GC
    *  @param        : Opportunity and Payment term
    *  @return       : String
    */
    public static String getPaymentTermOverride(Opportunity objOpportunity,String strPaymentTerm){
        if(strPaymentTerm != PAYMENT_TERM_PP00 || String.isBlank(objOpportunity.Product_Interest__c)){
            return strPaymentTerm;
        }
        else if((setPaymentDefaultCountryBreakFix.contains(objOpportunity.Account.BillingCountry)
                && (objOpportunity.RecordType.DeveloperName == Label.FieldServices || objOpportunity.RecordType.DeveloperName == Label.IndirectFieldServices)
                && objOpportunity.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix))
                || (setPaymentDefaultCountryRelocation.contains(objOpportunity.Account.BillingCountry)
                && objOpportunity.RecordType.DeveloperName == Label.FieldServices 
                && objOpportunity.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation))){
                    return PAYMENT_TERM_NT00;
        }
        else{
            return strPaymentTerm;
        }
    }

}