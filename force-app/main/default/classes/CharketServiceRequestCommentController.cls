/**
 * Controller of vf page :CharketServiceRequestComment
 * The page is used for manageing the case comments case via Wechat
 *  Modification Log:
 *  -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Charket                       28-Sep-2023          Added Instrumentation 
 *      Charket                       12-Oct-2023          Added query selector 
 * 
 *  -------------------------------------------------------------------------------------------------------------------
 */
global without sharing class CharketServiceRequestCommentController {
    private String code;
    private String caseId;
    private String wechatAccountId;
    private Charket__WeChatAccount__c wechatAccount;
    private CharketSettings__mdt thisCharketSettings;
    private static final String GUEST_TYPE = 'Guest';
    private static final String WAITING_CASE_STATUS = 'Awaiting Response - Internal';
    private static final String DESCRIPTION_COMMENT_TYPE = 'Original Description';
    private static final String LOG_TITLE = 'CharketServiceRequestCommentController';
    private static final String WECHAT_RECORD_TYPE_NAME = 'Case - WeChat';
    
    public String openId { get; set; }
    public String qrCodeImage { get; set; }
    public Boolean hasPermission { get; set; }
    public Boolean isWeChatBrowser { get; set; }
    public CaseInfo thisCase { get; set; }
    public List<CaseCommentItem> thisCaseComments { get; set; }
    public Id caseCommentId { get; set; } //the case comment id for uploading files
    public Id replyCaseCommentId { get; set; } //the case comment id for replying comment
    public Boolean hasUploadFiles { get; set; }
    public Boolean uploadFilesSuccessed { get; set; }
    public String pageRefreshTime { get; set; }
    public String followerName { get; set; }
    public ContentVersion contentVersion {
        get {
            if (contentVersion == null)
                contentVersion = new ContentVersion();
            return contentVersion;
        }
        set;
    }

    /**
     *  @author  Charket Team
     *  @description CharketServiceRequestCommentController constructor
     **/
    public CharketServiceRequestCommentController() {
        hasPermission = false;
        isWeChatBrowser = false;
        hasUploadFiles = false;
        uploadFilesSuccessed = false;
        pageRefreshTime = Datetime.now().format('HH:mm');
        Map<String, String> params = ApexPages.currentPage().getParameters();
        caseId = params.get('cid');
        code = params.get('code');
        initCaseAndCaseComments(caseId);
        wechatAccountId = params.get('wid');
        if (String.isNotBlank(wechatAccountId) && wechatAccountId instanceof Id) {
            wechatAccount = new CharketSelector().selectWeChatAccountsById(wechatAccountId)[0];
            thisCharketSettings = CharketCustomUtil.getCharketSetting(
                wechatAccount.Id
            );
            if (thisCharketSettings != null) {
                qrCodeImage = thisCharketSettings.QRCodeImageName__c;
            }
        }
    }

    /**
     *  @author  Charket Team
     *  @description Retrieve parameters and records needed
     **/
    public PageReference init() {
        ilib_LogEvent.push(LOG_TITLE + 'init');
        String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
        isWeChatBrowser = String.isNotBlank(userAgent) && userAgent.containsIgnoreCase('MicroMessenger');
        ilib_LogEvent.info('isWeChatBrowser: ' + isWeChatBrowser);
        if (!isWeChatBrowser || wechatAccount == null || thisCase == null) {
            ilib_LogEvent.pop();
            return null;
        }

        String callbackUrl = initOpenId();

        if(String.isNotBlank(callbackUrl)){
            ilib_LogEvent.pop();
            return new PageReference(callbackUrl);
        }
        ilib_LogEvent.info('Open Id: ' + openId);
        if (String.isNotBlank(openId) && thisCase.CaseFollowerOpenId == openId) {
            initWeChatFollower();
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket Team
     *  @description Authenticates WeChat Follower with the WeChat Account
     **/
    public String initOpenId() {
        ilib_LogEvent.push(LOG_TITLE + 'initOpenId');
        String cookieName = 'OPENID' + wechatAccountId.right(15);
        Cookie openIdCookie = ApexPages.currentPage().getCookies().get(cookieName);

        if (openIdCookie != null && String.isNotBlank(openIdCookie.getValue())) {
            openId = CharketCustomUtil.decryptOpenId(openIdCookie.getValue(), wechatAccount, thisCharketSettings);
        } 
        if (String.isBlank(openId) && String.isNotBlank(code)){
            openId = getOpenId();
            ApexPages.currentPage().getParameters().put('code', '');
        }
        ilib_LogEvent.info('Open Id: ' + openId);
        if (String.isBlank(openId)) {
            String callbackUrl = CharketCustomUtil.getCommentCallbackUrl(wechatAccount, caseId);
            ilib_LogEvent.info('Callback URL: ' + callbackUrl);
            ilib_LogEvent.pop();
            return callbackUrl;
        } else {
            openIdCookie = new Cookie(cookieName, CharketCustomUtil.encryptOpenId(OpenId, wechatAccount, thisCharketSettings), null, 14400, true);
            ApexPages.currentPage().setCookies(new List<Cookie>{ openIdCookie });
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket Team
     *  @description Get the Follower's information by openId
     **/
    public void initWeChatFollower(){
        ilib_LogEvent.push(LOG_TITLE + 'initWeChatFollower');
        Charket__WeChatFollower__c currentFollower = CharketCustomUtil.getFollower(openId);
        if (currentFollower != null) {
            hasPermission = true;
            followerName = CharketCustomUtil.getFollowerFullName(currentFollower);
        }
        ilib_LogEvent.info('WeChat Follower:' + currentFollower);
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket Team
     *  @description Get the WeChat Follower's WeChat Open ID
     **/
    public String getOpenId() {
        ilib_LogEvent.push(LOG_TITLE + 'getOpenId');
        try {
            if (String.isNotBlank(code) && String.isNotBlank(wechatAccount.Id)) {
                Charket.WeChatClient client = new Charket.WeChatClient(wechatAccount.Id);
                Charket.WeChatApiOAuth oauth = client.getOAuth();
                Charket.WeChatApiOAuth.AuthTokenResponse response = oauth.handleCallback(
                    code,
                    ''
                );
                ilib_LogEvent.info('Open Id' + response.OpenId);
                ilib_LogEvent.pop();
                return response.OpenId;
            }
        } catch (Exception ex) {
            CharketCustomUtil.addCharketLog('CharketServiceRequestCommentController.getOpenId', ex.getMessage(), 'openId' + openId);
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket Team
     *  @description Upload the images to the case comment & case
     **/
    public PageReference uploadImages() {
        ilib_LogEvent.push(LOG_TITLE + 'uploadImages');
        hasUploadFiles = true;
        try {
            ilib_LogEvent.info('ContentVersion: ' + contentVersion);
            if (contentVersion.Title != null) {
                //contentVersion.ContentLocation = 'S';
                //contentVersion.FirstPublishLocationId = CaseCommentId;
                contentVersion.PathOnClient = contentVersion.Title;
                contentVersion.IsMajorVersion = true;
                insert contentVersion;
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = new CharketSelector().selectContentVersionById(contentVersion.Id)[0].ContentDocumentId;
                contentDocumentLink.LinkedEntityId = caseCommentId;
                contentDocumentLink.ShareType = 'V';
                insert contentDocumentLink;
                //generates a public link
                ContentDistribution newContentDistribution = new ContentDistribution();
                newContentDistribution.Name = contentVersion.Title;
                newContentDistribution.ContentVersionId = contentVersion.Id;
                newContentDistribution.PreferencesAllowViewInBrowser = true;
                newContentDistribution.PreferencesLinkLatestVersion = true;
                newContentDistribution.PreferencesNotifyOnVisit = false;
                newContentDistribution.PreferencesPasswordRequired = false;
                newContentDistribution.PreferencesAllowOriginalDownload = true;
                insert newContentDistribution;
            }
            contentVersion.versionData = null;
            uploadFilesSuccessed = true;
            initCaseAndCaseComments(thisCase.CaseId);
        } catch (Exception ex) {
            CharketCustomUtil.addCharketLog('CharketServiceRequestCommentController.uploadImages', ex.getMessage(), 'Case Comment Id' + caseCommentId);
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
        }
        ilib_LogEvent.pop();
        return null;
    }

    //gets teh files of the case comments
    private Map<Id, List<ContentDistribution>> getCaseCommentFiles(Set<Id> caseCommentIds) {
        ilib_LogEvent.push(LOG_TITLE + 'getCaseCommentFiles');
        Map<Id, List<ContentDistribution>> contentVerMap = new Map<Id, List<ContentDistribution>>();
        
        List<ContentDocumentLink> cdlist = new CharketSelector().selectContentDocumentLinks(caseCommentIds);
        ilib_LogEvent.message('Content Document Links:' + cdlist);

        Map<Id, Id> linkedDocsMap = new Map<Id, Id>();
        for (ContentDocumentLink cl : cdlist) {
            linkedDocsMap.put(cl.ContentDocumentID, cl.LinkedEntityId);
        }
        List<ContentVersion> cvlist = new CharketSelector().selectContentVersionByCDIds(linkedDocsMap.keySet());
        ilib_LogEvent.message('Content Versions:' + cvlist);

        List<ContentDistribution> contentDistributionList = new CharketSelector().selectContentDistributionByCVs(cvlist);
        ilib_LogEvent.message('Content Distributions:' + contentDistributionList);
        
        Map<Id, ContentDistribution> cvs = new Map<Id, ContentDistribution>();
        for (ContentDistribution contentDistribution : contentDistributionList) {
            cvs.put(contentDistribution.ContentVersionId, contentDistribution);
        }
        for (ContentVersion file : cvlist) {
            ContentDistribution thisCVDis = cvs.get(file.Id);
            if (thisCVDis != null) {
                Id linkId = linkedDocsMap.get(file.ContentDocumentId);
                if (!contentVerMap.containsKey(linkId))
                    contentVerMap.put(linkId, new List<ContentDistribution>());
                contentVerMap.get(linkId).add(thisCVDis);
            }
        }
        ilib_LogEvent.pop();
        return contentVerMap;
    }

    /**
     *  @author  Charket Team
     *  @description  refresh the comment list
     **/
    public void refreshComments() {
        initCaseAndCaseComments(thisCase.CaseId);
    }

    /**
     *  @author  Charket Team
     *  @description  init the case and case comments
     **/
    private void initCaseAndCaseComments(String thisCaseId) {
        ilib_LogEvent.push(LOG_TITLE + 'initCaseAndCaseComments');
        pageRefreshTime = Datetime.now().format('HH:mm');
        replyCaseCommentId = null;
        contentVersion = new ContentVersion();
        thisCaseComments = new List<CaseCommentItem>();
        List<Case> thisCases = new CharketSelector().selectCasesByCaseId(thisCaseId);
        ilib_LogEvent.message('Cases: ' + thisCases);
        if(thisCases.size() == 0) {
            hasPermission = false;
            ilib_LogEvent.pop();
            return;
        }
        
        String caseDescription = '';
        String recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get(WECHAT_RECORD_TYPE_NAME).getRecordTypeId();
        Map<Id, Comment__c> caseComments = new Map<Id, Comment__c>(new CharketSelector().selectWeChatCommentByCaseId(thisCaseId, recordTypeId));
        ilib_LogEvent.message('Case Comments: ' + caseComments);
        
        if (caseComments.keyset().size() > 0) {
            Map<Id, List<ContentDistribution>> caseCommentFiles = getCaseCommentFiles(
                caseComments.keyset()
            );
            for (Comment__c thisCaseComment : caseComments.values()) {
                String commentType = thisCaseComment.Type__c;
                
                if (commentType != DESCRIPTION_COMMENT_TYPE) {
                    CaseCommentItem thisCaseItem = new CaseCommentItem(thisCaseComment);
                    
                    List<ContentDistribution> thisCommentCVs = caseCommentFiles.get(thisCaseComment.Id);
                    thisCommentCVs = thisCommentCVs != null ? thisCommentCVs : new List<ContentDistribution>();
                    
                    for (ContentDistribution thisCommentCV : thisCommentCVs) {
                        CaseCommentFileItem commentFielItem = new CaseCommentFileItem(
                            thisCommentCV.Name,
                            thisCommentCV.DistributionPublicUrl
                        );
                        thisCaseItem.CaseCommentFiels.add(commentFielItem);
                    }
                    
                    thisCaseComments.add(thisCaseItem);
                } else {
                    caseDescription = thisCaseComment.Comment__c;
                }
            }
        }
        ilib_LogEvent.info('Case Description: ' + caseDescription);
        if (String.isBlank(caseDescription)) {
            caseDescription = thisCases[0].Description;
            if (
                String.isNotBlank(caseDescription) &&
                caseDescription.indexOf('---------- Contact Information ----------') != -1
            ) {
                caseDescription = caseDescription.substring(
                    0,
                    caseDescription.indexOf('---------- Contact Information ----------')
                );
            }
        }
        thisCase = new CaseInfo(thisCases[0], caseDescription);
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket Team
     *  @description  save a comment record to the case
     **/
    @RemoteAction
    public static String saveTheComment(
        String inputContent,
        String caseId,
        String currentFollowerName,
        String replyCaseCommentId
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'saveTheComment');
        SaveResult result = new SaveResult();
        try {
            String comment = inputContent;
            ilib_LogEvent.info('reply Case Comment Id: ' + replyCaseCommentId);

            if (String.isNotBlank(replyCaseCommentId) && replyCaseCommentId instanceof Id) {

                List<Comment__c> replyComments = new CharketSelector().selectCommentById(replyCaseCommentId);
                ilib_LogEvent.message('reply Case Comments: ' + replyComments);

                if (replyComments.size() > 0 && String.isNotBlank(replyComments[0].Comment__c)) {
                    String commentAuthor = replyComments[0].CreatedBy.Name;
                    String commentCreatedUserType = replyComments[0].CreatedBy.UserType;
                    if (commentCreatedUserType == GUEST_TYPE) {
                        commentAuthor = currentFollowerName;
                    }
                    comment =
                        inputContent +
                        '<br/>- - - - - - - - - - - - - - -<br/>' +
                        commentAuthor +
                        ':' +
                        replyComments[0].Comment__c;
                }
            }
            Comment__c newComment = new Comment__c(
                Name = 'Sent by ' + currentFollowerName,
                Case__c = caseId,
                Comment__c = comment,
                Type__c = 'WeChat Comment',
                RecordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName()
                    .get('Case - WeChat')
                    .getRecordTypeId()
            );
            insert newComment;
            result.status = 1;
            result.message = newComment.Id;
        } catch (Exception ex) {
            result.status = 0;
            result.message = ex.getMessage();
            CharketCustomUtil.addCharketLog('CharketServiceRequestCommentController.saveTheComment', ex.getMessage(), 'comment:' + inputContent);
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket Team
     *  @description  update the case comment Customer_Read_Date_Time to currentTime
     **/
    @RemoteAction
    public static String updateCommentCustomerReadDateTime(String caseId) {
        SaveResult result = new SaveResult();
        try {
            if (String.isNotBlank(caseId)) {
                ilib_LogEvent.push(LOG_TITLE + 'updateCommentCustomerReadDateTime');
                List<Admin_Operation__e> lstAdminOperation = new List<Admin_Operation__e>();
                if (caseId != null) {
                    lstAdminOperation.add(
                        new Admin_Operation__e(
                            Name__c = 'CharketServiceUpdateLogic',
                            Related_Record__c = caseId
                        )
                    );
                }
                if (!lstAdminOperation.isEmpty()) {
                    EventBus.publish(lstAdminOperation);
                }
                ilib_LogEvent.pop();
            }
            result.status = 1;
            result.message = 'success';
        } catch (Exception ex) {
            result.status = 0;
            result.message = ex.getMessage();
            CharketCustomUtil.addCharketLog('CharketServiceRequestCommentController.updateCommentCustomerReadDateTime', ex.getMessage(), 'caseId:' + caseId);
            System.debug('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket Team
     *  @description SaveResult
     **/
    global class SaveResult {
        public Integer status;
        public String message;
    }

    /**
     *  @author  Charket Team
     *  @description Inner class to display related open Cases.
     **/
    global class CaseInfo {
        /*
         * Constructor
         */
        public CaseInfo(Case thisCase, String caseDescription) {
            this.caseNumber = thisCase.CaseNumber;
            this.caseId = thisCase.Id;
            this.subject = thisCase.Subject;
            this.description = caseDescription;
            this.createdDate = thisCase.CreatedDate.format('yyyy-MM-dd HH:mm');
            this.productSerialNumber = thisCase.Installed_Product_Serial_Number__c;
            String caseStatus = thisCase.Status;
            this.status = (caseStatus == WAITING_CASE_STATUS) ? 'In Progress' : caseStatus;
            this.caseFollowerOpenId = thisCase.WeChatFollower__r.Charket__OpenId__c;
        }

        public String caseId { get; set; }
        public String caseNumber { get; set; }
        public String subject { get; set; }
        public String status { get; set; }
        public String createdDate { get; set; }
        public String caseType { get; set; }
        public String description { get; set; }
        public String productSerialNumber { get; set; }
        public String caseFollowerOpenId { get; set; }
    }

    /**
     *  @author  Charket Team
     *  @description Inner class to display related case comments of a case.
     **/
    global class CaseCommentItem {
        /*
         * Constructor
         */
        public CaseCommentItem(Comment__c thisCaseComment) {
            this.caseCommentId = thisCaseComment.Id;
            this.comment = thisCaseComment.Comment__c;
            this.createdDate = thisCaseComment.CreatedDate.format('yyyy-MM-dd HH:mm');
            this.readTime = thisCaseComment.Customer_Read_Date_Time__c;
            this.author = thisCaseComment.CreatedBy.Name;
            this.isAuthorGuest = false;
            String commentCreatedUserType = thisCaseComment.CreatedBy.UserType;
            if (commentCreatedUserType == GUEST_TYPE) {
                this.isAuthorGuest = true;
                this.author = '我';
            }
            this.caseCommentFiels = new List<CaseCommentFileItem>();
        }

        public String caseCommentId { get; set; }
        public String comment { get; set; }
        public String author { get; set; }
        public String createdDate { get; set; }
        public Datetime readTime { get; set; }
        public Boolean isAuthorGuest { get; set; }
        public List<CaseCommentFileItem> caseCommentFiels { get; set; }
    }

    /**
     *  @author  Charket Team
     *  @description Inner class to display related case attachments of a case comment.
     **/
    global class CaseCommentFileItem {
        /*
         * Constructor
         */
        public CaseCommentFileItem(String filename, String viewLink) {
            this.fileName = filename;
            this.viewLink = viewLink;
        }

        public String fileName { get; set; }
        public String viewLink { get; set; }
    }
}