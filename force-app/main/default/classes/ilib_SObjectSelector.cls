/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *    may be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * Class providing common database query support for abstracting and encapsulating query logic
 **/
public abstract with sharing class ilib_SObjectSelector implements ilib_ISObjectSelector
{
    /**
     * This overrides the Multi Currency handling, preventing it from injecting the CurrencyIsoCode field for certain System objects that don't ever support it
     **/
    private final static Set<String> STANDARD_WITHOUT_CURRENCYISO = new Set<String> {
        'ApexClass', 'ApexTrigger', 'AsyncApexJob', 'Attachment', 'RecordType', 'UserTerritory2Association', 'ObjectTerritory2Association', 'Territory2Type'
        //Akshay 06-June-2018 Add objects which don't have this field
        ,'OpportunityContactRole','Sales_Area__mdt','Post_Pricing_Message__mdt','Code_Parameter__mdt','PermissionSetAssignment','ContentDocumentLink','EmailTemplate','Price_List__mdt','Campaign_Member_Status__mdt','Company_Code_Address__mdt','CountryRegionMapping__mdt','CampaignMemberStatus','Profile',
        //Sarath 29-Nov-2018
        'Interface_Detail__mdt','ContentDocument','Send_Email_Setting__mdt' /*Added ContentDocument-Pankaj Singla*/
        ,'EmailMessage' /*Added EmailMessage-Vaibhav Parashar*/
        ,'Product_Detail__mdt' /*Anish - DCP-25208 - Quantity Increase for Informatics*/
        ,'Informatics_Product__mdt' /*DCP-31767 - Informatics Products*/
         ,'Group'/*DCP-32166*/
		,'Product_Detail__mdt' /*Anish - DCP-25208 - Quantity Increase for Informatics*/
                 ,'Time_Zones__mdt'/*Himanshu-DCP-46943 - Pending Approval Notification*/
		,'CurrencyType' /*DCP-34078*/
        ,'Agreement_Condition_Table_Type_Mapping__mdt' /*DCP-31673*/
        ,'Material_Group__mdt' /*DCP-32049*/
        ,'Agreement_Line_Items_Required__mdt'/*DCP-33720*/,
        'Prospect_Scoring_Metadata__mdt' /* Pankaj Singla DCP-35844*/ ,
        'Promotion_To_Incentive_Mapping__mdt',
        'Approval_Priority_Combination__mdt', /* Roopal Verma TASK0537677*/
        'Vote' /*Adyasha Satapathy DCP-43356*/	,
		'Agreement_Import_Offline_Condition_Table__mdt',/*Joshith K DCP-43693*/
        'Knowledge_Sync_Mapping__mdt', /*Adyasha Satapathy DCP-43401*/
		'CLM_Preferred_Language_To_Template__mdt',/*Rishab Wali -- DCP-37232*/ 
        'Region_to_Email_Mapping__mdt',/*Rishi Sharma -- DCP-46376,Anand Palla -- DCP-46168*/ 
        'Product_End_Date_Setting__mdt',/*Prem Ranjan --DCP-48133*/
        'Calendar',
        'BusinessHours',
		'OrgWideEmailAddress',/*Rishab Wali -- DCP-46920 */
        'ContentNote',/*Nishan Shetty--SPQ-15*/
		'Dragen_Products__mdt',/*Maruthi IP2 - 34*/
        'Product_Code_to_Subscription_Map__mdt',/*Rishi Sharma IP2 - 175*/
        'CronTrigger',  /*Ashwin Kumar - DCP-52339*/
        'Report', /* Saddam - PM-41 */
		'AccountHistory', /* Maruthi Ticket TASK0754014 */
        'Email_Verification_Matrix__mdt', /*Ashwin Kumar - INC0403213 */
        'CaseComment',/*Saptarshi - QACM-175 */
        'CaseHistory',/*Saptarshi - QACM-175 */
        'R_Q_Contact_Eligible_Countries__mdt', /*Balakrishna - CMCM-2266 */ 
        'Business_Hours_Setting__mdt' /* Venkatesh prabhu CMCM-12168*/
    };

    /**
     * This overrides the automatic date stamp handling, preventing it from injecting the CreatedDate field for certain System objects that don't ever support it
     **/
    private final static Set<String> STANDARD_WITHOUT_CREATEDDATE = new Set<String> {'UserTerritory2Association', 'ObjectTerritory2Association','PermissionSetAssignment'
                                                                                //Akshay 06-Aug-2018 Add objects which don't have this field
                                                                                ,'ContentDocumentLink','AccountHistory'};

    /**
     * Should this selector automatically include the FieldSet fields when building queries?
     **/
    private Boolean mIncludeFieldSetFields;

    /**
     * Enforce FLS Security
     **/
    private Boolean mEnforceFLS;

    /**
     * Enforce CRUD Security
     **/
    private Boolean mEnforceCRUD;

    /**
    * Order by field
    **/
    private String mOrderBy;

    /**
     * Sort the query fields in the select statement (defaults to true, at the expense of performance).
     * Switch this off if you need more performant queries.
     **/
    private Boolean mSortSelectFields;

    /**
     * Describe helper
     **/
    private ilib_SObjectDescribe describeWrapper
    {
        get {
            if (describeWrapper == null)
                describeWrapper = ilib_SObjectDescribe.getDescribe(getSObjectType());
            return describeWrapper;
        }
        set;
    }

    /**
     * Implement this method to inform the base class of the SObject (custom or standard) to be queried
     **/
    abstract Schema.SObjectType getSObjectType();

    /**
     * Implement this method to inform the base class of the common fields to be queried or listed by the base class methods
     **/
    abstract List<Schema.SObjectField> getSObjectFieldList();

    /**
     * Constructs the Selector, defaults to not including any FieldSet fields automatically
     **/
    public ilib_SObjectSelector()
    {
        this(false);
    }

    /**
     * Constructs the Selector
     *
     * @param includeFieldSetFields Set to true if the Selector queries are to include Fieldset fields as well
     **/
    public ilib_SObjectSelector(Boolean includeFieldSetFields)
    {
        this(includeFieldSetFields, true, false);
    }

    /**
     * Constructs the Selector
     *
     * @param includeFieldSetFields Set to true if the Selector queries are to include Fieldset fields as well
     **/
    public ilib_SObjectSelector(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS)
    {
        this(includeFieldSetFields, enforceCRUD, enforceFLS, true);
    }

    /**
     * Constructs the Selector
     *
     * @param includeFieldSetFields Set to true if the Selector queries are to include Fieldset fields as well
     * @param enforceCRUD Enforce CRUD security
     * @param enforeFLS Enforce Field Level Security
     * @param sortSelectFields Set to false if selecting many columns to skip sorting select fields and improve performance
     **/
    public ilib_SObjectSelector(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields)
    {
        mIncludeFieldSetFields = includeFieldSetFields;
        mEnforceCRUD = enforceCRUD;
        mEnforceFLS = enforceFLS;
        mSortSelectFields = sortSelectFields;
    }

    /**
     * Override this method to provide a list of Fieldsets that can optionally drive inclusion of additional fields in the base queries
     **/
    public virtual List<Schema.FieldSet> getSObjectFieldSetList()
    {
        return null;
    }

    /**
     * Override this method to control the default ordering of records returned by the base queries,
     * defaults to the name field of the object or CreatedDate if there is none
     **/
    public virtual String getOrderBy()
    {
        if (mOrderBy == null)
        {
            if (getSObjectName().endsWith('Share') || STANDARD_WITHOUT_CREATEDDATE.contains(getSObjectName()))
                mOrderBy = 'Id';
            else
                mOrderBy = 'CreatedDate';
        }
        if (describeWrapper.getNameField() != null)
            mOrderBy = describeWrapper.getNameField().getDescribe().getName();

        return mOrderBy;
    }

    /**
     * Returns True if this Selector instance has been instructed by the caller to include Field Set fields
     **/
    public Boolean isIncludeFieldSetFields()
    {
        return mIncludeFieldSetFields;
    }

    /**
     * Returns True if this Selector is enforcing FLS
     **/
    public Boolean isEnforcingFLS()
    {
        return mEnforceFLS;
    }

    /**
     * Returns True if this Selector is enforcing CRUD Security
     **/
    public Boolean isEnforcingCRUD()
    {
        return mEnforceCRUD;
    }

    /**
     * Returns the string representaiton of the SObject this selector represents
     **/
    public String getSObjectName()
    {
        return describeWrapper.getDescribe().getName();
    }

    /**
     * Performs a SOQL query,
     *   - Selecting the fields described via getSObjectFieldsList and getSObjectFieldSetList (if included)
     *   - From the SObject described by getSObjectType
     *   - Where the Id's match those provided in the set
     *   - Ordered by the fields returned via getOrderBy
     * @returns A list of SObject's
     **/
    public List<SObject> selectSObjectsById(Set<Id> idSet)
    {
        return Database.query(buildQuerySObjectById());
    }

    /**
     * Performs a SOQL query,
     *   - Selecting the fields described via getSObjectFieldsList and getSObjectFieldSetList (if included)
     *   - From the SObject described by getSObjectType
     *   - Where the Id's match those provided in the set
     *   - Ordered by the fields returned via getOrderBy
     * @returns A QueryLocator (typically for use in a Batch Apex job)
     **/
    public Database.QueryLocator queryLocatorById(Set<Id> idSet)
    {
        return Database.getQueryLocator(buildQuerySObjectById());
    }

    /**
     * Public acccess for the getSObjectType during Mock registration
     *   (adding public to the existing method broken base class API backwards compatability)
     **/
    public SObjectType getSObjectType2()
    {
        return getSObjectType();
    }

    /**
     * Public acccess for the getSObjectType during Mock registration
     *   (adding public to the existing method broken base class API backwards compatability)
     **/
    public SObjectType sObjectType()
    {
        return getSObjectType();
    }

    /**
     * Returns a QueryFactory configured with the Selectors object, fields, fieldsets and default order by
     **/
    public ilib_QueryFactory newQueryFactory()
    {
        return newQueryFactory(mEnforceCRUD, mEnforceFLS, true);
    }

    /**
     * Returns a QueryFactory configured with the Selectors object, fields, fieldsets and default order by
     **/
    public ilib_QueryFactory newQueryFactory(Boolean includeSelectorFields)
    {
        return newQueryFactory(mEnforceCRUD, mEnforceFLS, includeSelectorFields);
    }

    /**
     * Returns a QueryFactory configured with the Selectors object, fields, fieldsets and default order by
     * CRUD and FLS read security will be checked if the corresponding inputs are true (overrides that defined in the selector).
     **/
    public ilib_QueryFactory newQueryFactory(Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields)
    {
        // Construct QueryFactory around the given SObject
        return configureQueryFactory(
            new ilib_QueryFactory(getSObjectType2()),
                assertCRUD, enforceFLS, includeSelectorFields);
    }

    /**
     * Adds the selectors fields to the given QueryFactory using the given relationship path as a prefix
     *
     * // TODO: This should be consistant (ideally) with configureQueryFactory below
     **/
    public void configureQueryFactoryFields(ilib_QueryFactory queryFactory, String relationshipFieldPath)
    {
        // Add fields from selector prefixing the relationship path
        for (SObjectField field : getSObjectFieldList())
            queryFactory.selectField(relationshipFieldPath + '.' + field.getDescribe().getName());

        // Automatically select the CurrencyIsoCode for MC orgs (unless the object is a known exception to the rule)
        if (hasCurrencyField())
            queryFactory.selectField(relationshipFieldPath + '.CurrencyIsoCode');
    }

    /**
     * Adds a subselect QueryFactory based on this selector to the given QueryFactor, returns the parentQueryFactory
     **/
    public ilib_QueryFactory addQueryFactorySubselect(ilib_QueryFactory parentQueryFactory)
    {
        return addQueryFactorySubselect(parentQueryFactory, true);
    }

    /**
     * Adds a subselect QueryFactory based on this selector to the given QueryFactor
     **/
    public ilib_QueryFactory addQueryFactorySubselect(ilib_QueryFactory parentQueryFactory, Boolean includeSelectorFields)
    {
        ilib_QueryFactory subSelectQueryFactory =
            parentQueryFactory.subselectQuery(getSObjectType2());
        return configureQueryFactory(
            subSelectQueryFactory,
            mEnforceCRUD,
            mEnforceFLS,
            includeSelectorFields);
    }

    /**
     * Adds a subselect QueryFactory based on this selector to the given QueryFactor, returns the parentQueryFactory
     **/
    public ilib_QueryFactory addQueryFactorySubselect(ilib_QueryFactory parentQueryFactory, String relationshipName)
    {
        return addQueryFactorySubselect(parentQueryFactory, relationshipName, TRUE);
    }

    /**
     * Adds a subselect QueryFactory based on this selector to the given QueryFactor
     **/
    public ilib_QueryFactory addQueryFactorySubselect(ilib_QueryFactory parentQueryFactory, String relationshipName, Boolean includeSelectorFields)
    {
        ilib_QueryFactory subSelectQueryFactory = parentQueryFactory.subselectQuery(relationshipName);
        return configureQueryFactory(subSelectQueryFactory, mEnforceCRUD, mEnforceFLS, includeSelectorFields);
    }

    /**
     * Constructs the default SOQL query for this selector, see selectSObjectsById and queryLocatorById
     **/
    private String buildQuerySObjectById()
    {
        return newQueryFactory().setCondition('id in :idSet').toSOQL();
    }

    /**
     * Configures a QueryFactory instance according to the configuration of this selector
     **/
    private ilib_QueryFactory configureQueryFactory(ilib_QueryFactory queryFactory, Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields)
    {
        // CRUD and FLS security required?
        if (assertCRUD)
        {
            try
            {
                // Leverage QueryFactory for CRUD checking
                queryFactory.assertIsAccessible();
            }
            catch (ilib_SecurityUtils.CrudException e)
            {
                // Marshal exception into DomainException for backwards compatability
                throw new ilib_SObjectDomain.DomainException(
                    'Permission to access an ' + getSObjectName() + ' denied.');
            }
        }
        queryFactory.setEnforceFLS(enforceFLS);

        // Configure the QueryFactory with the Selector fields?
        if (includeSelectorFields)
        {
            // select the Selector fields and Fieldsets and set order
            queryFactory.selectFields(getSObjectFieldList());

            List<Schema.FieldSet> fieldSetList = getSObjectFieldSetList();
            if (mIncludeFieldSetFields && fieldSetList != null)
                for (Schema.FieldSet fieldSet : fieldSetList)
                    queryFactory.selectFieldSet(fieldSet);

            // Automatically select the CurrencyIsoCode for MC orgs (unless the object is a known exception to the rule)
            if (hasCurrencyField())
                queryFactory.selectField('CurrencyIsoCode');
        }

        // Parse the getOrderBy()
        for (String orderBy : getOrderBy().split(','))
        {
           
            List<String> orderByParts = orderBy.trim().split(' ');
            String fieldNamePart = orderByParts[0];
            String fieldSortOrderPart = orderByParts.size() > 1 ? orderByParts[1] : null;
            String fieldNullPart = orderByParts.size() > 2 ? orderByParts[3] : null;//DCP-52703 [Adding support for NULLS LAST]
            ilib_QueryFactory.SortOrder fieldSortOrder = ilib_QueryFactory.SortOrder.ASCENDING;
            if (fieldSortOrderPart==null)
                fieldSortOrder = ilib_QueryFactory.SortOrder.ASCENDING;
            else if (fieldSortOrderPart.equalsIgnoreCase('DESC'))
                fieldSortOrder = ilib_QueryFactory.SortOrder.DESCENDING;
            else if (fieldSortOrderPart.equalsIgnoreCase('ASC'))
                fieldSortOrder = ilib_QueryFactory.SortOrder.ASCENDING;
            
            if(fieldNullPart!=null && fieldNullPart.equalsIgnoreCase('LAST')){
                queryFactory.addOrdering(fieldNamePart, fieldSortOrder,true);
            } else {
                queryFactory.addOrdering(fieldNamePart, fieldSortOrder);
            }
        }

        queryFactory.setSortSelectFields(mSortSelectFields);

        return queryFactory;
    }

    private Boolean hasCurrencyField()
    {
        return (Userinfo.isMultiCurrencyOrganization() &&
                !getSObjectName().endsWith('Share') &&
                !STANDARD_WITHOUT_CURRENCYISO.contains(getSObjectName())
        );
    }

}