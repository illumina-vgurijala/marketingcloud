/**
*   @author Charket
*   @date 12-Oct-2023
*
*   @description Class to get the records based on different conditions
*  Modification Log:
 *  -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Charket                       29-Mar-2024          Add new field to selectWeChatAccountsById field, 
 *      Charket                       29-Mar-2024          Removed limit from selectContactByEmail and selectContactByAlternateEmail methods
 *      Charket                       29-Mar-2024          Added new methods: selectWeChatAccountByOriginId, selectWeChatFollowerByOpenId, selectWeChatFollowerById, selectOpenTranscriptByFollowerId, selectVerifiedFollowerByUnionId,
 *                                                         selectOpenTranscriptsByAgentId, selectAccountSpecialistById, selectActiveCustomerCareAgentByUserId, selectRandomCustomerCareOnlineAgent, selectAgentStatusByName
 *  -------------------------------------------------------------------------------------------------------------------
 */
public inherited sharing class CharketSelector {
    private static final String LOG_TITLE = 'CharketSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String CUSTOMER_CARE_USER_ROLE = 'Customer Care Specialist';
    private static final String USED_FOR_CUSTOMER_CARE = 'Customer Care';

    /**
     * constructor
     **/
    public CharketSelector(){}

    /**
     *  @author Charket
     *  @description query wechat account records filtered by Id
     *  @param wechatAccountId String
     *  @return List<Charket__WeChatAccount__c>
     */
    public List<Charket__WeChatAccount__c> selectWeChatAccountsById(String wechatAccountId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatAccountsById', wechatAccountId);

        List<Charket__WeChatAccount__c> res = [
            SELECT Id, Charket__SalesforceEndpoint__c, OpenIdAesKey__c, DataPrivacyPolicy__c, AesKeySize__c, Charket__AppId__c
            FROM Charket__WeChatAccount__c
            WHERE Id= :wechatAccountId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
                logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description query wechat account records filtered by origin Id
     *  @param wechatAccountId String
     *  @return Charket__WeChatAccount__c
     */
    public Charket__WeChatAccount__c selectWeChatAccountByOriginId(String originId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatAccountByOriginId', originId);

        List<Charket__WeChatAccount__c> res = [
            SELECT Id, Charket__SalesforceEndpoint__c, OpenIdAesKey__c, DataPrivacyPolicy__c, AesKeySize__c
            FROM Charket__WeChatAccount__c
            WHERE Charket__WeChatOriginId__c = :originId];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
                logger.stop(res.size());

        if(res.size() > 0) 
            return res[0];

        return null;
    }

    /**
     *  @author Charket
     *  @description get cases with wechat comment
     *  @param String wechatfollowerId
     *  @param Set<String> caseStatuses
     *  @param String caseCommentType
     *  @return List<Case>
     */
    public List<Case> selectOpenCasesWithWeChatComments(String wechatfollowerId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenCasesWithWeChatComments', wechatfollowerId);
        }
        
        List<Case> res = [
            SELECT
                Id,
                CaseNumber,
                Subject,
                Description,
                CreatedDate,
                Status,
                Installed_Product_Serial_Number__c,
                (
                    SELECT Comment__c
                    FROM WeChat_Comments__r
                    WHERE Type__c = 'Original Description'
                    LIMIT 1
                )
            FROM Case
            WHERE
                (Status = 'Initiated'
                OR Status = 'Awaiting Response - Customer'
                OR Status = 'Awaiting Response - Internal'
                OR Status = 'In Progress')
                AND WeChatFollower__c = :wechatfollowerId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    } 

    /**
     *  @author Charket
     *  @description get cases by number
     *  @param String caseNumber
     *  @return List<Case>
     */
    public List<Case> selectCaseByCaseNumber(String caseNumber) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseByCaseNumber', caseNumber);

        List<Case> res = [
            SELECT Id, Subject, CaseNumber, Description
            FROM Case
            WHERE CaseNumber = :caseNumber
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 

    /**
     * @author Charket
     * @description get Install Products by Serial/Lot Number.
     * @param setSerialLotNumbers
     * @return List<SVMXC__Installed_Product__c>
     */
    public List<SVMXC__Installed_Product__c> selectInstalledProduct(String serialLotNumber)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProduct', serialLotNumber);

        List<SVMXC__Installed_Product__c> res = [
            SELECT Id
            FROM SVMXC__Installed_Product__c
            WHERE SVMXC__Serial_Lot_Number__c = :serialLotNumber
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Charket
     * @description get Install Products by Serial/Lot Number.
     * @param setSerialLotNumbers
     * @return List<SVMXC__Installed_Product__c>
     */
    public List<SVMXC__Installed_Product__c> selectInstalledProductBySerialLotNumber(String serialLotNumber)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectInstalledProductBySerialLotNumber', serialLotNumber);

        List<SVMXC__Installed_Product__c> res = [
            SELECT Id, Name, SVMXC__Company__c
            FROM SVMXC__Installed_Product__c
            WHERE SVMXC__Serial_Lot_Number__c = :serialLotNumber AND SVMXC__Company__c != NULL
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Charket
     * @description Get AccountContactRelation by Email.
     * @param accountId String
     * @param email String
     * @return List<AccountContactRelation>
     */
    public List<AccountContactRelation> selectAccountContactRelationByEmail(String accountId, String email)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountContactRelationByEmail', accountId + '|' + email);

        List<AccountContactRelation> res = [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE
                AccountId = :accountId
                AND IsActive = TRUE
                AND Contact.Is_Active__c = TRUE
                AND Contact.Email = :email
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @author Charket
     * @description Get AccountContactRelation by Email.
     * @param accountId String
     * @param email String
     * @return List<AccountContactRelation>
     */
    public List<AccountContactRelation> selectAccountContactRelationByAlternateEmail(String accountId, String email)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountContactRelationByAlternateEmail', accountId + '|' + email);

        List<AccountContactRelation> res = [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE
                AccountId = :accountId
                AND IsActive = TRUE
                AND Contact.Is_Active__c = TRUE
                AND Contact.Alternate_Email__c = :email
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /*
    * @author Charket
    * @description get contact by email
    * @param email String
    * @return List<Contact>
    *
    */
    public List<Contact> selectContactByEmail(String email)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactByEmail', email);

        List<Contact> res = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Email = :email AND Is_Active__c = TRUE
            ORDER BY LastModifiedDate DESC
        ];

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }
    
    /*
    * @author Charket
    * @description get contact by alternate email
    * @param email String
    * @return List<Contact>
    *
    */
    public List<Contact> selectContactByAlternateEmail(String email)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactByAlternateEmail', email);

        List<Contact> res = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Alternate_Email__c = :email AND Is_Active__c = TRUE
            ORDER BY LastModifiedDate DESC
        ];

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /*
    * @author Charket
    * @description get contact by id
    * @param id String
    * @return List<Contact>
    *
    */
    public List<Contact> selectContactById(Id contactId)
    {
        ilib_LogQuery logger;

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContactById', contactId);

        List<Contact> res = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

    /**
    *  @author Charket
    *  @description get ContentVersion by Id
    *  @param contentVersionId Id
    *  @return List<ContentVersion>
    **/
    public List<ContentVersion> selectContentVersionById(Id contentVersionId) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectContentVersionById', contentVersionId);
        }    
        List<ContentVersion> res = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*
     *  @author Charket
     *  @description get ContentDocumentLink 
     *  @param linkedEntityIds Set<Id>
     *  @return List<ContentDocumentLink>
     */
    public List<ContentDocumentLink> selectContentDocumentLinks(Set<Id> linkedEntityIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDocumentLinks', UtilsCollection.serializeIds(linkedEntityIds));
        }
        
        List<ContentDocumentLink> res = [
            SELECT ContentDocumentID, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :linkedEntityIds
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }

    /**
    *  @author Charket
    *  @description get ContentVersion details by ContentDocumentId
    *  @param Set<ID> contentDocumentIds
    *  @return List<ContentVersion>
    **/
    public List<ContentVersion> selectContentVersionByCDIds(Set<ID> contentDocumentIds) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectContentVersionByCDIds', UtilsCollection.serializeIds(contentDocumentIds));
        }

        List<ContentVersion> res = [
            SELECT Id, ContentDocumentId, title
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            ORDER BY CreatedDate DESC
        ];
        
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

     /**
    *  @author Charket
    *  @description get ContentDistribution details by Content Version Id
    *  @param contentVersions List<ContentVersion>
    *  @return List<ContentDistribution>
    **/
    public List<ContentDistribution> selectContentDistributionByCVs(List<ContentVersion> contentVersions) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) 
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDistributionByCVs', String.valueOf(contentVersions));
        
        List<ContentDistribution> res = [
            SELECT Id, Name, ContentVersionId, DistributionPublicUrl
            FROM ContentDistribution
            WHERE ContentVersionId IN :contentVersions AND PreferencesAllowViewInBrowser = TRUE
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Charket
     *  @description get wechat cases
     *  @param String caseId
     *  @return List<Case>
     */
    public List<Case> selectCasesByCaseId(String caseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCasesByCaseId', caseId);
        }

        List<Case> res = [
            SELECT
                Id,
                CaseNumber,
                Subject,
                Description,
                CreatedDate,
                Status,
                Installed_Product_Serial_Number__c,
                WeChatFollower__r.Charket__OpenId__c,
                WeChatFollower__r.FirstName__c, 
                WeChatFollower__r.LastName__c
            FROM Case
            WHERE Id = :caseId
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    } 

    /**
    * @author Charket
    * @description query wechat comment records
    * @param caseId Id
    * @param recordTypeId String
    * @return List<Comment__c>
    */
    public List<Comment__c> selectWeChatCommentByCaseId(Id caseId, String recordTypeId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatCommentByCaseId', caseId);
        
        List<Comment__c> res = [
            SELECT
                Id,
                Name,
                Type__c,
                Createddate,
                Customer_Read_Date_Time__c,
                Comment__c,
                CreatedById,
                CreatedBy.Name,
                CreatedBy.UserType
            FROM Comment__c
            WHERE Case__c = :caseId AND Internal_Non_Customer__c = FALSE AND RecordTypeId = :recordTypeId
            ORDER BY Createddate DESC
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
    
        return res;
    }

    /**
    * @author Charket
    * @description query wechat comment records
    * @param caseIds List<Id>
    * @param commentType String
    * @param recordTypeId String
    * @return List<Comment__c>
    */
    public List<Comment__c> selectUnreadWeChatCommentByCaseId(List<Id> caseIds, String commentType, String recordTypeId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUnreadWeChatCommentByCaseId', String.valueOf(caseIds) + '|' + commentType + '|' + recordTypeId);
        
        List<Comment__c> res = [
            SELECT Id, Customer_Read_Date_Time__c 
            FROM Comment__c 
            WHERE Customer_Read_Date_Time__c = null 
            AND Internal_Non_Customer__c = false 
            AND Case__c in :caseIds
            AND Type__c = :commentType
            AND RecordTypeId = :recordTypeId
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
    
        return res;
    }

    /**
    * @author Charket
    * @description get comment by id
    * @param String commentId
    * @return List<Comment__c>
    */
    public List<Comment__c> selectCommentById(String commentId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCommentById', commentId);

        List<Comment__c> res = [
            SELECT Comment__c, CreatedBy.UserType, CreatedBy.Name
            FROM Comment__c
            WHERE Id = :commentId
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
    
        return res;
    }

    /**
     *  @author Charket
     *  @description query EmailTemplate records filtered by Name
     *  @param developerName String
     *  @return List<EmailTemplate>
     */
    public List<EmailTemplate> selectEmailTemplateByName(String developerName) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEmailTemplateByName', developerName);

        List<EmailTemplate> res = [
            SELECT Id, Name, Body, HTMLValue, Subject
            FROM EmailTemplate
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description query OrgWideEmailAddress records
     *  @param emailAddress String
     *  @return List<OrgWideEmailAddress>
     */
    public List<OrgWideEmailAddress> selectOrgWideEmailAddress(String emailAddress) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOrgWideEmailAddress', emailAddress);

        List<OrgWideEmailAddress> res = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Address = :emailAddress
            LIMIT 1
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description query Group by name
     *  @param name String
     *  @return List<Group>
     */
    public List<Group> selectGroupByName(String name) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectGroupByName', name);

        List<Group> res = [
            SELECT Id 
            FROM Group 
            WHERE Name = :name
        ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description get wechat follower by openId
     *  @param String openId
     *  @return Charket__WeChatFollower__c
     */
    public Charket__WeChatFollower__c selectWeChatFollowerByOpenId(String openId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatFollowerByOpenId', openId);

            List<Charket__WeChatFollower__c> res = [
                SELECT
                    Id,
                    Charket__WeChatAccount__c,
                    Charket__WeChatAccount__r.Charket__SalesforceEndpoint__c,
                    DataPrivacyPolicyConsentDate__c,
                    EmailVerificationCode__c,
                    FirstName__c,
                    Lastname__c,
                    PreferredContactMethod__c,
                    Email__c,
                    IsEmailVerified__c,
                    IsContactVerified__c,
                    Charket__OpenId__c,
                    Mobile__c,
                    CompanyName__c,
                    EmailNotifiedTime__c,
                    ProductSerialNumber__c,
                    Charket__Contact__c,
                    Charket__Contact__r.AccountId,
                    Charket__IndexedUnionId__c
                FROM Charket__WeChatFollower__c
                WHERE Charket__OpenId__c = :openId
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        if(res.size() > 0)
            return res[0];
        
        return null;
    } 

    /**
     *  @author Charket
     *  @description get wechat follower by Id
     *  @param String followerId
     *  @return Charket__WeChatFollower__c
     */
    public Charket__WeChatFollower__c selectWeChatFollowerById(String followerId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatFollowerById', followerId);

            List<Charket__WeChatFollower__c> res = [
                SELECT
                    Id,
                    Charket__WeChatAccount__c,
                    DataPrivacyPolicyConsentDate__c,
                    EmailVerificationCode__c,
                    FirstName__c,
                    Lastname__c,
                    PreferredContactMethod__c,
                    Email__c,
                    IsEmailVerified__c,
                    IsContactVerified__c,
                    Charket__OpenId__c,
                    Mobile__c,
                    CompanyName__c,
                    EmailNotifiedTime__c,
                    ProductSerialNumber__c,
                    Charket__Contact__c,
                    Charket__Contact__r.AccountId
                FROM Charket__WeChatFollower__c
                WHERE Id = :followerId
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        if(res.size() > 0)
            return res[0];

        return null;
    } 

    /**
     *  @author Charket
     *  @description get open transcript by follower Id
     *  @param String followerId
     *  @return Charket__WeChatTranscript__c
     */
    public Charket__WeChatTranscript__c selectOpenTranscriptByFollowerId(String followerId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenTranscriptByFollowerId', followerId);

            List<Charket__WeChatTranscript__c> res = [
                SELECT
                    Id,
                    Charket__WeChatAgent__c
                FROM Charket__WeChatTranscript__c
                WHERE Charket__WeChatFollower__c = :followerId
                AND Charket__IsClosed__c = false
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        if(res.size() > 0)
            return res[0];

        return null;
    }

    /**
     *  @author Charket
     *  @description select verified follower by unionId
     *  @param String unionId
     *  @return Charket__WeChatFollower__c
     */
    public Charket__WeChatFollower__c selectVerifiedFollowerByUnionId(String unionId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectVerifiedFollowerByUnionId', unionId);

            List<Charket__WeChatFollower__c> res = [
                SELECT
                    Id,
                    Charket__Contact__c,
                    Charket__Contact__r.AccountId
                FROM Charket__WeChatFollower__c
                WHERE Charket__IndexedUnionId__c = :unionId
                AND IsEmailVerified__c = true
                LIMIT 1
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        if(res.size() > 0)
            return res[0];

        return null;
    } 

    /**
     *  @author Charket
     *  @description select open transcripts by agent Id
     *  @param String agentId
     *  @return List<Charket__WeChatTranscript__c>
     */
    public List<Charket__WeChatTranscript__c> selectOpenTranscriptsByAgentId(String agentId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOpenTranscriptsByAgentId', agentId);

            List<Charket__WeChatTranscript__c> res = [
                SELECT
                    Id, Charket__WeChatAgent__c, Charket__WeChatAgent__r.Name,
                    Charket__WeChatAgent__r.BackupAgent__c
                FROM Charket__WeChatTranscript__c
                WHERE Charket__WeChatAgent__c = :agentId
                AND Charket__IsClosed__c = false
                ORDER BY LastModifiedDate DESC 
                LIMIT 50
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description select account specialist by account Id
     *  @param String accountId
     *  @return Account_to_Field_Support__c
     */
    public List<Account_to_Field_Support__c> selectAccountSpecialistById(String accountId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountSpecialistById', accountId);

            List<Account_to_Field_Support__c> res = [
                SELECT Salesforce_User_ID__c 
                FROM Account_to_Field_Support__c 
                WHERE User_Role__c = :CUSTOMER_CARE_USER_ROLE
                AND Account__c = :accountId 
                LIMIT 1
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Charket
     *  @description select wechat agent by user Id
     *  @param String userId, String wechatAccountId
     *  @return Charket__WeChatAgent__c
     */
    public Charket__WeChatAgent__c selectActiveCustomerCareAgentByUserId(String userId, String wechatAccountId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveCustomerCareAgentByUserId', userId + ' ' + wechatAccountId);

            List<Charket__WeChatAgent__c> res = [
                SELECT Id, Name, Charket__Status__c, BackupAgent__c, 
                Charket__IsAcceptsChats__c, Charket__LastDesktopActiveTime__c
                FROM Charket__WeChatAgent__c
                WHERE Charket__WeChatAccount__c = :wechatAccountId
                AND Charket__IsActive__c = TRUE
                AND Charket__User__c =:userId 
                AND UsedFor__c = :USED_FOR_CUSTOMER_CARE
                LIMIT 1
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        if(res.size() > 0)
            return res[0];

        return null;
    }

    /**
     *  @author Charket
     *  @description select random online wechat agent
     *  @param String wechatAccountId
     *  @return Charket__WeChatAgent__c
     */
    public Charket__WeChatAgent__c selectRandomCustomerCareOnlineAgent(String wechatAccountId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRandomCustomerCareOnlineAgent', wechatAccountId);

            List<Charket__WeChatAgent__c> res = [
                SELECT Id
                FROM Charket__WeChatAgent__c
                WHERE Charket__WeChatAccount__c = :wechatAccountId
                AND Charket__IsActive__c = true
                AND Charket__IsAcceptsChats__c = true
                AND UsedFor__c = :USED_FOR_CUSTOMER_CARE
                ORDER BY Charket__CurrentStatusPriority__c, Charket__ChatCount__c, Charket__LastChatCompletedTime__c 
                LIMIT 1
            ];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        
        if(res.size() > 0)
            return res[0];

        return null;
    }

    /**
     *  @author Charket
     *  @description select agent status
     *  @param String statusName
     *  @return Charket__WeChatAgentStatus__c
     */
    public Charket__WeChatAgentStatus__c selectAgentStatusByName(String statusName) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgentStatusByName', statusName);

            List<Charket__WeChatAgentStatus__c> res = [
                SELECT Id FROM Charket__WeChatAgentStatus__c
                WHERE Name = :statusName
                AND Charket__IsActive__c = true
                LIMIT 1];

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        
        if(res.size() > 0)
            return res[0];

        return null;
    }
}