/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Class to get the Agreement records based on different conditions ,
*     Test Class 90% Coverage : TestApttusAgreements
 *    Test Class 75% Coverage : TestOpenOfferAgreements.
 *    Modification Log:
 *    Test class for 90% coverage: TestApttusAgreements,
 *   Test class for 75% coverage: TestOpenOfferagreements 
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Umesh Mor                  1/22/2020               Modified getSObjectType() and selectAgreements(Set<Id> agreementIds) to include new feild as part of DCP-31142 story
 *    Kushagra Desai             6-Feb-2020              Added field
 *    B Kamini                   24 Feb 2020             DCP-34092: Added field in selectAgreements
 *    Kushagra Desai             1-Mar-2020              Added field
 *    Joshith K                  10-June-2020            TASK0493822-Added field(Approval_Hierarchy_Discount__c)
 *    Joshith K                  21-Aug-2020             INC0279101-Added field
 *    Prabhsimran Singh          21-Aug-2020             DCP-39587 Added field
 *    Rahul Bishnoi              17-May-2021             INC0320773 Added Field
 *    Shivani Jain               24-Jun-2021             DCP-46181 - Added new fields
 *    Bharath Varma              29-Jun-2021             DCP-47006 Added 4 new fields
 *    Prem Ranjan                17-Aug-2021             DCP-47729 Ability to add PPM to Agreement header
 *    Nishan Shetty              23-May-2022             DCP-52708 Added Account Owner(Prepared By) field in selectAgreements method and query instrumentation.
 *    Saddam                     25-Aug-2022             DCP-54810 Added Open_Offer_Status__c field to select Agreements Method.
 *    Vivek R                    02-Sep-2022             DCP-54529 Added Sales Org and Distribution Channel fields in selectAgreements method
 *    Saddam                     02-sep-2022             DCP-54536  Added Feields to fieldlist.
 *    Aman Tyagi                 22-Sep-2022             added field as per DCP-56506
 *    Prem Ranjan                20-Feb-2023             CodeScan Fixes (APEX) Variable Naming Conventions
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
public class ApttusAgreementSelectors extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'ApttusAgreementSelectors';//DCP-52708
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';//DCP-52708

    /**
    *  @author Kushagra Desai 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Apttus__APTS_Agreement__c.sObjectType;
    }
    /**
     *  @author Kushagra Desai
     *  @description Retrieve list of fields for Line Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus__APTS_Agreement__c.id,
            Apttus__APTS_Agreement__c.Validation_Status__c,
            Apttus__APTS_Agreement__c.Account_ERP_Number__c,
            Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c,
            Apttus__APTS_Agreement__c.CurrencyIsoCode,
            Apttus__APTS_Agreement__c.Sales_Org__c, //adding reference sales org
            Apttus__APTS_Agreement__c.Distribution_Channel__c,
            Apttus__APTS_Agreement__c.Price_Group__c,
            Apttus__APTS_Agreement__c.Ultimate_Consignee_ERP_Number__c,
            Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c,
            Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c,
            Apttus__APTS_Agreement__c.Apttus__Subtype__c,
            //Apttus__APTS_Agreement__c.Customer_Discount_Level__c,
			//Below fields added as the part of user story : DCP-31142
            Apttus__APTS_Agreement__c.Apttus__Agreement_Number__c,
            Apttus__APTS_Agreement__c.Region__c,
            Apttus__APTS_Agreement__c.Apttus__Account__r.Name,
            Apttus__APTS_Agreement__c.OwnerId,
          
            //Below fields added as the part of user story : DCP-31177
            Apttus__APTS_Agreement__c.Territory__c,
            Apttus__APTS_Agreement__c.Competitive_Products__c,
            Apttus__APTS_Agreement__c.Value_Added_Distributor__c,
            Apttus__APTS_Agreement__c.Apttus__Auto_Renewal__c,
            Apttus__APTS_Agreement__c.Exclusivity__c,
            Apttus__APTS_Agreement__c.Date_of_Auto_Renewal_Expiration__c,
            Apttus__APTS_Agreement__c.Incoterm__c,
            Apttus__APTS_Agreement__c.Apttus__Version_Number__c,
            Apttus__APTS_Agreement__c.Apttus_Approval__Approval_Status__c,
             //DCP-32563
            Apttus__APTS_Agreement__c.Apttus__Account__r.OwnerId,
            Apttus__APTS_Agreement__c.Number_Of_Agreement_Line_Items__c,
            Apttus__APTS_Agreement__c.Apttus__Status__c,
            Apttus__APTS_Agreement__c.Apttus__Status_Category__c,
            Apttus__APTS_Agreement__c.Name,
            Apttus__APTS_Agreement__c.Action_Date__c,
            Apttus__APTS_Agreement__c.Is_Auto_Approved__c,
            Apttus__APTS_Agreement__c.Is_Validated_Successful__c,
            Apttus__APTS_Agreement__c.RecordTypeId,
            Apttus__APTS_Agreement__c.Approval_Hierarchy_Discount__c,
			//DCP-39587
            Apttus__APTS_Agreement__c.Amend_Batch_Completed__c,
            //INC0320773
            Apttus__APTS_Agreement__c.Agreement_Not_Amended__c,
            Apttus__APTS_Agreement__c.Parent_Agreement_Number__c,
            //DCP-47006
            Apttus__APTS_Agreement__c.ALIs_with_UC_Material_Group__c,
            Apttus__APTS_Agreement__c.ALIs_with_UC_Material_Discount__c,
            Apttus__APTS_Agreement__c.ALIs_with_UC_Material_Discount_Amount__c,
            Apttus__APTS_Agreement__c.ALIs_with_UC_Material_Fixed_Price__c,
            //DCP-54536 Start
            Apttus__APTS_Agreement__c.Apttus__Subtype__c
        };
    }
    
    /**
     *  @author Kushagra Desai 
     *  @description fetch Agreement with line item
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Apttus__APTS_Agreement__c> selectAgreementWithLines(Set<Id> idSet){
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN :idSet');
        query.selectfield('Apttus__Account__r.Name');
        query.selectfield('RecordType.Name');//dcp-54536
        query.selectfield('CurrencyIsoCode');//dcp-54536
        query.selectfield('Sales_Org__c');//dcp-54536
        query.selectfield('Distribution_Channel__c');//dcp-54536
        query.selectfield('Parent_Agreement_Number__c');//dcp-56506
         query.subselectQuery('Apttus__AgreementLineItems__r').selectFields(new ApttusAgreementLineItemSelectors().getSObjectFieldList())
            .selectField('Apttus__ProductId__r.Material_Number__c')
            .addOrdering('Apttus_CMConfig__LineNumber__c',ilib_QueryFactory.SortOrder.ASCENDING);
            system.debug('@@@@'+query.toSOQL());
        return (List<Apttus__APTS_Agreement__c>) Database.query(
            query.toSOQL()
        );
    }
    /*
    * @author Kushagra Desai
    * @date   20-Dec-2019
    * @description Fetch Agreement Record
    * @param Set of agreeement id
    *
    */
    public List<Apttus__APTS_Agreement__c> selectAgreements(Set<Id> agreementIds) 
    {   
        ilib_LogQuery logger = new ilib_LogQuery();
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgreements',UtilsCollection.serializeIds(agreementIds));
        }
        Integer numberOfQueries = Limits.getQueries();
        System.debug('Number of SOQL queries executed: ' + numberOfQueries);    
        List<Apttus__APTS_Agreement__c> res = (List<Apttus__APTS_Agreement__c>) Database.query(
        newQueryFactory()
				.selectField('RecordType.Name')
                .selectField('RecordType.DeveloperName')
                //Below fields added as the part of user story : DCP-31142
                .selectfield('Apttus__Agreement_Number__c')
                .selectfield('Region__c')
                .selectfield('Apttus__Account__c')
                .selectField('OwnerId')
                .selectField('Owner.Name')
                .selectField('Apttus__Account__r.OwnerId') //DCP-32563
                .selectfield('Apttus__Account__r.Name')
                .selectField('Apttus__Contract_Start_Date__c')
                .selectField('Apttus__Contract_End_Date__c')
                .selectField('Discount_Justification__c')
                .selectField('Territory__c')
                .selectfield('Competitive_Products__c')
                .selectField('Value_Added_Distributor__c')
                .selectField('Apttus__Auto_Renewal__c')
                .selectField('Exclusivity__c')
                .selectField('Date_of_Auto_Renewal_Expiration__c')
                .selectField('Incoterm__c')
                .selectField('Apttus__Version_Number__c')
				.selectField('Validation_Status__c')//DCP-34092
                .selectField('Approval_Category__c') //DCP-32046
				.selectField('Is_Agreement_under_Approvals_submission__c') //DCP-37225
                .selectField('Submission_Failed_Error_Message__c') //DCP-37225
                .selectField('Approval_Submission_Job_Id__c') //DCP-37225
                .selectField('Line_Items_Required_Optional__c')//INC0279101
                .selectField('Is_Updating_Line_Status__c')//INC0279101
				.selectField('Amend_Batch_Completed__c')//DCP-39587
                .selectField('Apttus__Status__c')//DCP-39587
                .selectField('Agreement_Not_Amended__c')//DCP-39587
                .selectField('Parent_Agreement_Number__c') //INC0320773
                .selectField('Apttus__Account__r.Account_Group__c') //DCP-46181
                .selectField('Apttus__Account__r.Channel_Partner_Type__c') //DCP-46181
                .selectField('Apttus__Account__r.ERP_Customer_Id__c') //DCP-46181
                .selectfield('Post_Pricing_Message__c')//DCP-47729
                .selectfield('Country_On_Account_Approvals__c')//DCP-49431
                .selectfield('Apttus__Account__r.Oncology_Lab_Manufacturer_Comparison__c')//DCP-49431
                .selectfield('Prepared_By__r.Name')//DCP-52708
                .selectfield('Open_Offer_Status__c')//DCP-54810
                .selectfield('Sales_Org__c')//DCP-54529
                .selectfield('Distribution_Channel__c')//DCP-54529
                .selectField('Account_National_Group_Number__c') //DCP-54439
				.selectField('Apttus__Total_Contract_Value__c') //CMCM-740 - To display new fields on Submit for approval email 
            	.selectField('Justification_for_No_Agreement_Value__c') //CMCM-740 - To display new fields on Submit for approval email 
            	.selectField('Other_Reason__c') //CMCM-740 - To display new fields on Submit for approval email 
				.selectField('Freight_Charge__c') //CMCM-5261 - To display new fields On Submit For Approval Email
            	.selectField('Reason_for_Non_Standard_Freight__c') //CMCM-5261 - To display new fields On Submit For Approval Email
                .setCondition('Id IN :agreementIds').toSOQL());

                if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
                  logger.stop(res.size());
                }
              return res;
    }
    /**
     *  @author Kushagra Desai 
     *  @description fetch Agreement with line item
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public Apttus__APTS_Agreement__c selectAgreementsByNumber(String agrNumber){
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Apttus__FF_Agreement_Number__c =: agrNumber');
         query.subselectQuery('Apttus__AgreementLineItems__r').selectFields(new ApttusAgreementLineItemSelectors().getSObjectFieldList())
            .addOrdering('Apttus_CMConfig__LineNumber__c',ilib_QueryFactory.SortOrder.ASCENDING);
            system.debug('@@@@'+query.toSOQL());
        return (Apttus__APTS_Agreement__c) Database.query(
            query.toSOQL()
        );
    }
}