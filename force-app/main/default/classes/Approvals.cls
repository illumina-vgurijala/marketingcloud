/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: Container class for all wrapper classes used in Approval Framework
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27           Initial Version
*         Satya Swain                 2021-08-11           Added new collections to wrapper classes
*         Kushal Shah                 2021-09-28           DCP-49429: Added fields for MFN
*         Bharath Varma               2021-11-30           DCP-50961: Added classes for AgreementLines
*         Himanshu                    2023-01-20           INC0447800: Changing it to when any of the line is updated 
*         Rajbabu                     2024-10-04           CMCM-11370: ByPass Special Programs RT when it has an approval category 
*    -----------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class Approvals {

    public static final String APPROVAL_TYPE_MATNUM = 'Material_Number';
    public static final String APPROVAL_TYPE_MATGRP = 'Material_Group';
    public static final String APPROVAL_TYPE_DISCOUNT = 'Discount';
    public static final String BLANK_STRING = 'BLANK';
    public static final String HIERARCHY_CUSTOM = 'Custom';
    public static final String HIERARCHY_TYPE_RECORD_OWNER = 'Record Owner';
    public static final Integer MAX_APPROVAL_LEVEL = Integer.valueOf(Label.Maximum_Approval_Level);
    public static final String CPQ_SALES = 'CPQ_Sales_Hierarchy';
    public static set<String> lineTypeForApprovals = new set<String>{'Price Group - Material', 'Price Group - Material Group 1'};

    private static final String APPROVAL_STATUS_PENDING = 'Pending Approval';
    private static final String APPROVAL_STATUS_REQUIRED = 'Approval Required';
    private static final String APPROVAL_STATUS_CANCELLED = 'Cancelled';
    private static final String APPROVAL_STATUS_REJECTED = 'Rejected';

    /*
    *   @description:
    *   Enum containing all Approval Scenarios in the form of Steps 
    *   Every Step will be implemented separately in individual classes
    *   Any new kind of approval which is to be developed in future needs to be added here
    */
    public enum StepName {
        CPQ_DISCOUNT,
        CPQ_MATERIAL_NUMBER,
        CPQ_MATERIAL_GROUP_1,
        CPQ_MATERIAL_NUMBER_CUSTOM,
        CPQ_MATERIAL_GROUP_CUSTOM,
        CPQ_DISCOUNT_CUSTOM,
        CPQ_MFN,
        PROMOTION_1,
        PROMOTION_2,
        PROMOTION_3,
        PROMOTION_4,
        PROMOTION_5,

        // CLM Step Names
        CLM_DISCOUNT,
        CLM_MATERIAL_NUMBER,
        CLM_MATERIAL_GROUP_1,
        CLM_MATERIAL_NUMBER_CUSTOM,
        CLM_MATERIAL_GROUP_CUSTOM,
        CLM_DISCOUNT_CUSTOM,
        CLM_MFN
    }

    /*
    *   @description: Enum containing Approval domains 
    */
    public enum StepDomain {
        QUOTE_LINE,
        AGREEMENT_LINE
    }

    /* method to return the correct domain */
    public static StepDomain getDomain(StepName name)
    {
        if (name == StepName.CLM_DISCOUNT
            || name == StepName.CLM_MATERIAL_NUMBER
            || name == StepName.CLM_MATERIAL_GROUP_1
            || name == StepName.CLM_MATERIAL_NUMBER_CUSTOM
            || name == StepName.CLM_MATERIAL_GROUP_CUSTOM
            || name == StepName.CLM_DISCOUNT_CUSTOM
            || name == StepName.CLM_MFN
        ) {
            return StepDomain.AGREEMENT_LINE;
        }

        return StepDomain.QUOTE_LINE;
    }

    /*
    *   @description:
    *   Enum containing all Approval Categories. These will be stamped on Quote Line/Quote header 
    *   in Approval Category Field based on type of approval triggered
    *   Any new kind of approval which is to be developed in future needs to be added here
    */
    public enum Category {
        CPQ_DISCOUNT,
        CPQ_MATERIAL_NUMBER,
        CPQ_MATERIAL_GROUP_1,
        CPQ_MATERIAL_NUMBER_CUSTOM,
        CPQ_MATERIAL_GROUP_CUSTOM,
        CPQ_DISCOUNT_CUSTOM,
        CPQ_Sales_Hierarchy,
        PROMOTION,

        // CLM Approval Categories
        MATERIAL_GROUP, 
        MATERIAL_NUMBER, 
        DISCOUNT, 
        MATERIAL_GROUP_CUSTOM, 
        MATERIAL_NUMBER_CUSTOM, 
        DISCOUNT_CUSTOM, 
        CLM_SALES_HIERARCHY, 
        MFN_APPROVALS
    }

    /*
    *   @description:
    *   Contains collections for Quote Line and Quotation details
    *   This is populated in client (trigger handler)
    *   Used in creation of SupportData wrapper 
    */
    public class QuoteLineInputs {
        public List<Apttus_Proposal__Proposal_Line_Item__c> quoteLines;
        public Map<Id, Apttus_Proposal__Proposal__c> idToQuote;
        
        /* constructor */
        public QuoteLineInputs(
            List<Apttus_Proposal__Proposal_Line_Item__c> quoteLines,
            Map<Id, Apttus_Proposal__Proposal__c> idToQuote)
        {
            this.quoteLines = quoteLines;
            this.idToQuote = idToQuote;
        }
    }

    /*
    *   @description:
    *   Contains collections for Agreement Line and Agreement details
    *   This is populated in client (trigger handler)
    *   Used in creation of SupportData wrapper 
    */
    public class AgreementLineInputs {
        public List<Apttus__AgreementLineItem__c> agreementLines;
        public Map<Id, Apttus__APTS_Agreement__c> idToAgreement;
        
        /* constructor */
        public AgreementLineInputs(
            List<Apttus__AgreementLineItem__c> agreementLines,
            Map<Id, Apttus__APTS_Agreement__c> idToAgreement)
        {
            this.agreementLines = agreementLines;
            this.idToAgreement = idToAgreement;
        }
    }

    /*
    *   @description:
    *   Contains collections regarding Data to be used when executing pipeline
    *   Any data which neeeds to be queried beforehand can be done 
    *   Passed in Constructor of All Pipeline Classes
    */
    public class SupportData {
        public Map<Id, Apttus_Proposal__Proposal__c> idToQuote;
        public Map<Id, Product2> idToProduct;
        // all (125) matrixes in the system in a wrapper class, split into two dimensions
        // hierarcy type: record owner (account owner determines hierarchy) vs custom (something else does)
        // record type: material number, material group, or discount
        public ApprovalMatricesWrapper approvalMatricesWrapper;
        // approval hierarchies for all the users who own relevent accounts
        public Map<Id, Approval_Hierarchy__c> userIdToApprovalHierarcy;
        public Map<Id, User> idToAccountOwner;
        public Map<String, Integer> approvalKeyToPriority;

        // TODO: how should I handle extra supporting data?
        // inheritance hierarchy? decorator?

        // if a CAM has products, its ID is mapped here to the set of product numbers
        public Map<Id, Set<String>> matrixIdToProductNumbers; // mat num only
        public Map<Id, Apttus_Config2__Incentive__c> idToPromo; // promo only

        // Fields for CLM
        public Map<Id, Apttus__APTS_Agreement__c> idToAgreement;
        public Map<String,Account> customerERPToAccount; // map to store ERP To Account
        public Map<String,Account_Sales_Area__c> aliToAccountSalesArea;
        public List<Apttus_Config2__PriceListItem__c> priceListItems;
        public Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>> productIdToPriceListItem;
        public Map<Id, Account> idToAccount;
        public Set<String> materialNumbers;
        public Set<Id> agreementLinesUpdated;

        /* constructor */
        public SupportData() { }

        /* parameterized constructor */
        public SupportData(Map<Id, Apttus_Proposal__Proposal__c> idToQuote, Map<Id, Product2> idToProduct, Map<Id, Apttus_Config2__Incentive__c> idToPromo, ApprovalMatricesWrapper approvalMatricesWrapper, Map<Id, Approval_Hierarchy__c> userIdToApprovalHierarcy, Map<Id, User> idToAccountOwner, Map<String, Integer> approvalKeyToPriority, Map<Id, Set<String>> matrixIdToProductNumbers)
        {
            this.idToQuote = idToQuote;
            this.idToProduct = idToProduct;
            this.idToPromo = idToPromo;
            this.approvalMatricesWrapper = approvalMatricesWrapper;
            this.userIdToApprovalHierarcy = userIdToApprovalHierarcy;
            this.idToAccountOwner = idToAccountOwner;
            this.approvalKeyToPriority = approvalKeyToPriority;
            this.matrixIdToProductNumbers = matrixIdToProductNumbers;
        }

        /* TTN added - parameterized constructor for CLM with no matrices */
        public SupportData( Map<Id, Apttus__APTS_Agreement__c> idToAgreement,
                            Map<Id, Product2> idToProduct, 
                            ApprovalMatricesWrapper approvalMatricesWrapper,
                            Set<Id> agreementLinesUpdated,
                            Map<String,Account> customerERPToAccount,
                            Map<Id,Account> idToAccount)
        {
            this(
                idToAgreement, 
                idToProduct, 
                approvalMatricesWrapper,
                new Map<Id, Approval_Hierarchy__c>(), 
                idToAccount, 
                new Map<String, Integer>(), 
                new Map<Id, Set<String>>(),
                new Set<String>(),
                customerERPToAccount,
                new Map<String, Account_Sales_Area__c>(),
                new List<Apttus_Config2__PriceListItem__c>(),
                new Map<String, Map<String, List<Apttus_Config2__PriceListItem__c>>>(),
                agreementLinesUpdated
            );
        }

        /* parameterized constructor for CLM */
        public SupportData( Map<Id, Apttus__APTS_Agreement__c> idToAgreement, 
                            Map<Id, Product2> idToProduct, 
                            ApprovalMatricesWrapper approvalMatricesWrapper, 
                            Map<Id, Approval_Hierarchy__c> userIdToApprovalHierarcy, 
                            Map<Id, Account> idToAccount, 
                            Map<String, Integer> approvalKeyToPriority, 
                            Map<Id, Set<String>> matrixIdToProductNumbers,
                            Set<String> materialNumbers,
                            Map<String,Account> customerERPToAccount,
                            Map<String,Account_Sales_Area__c> aliToAccountSalesArea,
                            List<Apttus_Config2__PriceListItem__c> priceListItems,
                            Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>> productIdToPriceListItem, 
                            Set<Id> agreementLinesUpdated)
        {
            this.idToAgreement = idToAgreement;
            this.idToProduct = idToProduct;
            this.approvalMatricesWrapper = approvalMatricesWrapper;
            this.userIdToApprovalHierarcy = userIdToApprovalHierarcy;
            this.idToAccount = idToAccount;
            this.approvalKeyToPriority = approvalKeyToPriority;
            this.matrixIdToProductNumbers = matrixIdToProductNumbers;
            this.materialNumbers = materialNumbers;
            this.customerERPToAccount = customerERPToAccount;
            this.aliToAccountSalesArea = aliToAccountSalesArea;
            this.priceListItems = priceListItems;
            this.productIdToPriceListItem = productIdToPriceListItem;
            this.agreementLinesUpdated = agreementLinesUpdated;
        }
    }
    /*
    *   @description:
    *   Used in stamping Quote Header values after Pipeline is finished executing
    */
    public class QuoteHeaderUpdates implements IApprovalsParentRecordUpdates {
        public Map<Id, QuoteHeaderUpdateFields> idToUpdates;

        /* constructor */
        public QuoteHeaderUpdates()
        {
            idToUpdates = new Map<Id, QuoteHeaderUpdateFields>();
        }

        /* setter method for stamping approval errors found during pipeline execution */
        public void setApprovalError(Id quoteId, String approvalError)
        {
            confirmQuoteIdPresent(quoteId);
            idToUpdates.get(quoteId).approvalError = approvalError;
        }

        /* setter method for stamping approval hierarchy for non transborder scenario found during pipeline execution */
        public void setHierarchyOwner(Id quoteId, Id hierarchyOwner)
        {
            confirmQuoteIdPresent(quoteId);
            idToUpdates.get(quoteId).hierarchyOwner = hierarchyOwner;
        }

        /* setter method for stamping approval hierarchy for transborder scenario found during pipeline execution */
        public void setTransborderHierarchyOwner(Id quoteId, Id transborderHierarchyOwner)
        {
            confirmQuoteIdPresent(quoteId);
            idToUpdates.get(quoteId).transborderHierarchyOwner = transborderHierarchyOwner;
        }
        /* adds quote id to Map if not present */
        private void confirmQuoteIdPresent(Id quoteId)
        {
            if (!idToUpdates.containsKey(quoteId))
            {
                idToUpdates.put(quoteId, new QuoteHeaderUpdateFields());
            }
        }
    }

    /*
    *   @description:
    *   Contains Quotation Header Level fields which are stamped after approval pipeline execution
    */
    public class QuoteHeaderUpdateFields implements IApprovalsParentRecordUpdate {

        public String approvalError;
        public Id hierarchyOwner;
        public Id transborderHierarchyOwner;

        /* sets quotation header level field values */
        public void updateHeaderRecord(Object header)
        {
            Apttus_Proposal__Proposal__c quote = (Apttus_Proposal__Proposal__c)header;

            quote.Sales_Discretionary_Approval_Error__c = approvalError;
            quote.Approval_Hierarchy_Record_Owner__c = hierarchyOwner;
            quote.Approval_Hierarchy_Transborder__c = transborderHierarchyOwner;

            ilib_LogEvent.message('Quote ' + quote.Id + ' Values\n' +
                'hierarchyOwner = ' + hierarchyOwner + '\n' +
                'transborderHierarchyOwner = ' + transborderHierarchyOwner + '\n' +
                'approvalError = ' + approvalError
            );
        }
    }

    /*
    *   @description:
    *   Contains collections regarding Data collected after every step execution
    *   Stores hierarchy, level, category, and error information
    *   Values are copied to Output wrapper for every step
    */
    public class StepResults {

        public Boolean approvalFound = false;  // was an approval result found
        public Boolean isMFNApprovalLine = false; //DCP-49429

        public HierarchyAndLevel discount = new HierarchyAndLevel();
        public HierarchyAndLevel discountUC = new HierarchyAndLevel();

        public Set<String> approvalCategories = new Set<String>();
        public Boolean requiresApprovalWithoutCategory = false;

        public Set<Id> quotesWithMatrixError = new Set<Id>();
        public Map<Id, String> erroredQuoteIdToAccount = new Map<Id, String>();
        public Map<Id, Set<Id>> erroredQuoteIdToOwnerIds = new Map<Id, Set<Id>>();
        
        // CLM fields
        public Set<Id> agreementsWithHierarchyError = new Set<ID>();
        public Set<Id> agreementsWithMatrixError = new Set<ID>();
        public Set<Id> agreementstoRevert = new Set<ID>();
        public Set<Id> agreementstoRemoveFromMatrixError = new Set<ID>();
    }

    // TODO: this might need to be something typed/inherited
    /*
    *   @description:
    *   Contains final values which will be used in line level and header level value stamping
    *   After every step execution, StepResults data is copied to Output wrapper   
    */
    public class Outputs {
        public ApprovalsResults approvalsResults;

        // QUESTION: should we bundle up the error collections in to a class?
        // Does it also need to be typed in which case the whole outputs should be
        public Set<Id> quotesWithMatrixError;
        public Map<Id, String> erroredQuoteIdToAccount;
        public Map<Id, Set<Id>> erroredQuoteIdToOwnerIds;

        // CLM fields
        public Set<Id> agreementsWithHierarchyError;
        public Set<Id> agreementsWithMatrixError;
        public Set<Id> agreementsToRevert;
        public Set<Id> agreementstoRemoveFromMatrixError;
        
        public Custom_Approval_Matrix__c materialNumberRecordOwnerMatrix;
        public Custom_Approval_Matrix__c materialGroup1RecordOwnerMatrix;
        public Custom_Approval_Matrix__c discountRecordOwnerMatrix;
        public Custom_Approval_Matrix__c materialNumberCustomMatrix;
        public Custom_Approval_Matrix__c materialGroup1CustomMatrix;
        public Custom_Approval_Matrix__c discountCustomMatrix;
        

        /* constructor */
        public Outputs()
        {
            approvalsResults = new ApprovalsResults();

            quotesWithMatrixError = new Set<Id>();
            erroredQuoteIdToAccount = new Map<Id, String>();
            erroredQuoteIdToOwnerIds = new Map<Id, Set<Id>>();

            // CLM fields
            agreementsWithHierarchyError = new Set<ID>();
            agreementsWithMatrixError = new Set<ID>();
            agreementsToRevert = new Set<ID>();
            agreementstoRemoveFromMatrixError = new Set<ID>();


        }
    }

    /*
    *   @description:
    *   Contains details regarding hierarchy and level for any approval step execution
    */
    public class HierarchyAndLevel {
        public Boolean isValidHierarchyFound { get; private set; }
        public Id hierarchy { get; private set; }
        public Integer level { get; private set; }
        
        /* constructor */
        public HierarchyAndLevel()
        {
            this.hierarchy = null;
            this.level = null;
            this.isValidHierarchyFound = false;
        }
        /* parameterized constructor */
        public HierarchyAndLevel(Boolean isValidHierarchyFound, Id hierarchy, Integer level)
        {
            this.isValidHierarchyFound = isValidHierarchyFound;
            this.hierarchy = hierarchy;
            this.level = level;
        }
    }

    /*
    *   @description:
    *   Contains booleans to store for output what kind of approval is found in each step per line item
    */
    public class FoundHierarchies {
        public Boolean promotion = false;
        public Boolean materialNumber = false;
        public Boolean materialGroup = false;
        public Boolean discount = false;
        public Boolean customMaterialNumber = false;
        public Boolean customMaterialGroup = false;
        public Boolean customDiscount = false;
    }

    /*
    *   @description:
    *   Contains collections custom approval matrix data
    *   Matrices are segregated into various collections based on record type
    *   This is used to isolate a list of specific matrix to iterate upon
    *   Depending the type of approval
    */
    public class ApprovalMatricesWrapper {
        // all records
        public Map<Id, Custom_Approval_Matrix__c> idToMatrix { get; set; }

        // promotion collections
        public Map<String, List<Custom_Approval_Matrix__c>> promoCodeToMatrices { get; set; }

        // material number collections
        public Set<Id> materialNumberMatrixIds { get; set; }
        public List<Custom_Approval_Matrix__c> materialNumberMatrices { get; set; }
        public List<Custom_Approval_Matrix__c> customMaterialNumberMatrices { get; set; }

        // material group collections
        public Map<Id, Set<String>> idToMaterialGroups { get; set; }
        public Map<Id, Set<String>> idToCustomMaterialGroups { get; set; }
        public List<Custom_Approval_Matrix__c> materialGroupMatrices { get; set; }
        public List<Custom_Approval_Matrix__c> customMaterialGroupMatrices { get; set; }

        // discount collections
        public List<Custom_Approval_Matrix__c> discountMatrices { get; set; }
        public List<Custom_Approval_Matrix__c> customDiscountMatrices { get; set; }

        /* constructor */
        public ApprovalMatricesWrapper()
        {
            idToMatrix = new Map<Id, Custom_Approval_Matrix__c>();
            promoCodeToMatrices = new Map<String, List<Custom_Approval_Matrix__c>>();
            materialNumberMatrixIds = new Set<Id>();
            materialNumberMatrices = new List<Custom_Approval_Matrix__c>();
            customMaterialNumberMatrices = new List<Custom_Approval_Matrix__c>();
            idToMaterialGroups = new Map<Id, Set<String>>();
            idToCustomMaterialGroups = new Map<Id, Set<String>>();
            materialGroupMatrices = new List<Custom_Approval_Matrix__c>();
            customMaterialGroupMatrices = new List<Custom_Approval_Matrix__c>();
            discountMatrices = new List<Custom_Approval_Matrix__c>();
            customDiscountMatrices = new List<Custom_Approval_Matrix__c>();
        }     
    }

    /*
    *   @description:
    *   Used in stamping Agreement Header values after Pipeline is finished executing
    */
    public class AgreementHeaderUpdates implements IApprovalsParentRecordUpdates {
        public Map<Id, Apttus__APTS_Agreement__c> idToAgreement;
        public List<Apttus__AgreementLineItem__c> existingAgreementLines;
        public Map<Id, Id> agreementIdToHierarchyId;
        public Set<Id> agreementsToUpdate;
        public Set<Id> agreementsToRevert;
        public Set<Id> agreementsWithHierarchyError;
        public Set<Id> agreementsWithMatrixError;
        public Set<Id> agreementLinesUpdated;

        /* constructor */
        public AgreementHeaderUpdates(SupportData supportData)
        {
            idToAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
            agreementIdToHierarchyId = new Map<Id, Id>();
            agreementsToUpdate = new Set<Id>();
            agreementsToRevert = new Set<Id>();
            agreementsWithHierarchyError = new Set<Id>();
            agreementsWithMatrixError = new Set<Id>();
            agreementLinesUpdated = supportData.agreementLinesUpdated;
            existingAgreementLines = new ApttusAgreementLineItemSelectors().selectByAgreementId(supportData.idToAgreement.keySet());
        }

        private String getRecordTypeInfo(Apttus__APTS_Agreement__c agreement)
        {
            String rtName = null;
            Map<Id, RecordTypeInfo> agreementRecordTypeinfo = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
            if(agreementRecordTypeinfo.containsKey(agreement.RecordTypeId)) {
                rtName = agreementRecordTypeinfo.get(agreement.RecordTypeId).getDeveloperName();
            }

            return rtName;
        }

        private Boolean isMatrixFound(Id agreementId)
        {
            return agreementsWithMatrixError.contains(agreementId);
        }

        private Id getHierarchyOfOwner(Id agreementId)
        {
            return agreementIdToHierarchyId.get(agreementId);
        }

        private Boolean isHierarchyFound(Id agreementId)
        {
            return !agreementsWithMatrixError.contains(agreementId) && agreementsWithHierarchyError.contains(agreementId);
        }

        private String getApprovalStatusWhenHierarchyNotFound(Id agreementId, String oldApprovalStatus)
        {
            String approvalStatus = oldApprovalStatus;
            if(!agreementsWithMatrixError.contains(agreementId) && agreementsWithHierarchyError.contains(agreementId))
            {
                if(agreementsToUpdate.contains(agreementId)) 
                {
                    approvalStatus = APPROVAL_STATUS_REQUIRED;
                }
            }
            return approvalStatus;
        }

        private String getApprovalStatus(Apttus__APTS_Agreement__c agreement)
        {
            String rTName = getRecordTypeInfo(agreement);
            String approvalStatus = agreement.Apttus_Approval__Approval_Status__c;

            Boolean isAgreementErrorFree = !agreementsWithMatrixError.contains(agreement.Id) && !agreementsWithHierarchyError.contains(agreement.Id);

            if (agreementsToUpdate.contains(agreement.Id)
                && agreement.Apttus_Approval__Approval_Status__c != APPROVAL_STATUS_PENDING
                && isAgreementErrorFree
            ) {
                approvalStatus = APPROVAL_STATUS_REQUIRED;
            }

            //CMCM-7846 Defect CMCM-11370 Include Special Programs to the list to override auto approval when category has a value
            Boolean doesCategoryOverrideAutoApprove = (
                rtName == Label.AgreementRecordTypeChannelPartner || rtName == Label.AgreementRecordTypeMasterService
                || rtName == Label.AgreementRecordTypeStandingQuote || rtName == Label.AgreementRecordTypeTender
                || rtName == Label.AgreementRecordTypeSpecialPrograms
            );

            if (agreementsToRevert.contains(agreement.Id) && !agreementsToUpdate.contains(agreement.Id)
                && isAgreementErrorFree
                && (!doesCategoryOverrideAutoApprove
                    || (doesCategoryOverrideAutoApprove && String.isBlank(agreement.Approval_Category__c))
                )
            ) {
                approvalStatus = System.Label.AgreementApprovalStatusApproved;
            }

            approvalStatus = getApprovalStatusWhenHierarchyNotFound(agreement.Id, approvalStatus);

            return approvalStatus;
        }

        /* Create set for lines that are already existing */
        public void updatesForExistingLines()
        {
            // if there are agreement line items
            // and
            // either all of them or none of them have been updated (?)
            // changing it to when any of the line is updated - INC0447800
            if (!existingAgreementLines.isEmpty() ||
                (!agreementLinesUpdated.isEmpty() || agreementLinesUpdated.size() == existingAgreementLines.size())//Updating the conditions to meet the old framework
            ) {
                for (Apttus__AgreementLineItem__c existingLine : existingAgreementLines)
                {
                    if (agreementLinesUpdated.contains(existingLine.Id)) {
                        continue;
                    }

                    Boolean doesStatusRequireUpdate = existingLine.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_REQUIRED
                        || existingLine.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_REJECTED
                        || existingLine.Apttus_Approval__Approval_Status__c == APPROVAL_STATUS_CANCELLED;

                    if (String.isNotBlank(existingLine.Approval_Category__c) && doesStatusRequireUpdate)// was a miss when changing from old approvals framework to a new one - INC0447800
                    {
                        agreementsToUpdate.add(existingLine.Apttus__AgreementId__c);
                    }
                    else
                    {
                        agreementsToRevert.add(existingLine.Apttus__AgreementId__c);
                    }
                } 
            }
            ilib_LogEvent.message('&&& Framework Update Agreement Set '+ agreementsToUpdate);
            ilib_LogEvent.message('&&& Framework Auto Approve Agreement Set '+ agreementsToRevert);

            updateAgreement();
        }

        /* Update the header based on the approvals on line items */
        private void updateAgreement()
        {
            ilib_LogEvent.message('&&& Inside UpdateAgreement');

            for(Apttus__APTS_Agreement__c agreement : idToAgreement.values())
            {
                Boolean isAutoApproved = false;
                String approvalStatus = getApprovalStatus(agreement);
                
                if(approvalStatus == System.Label.AgreementApprovalStatusApproved)
                {
                    isAutoApproved = true;
                }

                agreement.Approval_Matrix_Not_Found__c = isMatrixFound(agreement.Id) ;
                agreement.Approval_Hierarchy_Not_Found__c = isHierarchyFound(agreement.Id);
                agreement.Is_Auto_Approved__c = isAutoApproved;
                agreement.Approval_Hierarchy_Discount__c = getHierarchyOfOwner(agreement.Id);
                agreement.Apttus_Approval__Approval_Status__c = approvalStatus;
            }

            update idToAgreement.values();
        }
    }

    /*
    *   @description:
    *   Contains Data regarding all the final category, hierarchy, level, status calculated for the entire pipeline
    */
    public class ApprovalsResults {

        public Set<String> approvalCategories = new Set<String>();
        public Boolean requiresApprovalWithoutCategory = false;
        public Boolean isMFNApprovalLine = false; //DCP-49429
        public String approvalStatus {
            get
            {
                Boolean hasCategories = approvalCategories != null && !approvalCategories.isEmpty();
                return requiresApprovalWithoutCategory || hasCategories ? System.Label.ProposalApprovalStatusApprovalRequired : '';
            }
        }

        // keeps track of which steps found approval records
        public FoundHierarchies isHierarchyFound = new FoundHierarchies();

        // the specific approvals that can be found in all steps combined
        public HierarchyAndLevel promo1 = new HierarchyAndLevel();
        public HierarchyAndLevel promo2 = new HierarchyAndLevel(); //DCP-25340, Added levels for 5 promotion fields 
        public HierarchyAndLevel promo3 = new HierarchyAndLevel();
        public HierarchyAndLevel promo4 = new HierarchyAndLevel();
        public HierarchyAndLevel promo5 = new HierarchyAndLevel();
        public HierarchyAndLevel discount = new HierarchyAndLevel();
        public HierarchyAndLevel discountUC = new HierarchyAndLevel();

        // The below three were previously commented, uncommented now by Satya
        public HierarchyAndLevel customDiscount = new HierarchyAndLevel();
        public HierarchyAndLevel customMaterialNumber = new HierarchyAndLevel();
        public HierarchyAndLevel customMaterialGroup = new HierarchyAndLevel();
    }

    /*
    *   @description:
    *   Used in storing the final Matrix information selected in every step
    */
    public class MatrixWrapper {

        public Custom_Approval_Matrix__c record;
        public Boolean isDiscountUnderLevel1;
        public Integer approvalLevel;
        public Id ownerId;
        public string hierarchyType;

        /* default values */
        public MatrixWrapper(Id ownerId)
        {
            this.record = null;
            this.isDiscountUnderLevel1 = false;
            this.approvalLevel = null;
            this.ownerId = ownerId;
        }

        /* parameterized constructor */
        public MatrixWrapper(Custom_Approval_Matrix__c record, Boolean isDiscountUnderLevel1, Integer approvalLevel, Id ownerId)
        {
            this.record = record;
            this.isDiscountUnderLevel1 = isDiscountUnderLevel1;
            this.approvalLevel = approvalLevel;
            this.ownerId = ownerId;
        }

        /*
         * New Constructor to add parameter hierarchyType
		*/
        public MatrixWrapper(Custom_Approval_Matrix__c record, Boolean isDiscountUnderLevel1, Integer approvalLevel, Id ownerId, string hierarchyType)
        {
            this.record = record;
            this.isDiscountUnderLevel1 = isDiscountUnderLevel1;
            this.approvalLevel = approvalLevel;
            this.ownerId = ownerId;
            this.hierarchyType = hierarchyType;
        }
    }
    
    /*
    *   @description:
    *   Used in storing the candidate matrix information
    *   More than 1 candidate matrix can be generated in every step
    *   Best candidate matrix will be selected based on algorithm designed
    *   Example implementation can be seen in ApprovalStepBase.findHighestPriorityMatrix()
    */
    public class CandidateMatrix {
        public Boolean isApprovalMatrixFound;
        public Custom_Approval_Matrix__c record;
        public Integer priority;
        public Datetime lastModified;

        /* default values */
        public CandidateMatrix()
        {
            this.isApprovalMatrixFound = false;
            this.record = null;
            this.priority = null;
            this.lastModified = null;
        }

        /* parameterized constructor */
        public CandidateMatrix(Boolean isApprovalMatrixFound, Custom_Approval_Matrix__c record, Integer priority, Datetime lastModified)
        {
            this.isApprovalMatrixFound = isApprovalMatrixFound;
            this.record = record;
            this.priority = priority;
            this.lastModified = lastModified;
        }
    }

    /*
    *   @description:
    *   Used in storing Account Useful Data
    *   Applied in algorithm for matrix selection
    *   to check if matrix contains respective account data values
    */
    public class AccountData {

        public String region;
        public String country;
        public Id ownerId;

        /* parameterized constructor */
        public AccountData(String region, String country, Id ownerId)
        {
            this.region = region;
            this.country = country;
            this.ownerId = ownerId;
        }
    }

}