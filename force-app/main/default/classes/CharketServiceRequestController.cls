/**
 * Controller of vf page :CharketServiceRequest
 * The page is used for submitting an inquiry case via Wechat
 *  Modification Log:
 *  -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Charket                       12-Sep-2023          Added the complaint and feedback feature
 *      Charket                       28-Sep-2023          Added Instrumentation 
 *      Charket                       12-Oct-2023          Added query selector
 *  -------------------------------------------------------------------------------------------------------------------
 */
global without sharing class CharketServiceRequestController {
    private static final String LOG_TITLE = 'CharketServiceRequestController';
    private static String code;
    private static Charket__WeChatAccount__c wechatAccount;
    private CharketSettings__mdt thisCharketSettings;
    public String OpenId { get; set; }
    public String QRCodeImage { get; set; }
    public Boolean IsEmailVerified { get; set; }
    public Boolean IsWeChatBrowser { get; set; }
    public FollowerInfo CurrentFollower { get; set; }
    public Boolean IsFollowerRelatedCase { get; set; }
    public Boolean IsUpdatePersonalInfo { get; set; }
    public Boolean IsComplaintAndFeedback { get; set; }
    public List<HistoryCaseItem> HistoryCases { get; set; }
    public CharketSetting CurrentCharketSetting { get; set; }
    public String contactMethod { get; set; }
    public Boolean isAcceptDataPrivacyPolicy { get; set; }
    public Boolean hasUploadFiles { get; set; }
    public Boolean uploadFilesSuccessed { get; set; }
    public String caseSubject { get; set; }
    public String caseNumber { get; set; }
    public ContentVersion contentVersion1 {
        get {
            if (contentVersion1 == null)
                contentVersion1 = new ContentVersion();
            return contentVersion1;
        }
        set;
    }

    public ContentVersion contentVersion2 {
        get {
            if (contentVersion2 == null)
                contentVersion2 = new ContentVersion();
            return contentVersion2;
        }
        set;
    }

    public ContentVersion contentVersion3 {
        get {
            if (contentVersion3 == null)
                contentVersion3 = new ContentVersion();
            return contentVersion3;
        }
        set;
    }

    /**
     *  @author  Charket Team
     *  @description CharketServiceRequestController constructor
     **/
    public CharketServiceRequestController() {
        IsEmailVerified = false;
        IsWeChatBrowser = false;
        IsFollowerRelatedCase = false;
        isAcceptDataPrivacyPolicy = false;
        hasUploadFiles = false;
        uploadFilesSuccessed = false;
        HistoryCases = new List<HistoryCaseItem>();
        CurrentCharketSetting = null;
        CurrentFollower = new FollowerInfo(new Charket__WeChatFollower__c());
        Map<String, String> params = ApexPages.currentPage().getParameters();

        String wechatAccountId = params.get('wechatAccountId');
        if (String.isNotBlank(wechatAccountId) && wechatAccountId instanceof Id) {
            wechatAccount = new CharketSelector().selectWeChatAccountsById(wechatAccountId)[0];
            thisCharketSettings = CharketCustomUtil.getCharketSetting(
                wechatAccount.Id
            );
            CurrentCharketSetting = new CharketSetting(thisCharketSettings);
        }
    }

    /**
     *  @author  Charket Team
     *  @description Retrieve parameters and records needed
     **/
    public PageReference init() {
        ilib_LogEvent.push(LOG_TITLE + 'init');
        String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
        IsWeChatBrowser =
            String.isNotBlank(userAgent) && userAgent.containsIgnoreCase('MicroMessenger');
        ilib_LogEvent.info('isWeChatBrowser: ' + isWeChatBrowser);
        ilib_LogEvent.info('wechatAccount: ' + wechatAccount);
        if (!isWeChatBrowser || wechatAccount == null ) {
            ilib_LogEvent.pop();
            return null;
        }
        code = ApexPages.currentPage().getParameters().get('code');
        String thisSerialNumber = ApexPages.currentPage().getParameters().get('number') != null
            ? ApexPages.currentPage().getParameters().get('number')
            : '';
        String thisServiceType = ApexPages.currentPage().getParameters().get('type') != null
            ? ApexPages.currentPage().getParameters().get('type')
            : '';
        
        IsUpdatePersonalInfo = thisServiceType == 'update_personal_info';
        IsComplaintAndFeedback = thisServiceType == 'complaint_and_feedback';

        String cookieName = 'OPENID' + ((String)wechatAccount.Id).right(15);
        Cookie openIdCookie = ApexPages.currentPage().getCookies().get(cookieName);

        // Get open Id from cookie
        if (openIdCookie != null && String.isNotBlank(openIdCookie.getValue())) {
            OpenId = CharketCustomUtil.decryptOpenId(openIdCookie.getValue(), wechatAccount, thisCharketSettings);
        } 

        // Get open Id from WeChat
        if (String.IsBlank(OpenId) && String.isNotBlank(code)) {
            OpenId = getOpenId();
            ApexPages.currentPage().getParameters().put('code', '');
        }

        // Redirect to WeChat Oauth Page
        if (String.isBlank(OpenId)) {
            String callbackUrl = '{0}/CharketServiceRequest?wechatAccountId={1}&number={2}&type={3}';
            callbackUrl = String.format(
                callbackUrl,
                new List<Object>{
                    wechatAccount.Charket__SalesforceEndpoint__c,
                    wechatAccount.Id,
                    thisSerialNumber,
                    thisServiceType
                }
            );
            Charket.WeChatApiOAuth oauth = (new Charket.WeChatClient(wechatAccount.Id)).getOAuth();
            String result = oauth.initiate(callbackUrl, Charket.WeChatApiOAuth.Scope.base, '')
                .getUrl();
            ilib_LogEvent.info('oauth url: ' + result);
            ilib_LogEvent.pop();
            return new PageReference(result);
        }

        if (String.isNotBlank(OpenId)) {
            ilib_LogEvent.info('Open Id : ' + OpenId);
            openIdCookie = new Cookie(cookieName, CharketCustomUtil.encryptOpenId(OpenId, wechatAccount, thisCharketSettings), null, 14400, true);
            ApexPages.currentPage().setCookies(new List<Cookie>{ openIdCookie });
            
            initWeChatFollower();
        }
        ilib_LogEvent.pop();
        return null;
    }

    /*
    * @author : Pooja 
    * 
    */
    public void initWeChatFollower() {
        ilib_LogEvent.push(LOG_TITLE + 'initWeChatFollower');
        Charket__WeChatFollower__c follower = CharketCustomUtil.getFollower(OpenId);
        if (follower == null) {
            follower = new Charket__WeChatFollower__c(
                Charket__WeChatAccount__c = wechatAccount.Id,
                Charket__OpenId__c = OpenId,
                Charket__IsFollowing__c = false,
                Name = 'WeChat User'
            );
            upsert follower Charket__WeChatFollower__c.fields.Charket__OpenId__c;
        }
        
        if (follower.DataPrivacyPolicyConsentDate__c != null) {
            isAcceptDataPrivacyPolicy = true;
        }

        CurrentFollower = new FollowerInfo(follower);
        IsEmailVerified = follower.IsEmailVerified__c;
        if (IsEmailVerified) {
            // If WeChat Follower email is verified and is related to cases, open Cases are retrieved and displayed to the WeChat follower.
            List<Case> openCases = new CharketSelector().selectOpenCasesWithWeChatComments(follower.Id);
            for (Case historyCase : openCases) {
                String caseComment = '';
                if (historyCase.WeChat_Comments__r.size() > 0) {
                    caseComment = historyCase.WeChat_Comments__r[0].Comment__c;
                } else {
                    caseComment = ((historyCase.Description != null &&
                        historyCase.Description.length() > 10)
                        ? (historyCase.Description.substring(0, 10) + '...')
                        : historyCase.Description);
                }
                HistoryCases.add(
                    new HistoryCaseItem(
                        historyCase.Id,
                        historyCase.caseNumber,
                        ((historyCase.subject != null &&
                            historyCase.subject.length() > 10)
                            ? (historyCase.subject.substring(0, 10) + '...')
                            : historyCase.subject),
                        caseComment,
                        historyCase.CreatedDate.format('yyyy-MM-dd'),
                        historyCase.Status,
                        historyCase.Installed_Product_Serial_Number__c
                    )
                );
                ilib_LogEvent.message('History Cases' + HistoryCases);
            }
            if (HistoryCases.size() > 0) {
                IsFollowerRelatedCase = true;
            }
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket Team
     *  @description Get the WeChat Follower's WeChat Open ID
     **/
    public static String getOpenId() {
        ilib_LogEvent.push(LOG_TITLE + 'getOpenId');
        try {
            String wechatCode = ApexPages.currentPage().getParameters().get('code');
            if (String.isNotBlank(wechatCode) && String.isNotBlank(wechatAccount.Id)) {
                Charket.WeChatClient client = new Charket.WeChatClient(wechatAccount.Id);
                Charket.WeChatApiOAuth oauth = client.getOAuth();
                Charket.WeChatApiOAuth.AuthTokenResponse response = oauth.handleCallback(
                    wechatCode,
                    ''
                );
                ilib_LogEvent.info('Open Id' + response.OpenId);
                ilib_LogEvent.pop();
                return response.OpenId;
            }
        } catch (Exception ex) {
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketServiceRequestController.getOpenId',
                Charket__Message__c = ex.getMessage(),
                Charket__Data__c = 'openId'
            ));
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket Team
     *  @description Send a verification code to the email address inputted
     **/
    @RemoteAction
    public static String sendVerificationCode(
        String toEmail,
        String replyToEmailAddress,
        String senderDisplayName,
        String followerId
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'sendVerificationCode');
        SaveResult result = new SaveResult();
        try {
            Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(Id = followerId);
            String emailVerificationCode = CharketCustomUtil.generateVerificationCode(6);
            Boolean sendResult = CharketCustomUtil.sendEmailVerificationCode(
                emailVerificationCode,
                toEmail,
                replyToEmailAddress,
                senderDisplayName
            );
            if (sendResult) {
                follower.EmailNotifiedTime__c = datetime.now();
                follower.EmailVerificationCode__c = emailVerificationCode;
                update follower;
                result.status = 1;
                result.message = 'success';
            } else {
                //Returns message to WeChat Follower "Failed to send email verification code"
                result.status = 0;
                result.message = '发送邮件验证码失败';
            }
        } catch (Exception ex) {
            result.status = 0;
            result.message = '发送邮件验证码失败';
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketServiceRequestController.sendVerificationCode',
                Charket__Message__c = ex.getMessage(),
                Charket__Data__c = 'followerId' + followerId
            ));
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket Team
     *  @description verifiy if the email verification code is correct
     **/
    @RemoteAction
    public static String verifiyEmailCode(
        String thisEmailVerificationCode,
        String firstname,
        String lastname,
        String email,
        String mobile,
        String companyName,
        String contactMethod,
        String productSerialNumber,
        String subject,
        String Description,
        String openId
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'verifiyEmailCode');
        SaveResult result = new SaveResult();
        try {
            Charket__WeChatFollower__c follower = CharketCustomUtil.getFollower(openId);
            ilib_LogEvent.message('Follower' + follower);
            if (thisEmailVerificationCode == follower.EmailVerificationCode__c) {
                Id accountId = null;
                Id contactId = null;
                Contact matchedContact = getMatchedContact(email, productSerialNumber);
                if (matchedContact != null) {
                    follower.Charket__Contact__c = matchedContact.Id;
                    accountId = matchedContact.AccountId;
                    contactId = matchedContact.Id;
                }
                follower.Name = lastname + ' ' + firstname;
                follower.FirstName__c = firstname;
                follower.Lastname__c = lastname;
                follower.Email__c = email;
                follower.Mobile__c = mobile;
                follower.CompanyName__c = companyName;
                //follower.PreferredContactMethod__c = contactMethod;
                follower.ProductSerialNumber__c = productSerialNumber;
                follower.EmailNotifiedTime__c = null;
                follower.EmailVerificationCode__c = '';
                follower.IsEmailVerified__c = true;
                update follower;
                String contactInfo = getFormatContactInfo(
                    firstname,
                    lastname,
                    email,
                    mobile,
                    companyName,
                    contactMethod,
                    follower.Id,
                    productSerialNumber
                );
                String caseNumber = CharketCustomUtil.saveCase(
                    subject,
                    description,
                    productSerialNumber,
                    contactInfo,
                    contactId,
                    accountId,
                    follower.Id
                );
                result.status = 1;
                result.message = caseNUmber;
            } else {
                result.status = 0;
                result.message = '邮件验证码不匹配';
            }
        } catch (Exception ex) {
            result.status = 0;
            result.message = ex.getMessage();
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketServiceRequestController.verifiyEmailCode',
                Charket__Message__c = ex.getMessage() + ex.getStackTraceString(),
                Charket__Data__c = 'openId' + openId
            ));
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket Team
     *  @description creates new case
     **/
    @RemoteAction
    public static String createNewCase(
        String subject,
        String contactmethod,
        String description,
        String productSerialNumber,
        String openId
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'createNewCase');
        SaveResult result = new SaveResult();
        try {
            Charket__WeChatFollower__c follower = CharketCustomUtil.getFollower(openId);
            update follower;
            ilib_LogEvent.message('Follower' + follower);
            String contactInfo = getFormatContactInfo(
                follower.FirstName__c,
                follower.LastName__c,
                follower.Email__c,
                follower.Mobile__c,
                follower.CompanyName__c,
                contactmethod,
                follower.Id,
                productSerialNumber
            );
            String caseNumber = CharketCustomUtil.saveCase(
                subject,
                description,
                productSerialNumber,
                contactInfo,
                follower.Charket__Contact__c,
                follower.Charket__Contact__r.AccountId,
                follower.Id
            );
            ilib_LogEvent.info('Case Number' + caseNumber);
            result.status = 1;
            result.message = caseNumber;
        } catch (Exception ex) {
            result.status = 0;
            result.message = ex.getMessage();
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketServiceRequestController.createNewCase',
                Charket__Message__c = ex.getMessage(),
                Charket__Data__c = 'openId' + openId
            ));
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket Team
     *  @description Upload the images to the case files
     **/
    public PageReference uploadImages() {
        ilib_LogEvent.push(LOG_TITLE + 'uploadImages');
        hasUploadFiles = true;
        isAcceptDataPrivacyPolicy = true;
        try {
            Case thisNewCase = new CharketSelector().selectCaseByCaseNumber(caseNumber)[0];
            ilib_LogEvent.info('Case' + thisNewCase);
            caseSubject = thisNewCase.Subject;
            String uploadImageNames = '\nFile attached: ';
            Set<String> filenames = new Set<String>();
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            if (contentVersion1.Title != null) {
                contentVersion1.ContentLocation = 'S';
                contentVersion1.FirstPublishLocationId = thisNewCase.Id;
                contentVersion1.PathOnClient = contentVersion1.Title;
                //uploadImageNames += contentVersion1.Title + ',';
                filenames.add(contentVersion1.Title);
                contentVersions.add(contentVersion1);
            }
            if (contentVersion2.Title != null) {
                contentVersion2.ContentLocation = 'S';
                contentVersion2.FirstPublishLocationId = thisNewCase.Id;
                contentVersion2.PathOnClient = contentVersion2.Title;
                //uploadImageNames += contentVersion2.Title + ',';
                filenames.add(contentVersion2.Title);
                contentVersions.add(contentVersion2);
            }
            if (contentVersion3.Title != null) {
                contentVersion3.ContentLocation = 'S';
                contentVersion3.FirstPublishLocationId = thisNewCase.Id;
                contentVersion3.PathOnClient = contentVersion3.Title;
                //uploadImageNames += contentVersion3.Title;
                filenames.add(contentVersion3.Title);
                contentVersions.add(contentVersion3);
            }
            for (String filename : filenames) {
                uploadImageNames += filename + ',';
            }
            uploadImageNames = uploadImageNames.substring(0, uploadImageNames.length() - 1);
            insert contentVersions;
            ilib_LogEvent.message('ContentVersions: ' + contentVersions);
            thisNewCase.Description = thisNewCase.Description + uploadImageNames;
            update thisNewCase;
            ilib_LogEvent.info('Updated case: ' + thisNewCase);
            contentVersion1.versionData = null;
            contentVersion2.versionData = null;
            contentVersion3.versionData = null;
            uploadFilesSuccessed = true;
        } catch (Exception ex) {
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketDataPrivacyConsentController.uploadImages',
                Charket__Message__c = ex.getMessage(),
                Charket__Data__c = 'Case Number' + caseNumber
            ));
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket Team
     *  @description Format the Form inputs to save in the Case description.
     **/
    private static String getFormatContactInfo(
        String firstname,
        String lastname,
        String email,
        String mobile,
        String companyName,
        String contactMethod,
        Id followerId,
        String productSerialNumber
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'getFormatContactInfo');
        String contactInfo = '';
        contactInfo += 'First Name: ' + firstname + '\n';
        contactInfo += 'Last Name: ' + lastname + '\n';
        contactInfo += 'Email: ' + email + '\n';
        contactInfo += 'Phone: ' + mobile + '\n';
        contactInfo += 'Company: ' + companyName + '\n';
        contactInfo +=
            'Product Serial Number: ' + (productSerialNumber != null ? productSerialNumber : '');
        ilib_LogEvent.info('Contact Info' + contactInfo);
        ilib_LogEvent.pop();
        return contactInfo;
    }

    /**
     *  @author  Charket Team
     *  @description Try to match a Contact based on the Form input
     **/
    private static Contact getMatchedContact(String email, String productSerialCode) {
        ilib_LogEvent.push(LOG_TITLE + 'getMatchedContact');
        Contact matchedContact = null;
        Boolean isProductNotFoundOrCodeIsEmpty = true;
        ilib_LogEvent.info('Product Serial Code' + productSerialCode);
        
        //If a product serial number is provided, search for Installed Product Record
        if (String.isNotBlank(productSerialCode)) {
            List<SVMXC__Installed_Product__c> thisInstalledProducts = new CharketSelector().selectInstalledProductBySerialLotNumber(productSerialCode);
            ilib_LogEvent.message('Installed Products: ' + thisInstalledProducts);
            
            //If an installed product record is found, search for a Contact related to the installed product's record and have a matching email address
            if (thisInstalledProducts.size() > 0) {
                isProductNotFoundOrCodeIsEmpty = false;
                String matchedContactId;
                
                List<AccountContactRelation> accountContactRelations = new CharketSelector().selectAccountContactRelationByEmail(thisInstalledProducts[0].SVMXC__Company__c, email);
                
                if (accountContactRelations.size() > 0) {
                    matchedContactId = accountContactRelations[0].ContactId;
                } else {
                    accountContactRelations = new CharketSelector().selectAccountContactRelationByAlternateEmail(thisInstalledProducts[0].SVMXC__Company__c, email);
                    if (accountContactRelations.size() > 0) {
                        matchedContactId = accountContactRelations[0].ContactId;
                    }
                }

                if (String.isNotBlank(matchedContactId)) {
                    matchedContact = new CharketSelector().selectContactById(matchedContactId)[0];
                }
            }
        }
        //If no Contacts was found, try searching for an active Contact with the same email address
        
        if (isProductNotFoundOrCodeIsEmpty) {
            List<Contact> contacts = new CharketSelector().selectContactByEmail(email);
            if (contacts.size() > 0) {
                matchedContact = contacts[0];
            } else {
                contacts = new CharketSelector().selectContactByAlternateEmail(email);
                if (contacts.size() > 0) {
                    matchedContact = contacts[0];
                }
            }
        }
        ilib_LogEvent.info('Matched Contact: ' + matchedContact);
        ilib_LogEvent.pop();
        return matchedContact;
    }

    /**
     *  @author  Charket Team
     *  @description update the Data Privacy Policy Consent Date
     **/
    @RemoteAction
    public static String updateFollowerDataPrivacyPolicyConsentDate(String openId) {
        ilib_LogEvent.push(LOG_TITLE + 'updateFollowerDataPrivacyPolicyConsentDate');
        ilib_LogEvent.info('Open Id: ' + openId);
        SaveResult result = new SaveResult();
        try {
            Charket__WeChatFollower__c follower = CharketCustomUtil.getFollower(openId);
            ilib_LogEvent.info('Follower: ' + follower);
            if(follower != null)//INC0459759
                follower.DataPrivacyPolicyConsentDate__c = Datetime.now();
            
            update follower;
            result.status = 1;
            result.message = 'success';
        } catch (Exception ex) {
            result.status = 0;
            result.message = ex.getMessage();
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketDataPrivacyConsentController.createNewCase',
                Charket__Message__c = ex.getMessage(),
                Charket__Data__c = 'openId' + openId
            ));
            ilib_LogEvent.info('Exception-->' + ex.getMessage());
            ApexExceptions.emit('WeChatCaseCreationError', ex);
        }
        ilib_LogEvent.pop();
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
     *  @description Inner class to display the WeChat Follower's information on the page
     **/
    global class FollowerInfo {
        /*
         * Constructor
         */
        public FollowerInfo(Charket__WeChatFollower__c follower) {
            this.FollowerId = follower.Id;
            this.WechatAccountId = follower.Charket__WeChatAccount__c;
            this.Firstname = follower.Firstname__c;
            this.LastName = follower.Lastname__c;
            this.Email = follower.Email__c;
            this.Mobile = follower.Mobile__c;
            this.CompanyName = follower.CompanyName__c;
        }

        public String FollowerId { get; set; }
        public String WechatAccountId { get; set; }
        public String Firstname { get; set; }
        public String LastName { get; set; }
        public String Email { get; set; }
        public String Mobile { get; set; }
        public String CompanyName { get; set; }
    }

    /**
     *  @author  Charket Team
     *  @description Inner class to display related open Cases to WeChat Follower who has email address verified and related to a Contact record.
     **/
    global class HistoryCaseItem {
        /*
         * Constructor
         */
        public HistoryCaseItem(
            String caseId,
            String caseNumber,
            String subject,
            String description,
            String createdDate,
            String status,
            String productSerialNumber
        ) {
            this.caseId = caseId;
            this.caseNumber = caseNumber;
            this.subject = subject;
            this.description = description;
            this.createdDate = createdDate;
            this.status = status;
            if (this.status == 'Awaiting Response - Internal') {
                this.status = 'In Progress';
            }
            this.productSerialNumber = productSerialNumber;
        }

        public String caseNumber { get; set; }
        public String subject { get; set; }
        public String status { get; set; }
        public String createdDate { get; set; }
        public String description { get; set; }
        public String caseId { get; set; }
        public String productSerialNumber { get; set; }
    }

    /**
     *  @author  Charket Team
     *  @description Inner class to retrieve configuration data stored in Custom Medatadata Type
     **/
    global class CharketSetting {
        /*
         * Constructor
         */
        public CharketSetting(CharketSettings__mdt thisCharketSettings) {
            this.replyToEmailAddress = thisCharketSettings.ReplyToEmailAddress__c;
            this.senderDisplayName = thisCharketSettings.SenderDisplayName__c;
            this.qrCodeImageName = thisCharketSettings.QRCodeImageName__c;
        }

        public String replyToEmailAddress { get; set; }
        public String senderDisplayName { get; set; }
        public String qrCodeImageName { get; set; }
    }
}