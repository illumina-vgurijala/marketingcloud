/**
 *    @author Charket
 *    @date   29-Mar-2024
 *    @description: Controller of the CharketCustomerCare page for gathering follower information via WeChat.                
 **/
global without sharing class CharketCustomerCareController {
    private static final String LOG_TITLE = 'CharketCustomerCareController';
    private static final String EMAIL_TEMPLATE_NAME = 'Charket_Verification_Code_Email_for_Customer_Care';
    private static final String CHINA_QUEUE_NAME = 'CS - GC - Customer Service';
    private static final String NUMBER_CHAR = '0123456789';
    private static String code;
    private String openId;
    private static Charket__WeChatAccount__c wechatAccount;
    public Boolean isWeChatBrowser { get; set; }
    public Boolean isValidWeChatUser { get; set; }
    public Boolean isContactVerified { get; set; }
    public Boolean isEmailVerified { get; set; }
    public Boolean isAcceptDataPrivacyPolicy { get; set; }
    public Follower follower { get; set; }
    public String displayMessage { get; set; }
    public String formSubmittedMessage { get; set; }
    public String privacyConsent { get; set; }

    /**
     *  @author  Charket
     *  @description Constructor method
     **/
    public CharketCustomerCareController() {
        isWeChatBrowser = false;
        isContactVerified = false;
        isEmailVerified = false;
        isAcceptDataPrivacyPolicy = false;
        isValidWeChatUser = false;
        formSubmittedMessage = System.Label.WeChatFormSubmittedMessage;
    }

    /**
     *  @author  Charket 
     *  @description Retrieve parameters and records needed
     **/
    public PageReference init() {
        ilib_LogEvent.push(LOG_TITLE + 'init');
        if (isValidBrowser()) {
            openId = getOpenId();
            
            if (String.isBlank(openId)) {
                String redirectURI;

                String orgDomain = URL.getOrgDomainURL().toExternalForm();
                if(orgDomain.contains('sandbox')){
                    redirectURI = orgDomain.replace('salesforce.com', 'salesforce-sites.com') + '/CharketCustomerCare?wid=' + wechatAccount.Id;
                } else {
                    redirectURI = 'https://illumina.customer.charket.com.cn/CharketCustomerCare?wid='  + wechatAccount.Id;
                }

                PageReference wechatoauth = new PageReference('https://open.weixin.qq.com/connect/oauth2/authorize?appid=&redirect_uri=&response_type=code&scope=snsapi_base&state=#wechat_redirect');
                wechatoauth.getParameters().put('appid', wechatAccount.Charket__AppId__c);
                wechatoauth.getParameters().put('redirect_uri', redirectURI);
                wechatoauth.setRedirect(true);
                ilib_LogEvent.pop();
                return wechatoauth;
            } else {
                ilib_LogEvent.info('Open Id: ' + openId);
                encryptOpenId(openId, wechatAccount);
                initWeChatFollower();
            }
        }

        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author Charket
     *  @description Init the follower information
     **/
    public void initWeChatFollower() {
        ilib_LogEvent.push(LOG_TITLE + 'initWeChatFollower');
        Charket__WeChatFollower__c wechatFollower = new CharketSelector().selectWeChatFollowerByOpenId(openId);

        if (wechatFollower == null){
            wechatFollower = new Charket__WeChatFollower__c(
                Charket__WeChatAccount__c = wechatAccount.Id,
                Charket__OpenId__c = openId,
                Charket__IsFollowing__c = false,
                Name = 'WeChat User'
            );
            upsert wechatFollower Charket__WeChatFollower__c.fields.Charket__OpenId__c;
        } else {
            isContactVerified = wechatFollower.IsContactVerified__c;
            isEmailVerified = wechatFollower.IsEmailVerified__c;
            if(isContactVerified) {
                displayMessage = System.Label.WeChatVerifiedMessage;
            } else if(isEmailVerified) {
                displayMessage = System.Label.WeChatWaitingMessage;
            }
            isAcceptDataPrivacyPolicy = wechatFollower.DataPrivacyPolicyConsentDate__c != null;
        }

        follower = new Follower(wechatFollower);
        isValidWeChatUser = true;
        ilib_LogEvent.info('Follower Id: ' + wechatFollower.Id);
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket
     *  @description Get the WeChat Follower's WeChat Open ID
     **/
    public String getOpenId() {
        ilib_LogEvent.push(LOG_TITLE + 'getOpenId');
        try {
            String cookieName = 'OPENID' + ((String)wechatAccount.Id).right(15);
            Cookie openIdCookie = ApexPages.currentPage().getCookies().get(cookieName);

            // Get open Id from cookie
            if (openIdCookie != null && String.isNotBlank(openIdCookie.getValue())) {
                return decryptOpenId(openIdCookie.getValue(), wechatAccount);
            } else if(String.isNotBlank(code)) {
                Charket.WeChatClient client = new Charket.WeChatClient(wechatAccount.Id);
                Charket.WeChatApiOAuth oauth = client.getOAuth();
                Charket.WeChatApiOAuth.AuthTokenResponse response = oauth.handleCallback(
                    code,
                    ''
                );
                ApexPages.currentPage().getParameters().put('code', '');
                ilib_LogEvent.info('Open Id' + response.OpenId);
                ilib_LogEvent.pop();
                return response.OpenId;
            }
        } catch (Exception ex) {
            return null;
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket
     *  @description check if it's a valid browser
     **/
    public Boolean isValidBrowser() {
        ilib_LogEvent.push(LOG_TITLE + 'isValidBrowser');
        Map<String, String> params = ApexPages.currentPage().getParameters();
        code = params.get('code');
        String wechatAccountId = params.get('wid');

        if (String.isNotBlank(wechatAccountId) && wechatAccountId instanceof Id) {
            wechatAccount = new CharketSelector().selectWeChatAccountsById(wechatAccountId)[0];
            privacyConsent = wechatAccountId;

            String userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
            isWeChatBrowser = String.isNotBlank(userAgent) && userAgent.containsIgnoreCase('MicroMessenger');
            
            ilib_LogEvent.pop();
            return isWeChatBrowser && wechatAccount != null;
        }

        ilib_LogEvent.pop();
        return false;
    }

    /**
     *  @author  Charket
     *  @description Send a verification code to the email address inputted
     **/
    @RemoteAction
    public static String sendVerificationCode(
        String followerJson
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'sendVerificationCode');
        SaveResult result = new SaveResult();
        String randomCode = generateRandomCode(6);
        Follower follower = (CharketCustomerCareController.Follower)JSON.deserialize(followerJson, CharketCustomerCareController.Follower.class);
        Charket__WeChatFollower__c wechatFollower = new Charket__WeChatFollower__c(
            Id = follower.followerId,
            Email__c = follower.email,
            EmailVerificationCode__c = randomCode,
            EmailNotifiedTime__c = Datetime.now()
        );

        wechatFollower = setFollowerDetails(follower, wechatFollower);
        
        try {
            Boolean sendResult = sendEmail(randomCode, follower.email);
            
            if (sendResult) {
                update wechatFollower;
                result.status = 1;
            } else {
                result.status = 0;
                result.message = '发送失败，请稍后再试';
            }
        } catch (Exception ex) {
            result.status = 0;
            result.message = '发送失败，请稍后再试';
            ilib_LogEvent.info('Exception' + ex.getMessage());
            ApexExceptions.emit('WeChatCustomerCareError', ex);
            createCharketLog(LOG_TITLE + '.sendVerificationCode', ex.getMessage(), String.valueOf(follower));
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket
     *  @description Submit the form
     **/
    @RemoteAction
    public static String submit(
        String followerJson
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'submit');
        Follower follower = (CharketCustomerCareController.Follower)JSON.deserialize(followerJson, CharketCustomerCareController.Follower.class);
        Charket__WeChatFollower__c wechatFollower = new CharketSelector().selectWeChatFollowerById(follower.followerId);
        ilib_LogEvent.message('Follower' + follower);
        SaveResult result = new SaveResult();
        try {
            Boolean isCodeCorrect = follower.emailVerificationCode == wechatFollower.EmailVerificationCode__c && follower.email == wechatFollower.Email__c;
            if (!isCodeCorrect) {
                result.status = 0;
                result.message = '邮箱验证码不匹配';
            } else {
                wechatFollower = setFollowerDetails(follower, wechatFollower);
                wechatFollower.IsEmailVerified__c = true;

                List<Contact> matchedContacts = getMatchedContacts(follower.email);
                Boolean matchedOneContact = matchedContacts.size() == 1;
                if (matchedOneContact) {
                    wechatFollower.Charket__Contact__c = matchedContacts[0].Id;
                    wechatFollower.IsContactVerified__c = true;
                } else {
                    createNewCase(follower, matchedContacts.size());
                }

                update wechatFollower;

                result.status = 1;
            }
        } catch (Exception ex) {
            result.status = 0;
            result.message = '提交失败，请稍后再试';
            ilib_LogEvent.info('Exception' + ex.getMessage());
            ApexExceptions.emit('WeChatCustomerCareError', ex);
            createCharketLog(LOG_TITLE + '.submit', ex.getMessage(), String.valueOf(follower));
        }
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket 
     *  @description Update the Data Privacy Policy Consent Date
     **/
    @RemoteAction
    public static String acceptPrivacyDate(String followerId) {
        ilib_LogEvent.push(LOG_TITLE + 'acceptPrivacyDate');
        ilib_LogEvent.info('FollowerId: ' + followerId);
        SaveResult result = new SaveResult();

        update new Charket__WeChatFollower__c(
            Id = followerId,
            DataPrivacyPolicyConsentDate__c = Datetime.now()
        );
        
        result.status = 1;
        ilib_LogEvent.pop();
        return JSON.serialize(result);
    }

    /**
     *  @author  Charket 
     *  @description Send an email verification code to the follower when they click the "Get Email Verification Code" button on the WeChat form.
     **/
    public static Boolean sendEmail(String code, String email) {
        ilib_LogEvent.push(LOG_TITLE + 'sendEmail');
        String replyToEmailAddress = System.Label.WeChatReplyToEmail;
        String senderDisplayName = System.Label.WeChatSenderDisplayName;
        Boolean sendResult = false;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<EmailTemplate> templates = new CharketSelector().selectEmailTemplateByName(EMAIL_TEMPLATE_NAME);

        if (templates.size() > 0) {
            String subject = templates[0].Subject;
            String body = (String.isNotBlank(templates[0].Body)
                ? (templates[0].Body.replace('{!verificationcode}', code))
                : '');
            String htmlValue = (String.isNotBlank(templates[0].HTMLValue)
                ? (templates[0].HTMLValue.replace('{!verificationcode}', code))
                : '');
            
            List<OrgWideEmailAddress> orgWideEmails = new CharketSelector().selectOrgWideEmailAddress(replyToEmailAddress);
            if (orgWideEmails.size() > 0) {
                mail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            } else {
                mail.setSenderDisplayName(senderDisplayName);
                mail.setReplyTo(replyToEmailAddress);
            }
            
            mail.setToAddresses(new List<String>{ email });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setHtmlBody(htmlValue);
            mail.setCharset('UTF-8');

            Messaging.SendEmailResult[] sendEmailResults = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
            sendResult = sendEmailResults[0].isSuccess();
            if (!sendResult) {
                String errorMessage = '';
                Messaging.SendEmailError[] sendErrors = sendEmailResults[0].getErrors();
                if (sendErrors != null && sendErrors.size() > 0) {
                    errorMessage = sendErrors[0].getMessage();
                    ilib_LogEvent.info('Exception' + errorMessage);
                    createCharketLog(LOG_TITLE + '.sendEmail', errorMessage, email);
                }
            }
        }
        ilib_LogEvent.pop();
        return sendResult;
    }

    /**
     *  @author  Charket 
     *  @description Decrypt the wechat open Id
     **/
    public String decryptOpenId(String encryptedOpenId, Charket__WeChatAccount__c wechatAccount) {
        ilib_LogEvent.push(LOG_TITLE + 'decryptOpenId');
        if (String.isNotBlank(encryptedOpenId) && wechatAccount != null) {
            try{
                String aesKey = wechatAccount.OpenIdAesKey__c;
                String algorithmName = 'AES' + wechatAccount.AesKeySize__c;
                Blob key = EncodingUtil.base64Decode(aesKey);
                Blob data = EncodingUtil.base64Decode(encryptedOpenId);
                Blob decrypted = Crypto.decryptWithManagedIV(algorithmName, key, data);
                
                ilib_LogEvent.pop();
                return decrypted.toString();
            } catch (Exception ex) {
                return null;
            }
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket 
     *  @description Encrypt the wechat open Id
     **/
    public String encryptOpenId(String openId, Charket__WeChatAccount__c wechatAccount) {
        ilib_LogEvent.push(LOG_TITLE + 'encryptOpenId');
        if (String.isNotBlank(openId) && wechatAccount != null) {
            try{
                String aesKey = wechatAccount.OpenIdAesKey__c;
                Integer aesKeySize = Integer.valueOf(wechatAccount.AesKeySize__c);
                String algorithmName = 'AES' + aesKeySize;
                if(String.isBlank(aesKey)){
                    aesKey = EncodingUtil.base64Encode(crypto.generateAesKey(aesKeySize));
                    wechatAccount.OpenIdAesKey__c = aesKey;
                    update wechatAccount;
                }
                Blob key = EncodingUtil.base64Decode(aesKey);
                Blob data = Blob.valueOf(openId);
                Blob encrypted = Crypto.encryptWithManagedIV(algorithmName, key, data);

                ilib_LogEvent.pop();
                String encryptOpenId = EncodingUtil.base64Encode(encrypted);
                if(encryptOpenId != null){
                    String cookieName = 'OPENID' + ((String)wechatAccount.Id).right(15);
                    Cookie openIdCookie = new Cookie(cookieName, encryptOpenId, null, 14400, true);
                    ApexPages.currentPage().setCookies(new List<Cookie>{ openIdCookie });
                }
                return encryptOpenId;
            } catch(Exception ex) {
                return null;
            }
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author  Charket
     *  @description Create a charket log record.
     **/
    public static void createCharketLog(String method, String message, String data){
        insert new Charket__Log__c(
            Charket__ApexCodeName__c = method,
            Charket__Message__c = message,
            Charket__Data__c = data
        );
    }

    /**
     *  @author  Charket 
     *  @description Generate a random email verification code
     **/
    private static String generateRandomCode(Integer len) {
        ilib_LogEvent.push(LOG_TITLE + 'generateRandomCode');
        
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), NUMBER_CHAR.length());
            randStr += NUMBER_CHAR.substring(idx, idx + 1);
        }
        ilib_LogEvent.pop();
        return randStr;
    }

    /**
     *  @author  Charket
     *  @description Create a new Case that origins from WeChat.
     **/
    private static void createNewCase(
        Follower follower, 
        Integer matchedContactSize
    ){
        Case newCase = new Case();
        newCase.Status = 'Initiated';
        newCase.Origin = 'WeChat - CS';
        newCase.Region__c = 'China';
        newCase.Sub_Type__c = 'General';
        newCase.Category__c = 'Question';
        newCase.SuppliedEmail = follower.email;
        newCase.WeChatFollower__c = follower.followerId;

        Boolean isMultipleMatch = matchedContactSize > 1;
        if(isMultipleMatch){
            newCase.Subject = 'WeChat User registration – multiple SFDC contact: ' + follower.email + '; ' + follower.companyName;
            newCase.Description = newCase.Subject + '.  Please validate user and link wechat user to appropriate contact.';
        } else {
            newCase.Subject = 'WeChat User registration – no SFDC contact: ' + follower.email + '; ' + follower.companyName;
            newCase.Description = newCase.Subject + '. Please validate user and create SFDC contact. Then link wechat user to contact.';
        }

        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Inquiry')
            .getRecordTypeId();
        newCase.OwnerId = new CharketSelector().selectGroupByName(CHINA_QUEUE_NAME)[0].Id;
        
        insert newCase;
    }

    /**
     *  @author  Charket 
     *  @description Set follower fields
     **/
    private static Charket__WeChatFollower__c setFollowerDetails(Follower follower, Charket__WeChatFollower__c wechatFollower) {
        ilib_LogEvent.push(LOG_TITLE + 'setFollowerFields');
        
        Boolean fieldsCompleted = follower.firstName != null && follower.lastName != null && follower.mobile != null && follower.companyName != null;
        if(fieldsCompleted){
            wechatFollower.Name = follower.lastName + ' ' + follower.firstName;
            wechatFollower.FirstName__c = follower.firstName;
            wechatFollower.LastName__c = follower.lastName;
            wechatFollower.Mobile__c = follower.mobile;
            wechatFollower.CompanyName__c = follower.companyName;
        }

        ilib_LogEvent.pop();
        return wechatFollower;
    }

    /**
     *  @author  Charket 
     *  @description get matched contacts by email
     **/
    private static List<Contact> getMatchedContacts(String email) {
        ilib_LogEvent.push(LOG_TITLE + 'getMatchedContacts');
        
        List<Contact> matchedContacts = new CharketSelector().selectContactByEmail(email);
        Boolean noMatched = matchedContacts.size() == 0;
        if (noMatched) {
            matchedContacts = new CharketSelector().selectContactByAlternateEmail(email);
        } 

        ilib_LogEvent.pop();
        return matchedContacts;
    }

    /**
     *  @author  Charket 
     *  @description Inner class for the save result
     **/
    global class SaveResult {
        public Integer status;
        public String message;
    }

    /**
     *  @author  Charket 
     *  @description Inner class to display the WeChat Follower's information on the page
     **/
    global class Follower {
        /*
         * Constructor
         */
        public Follower(Charket__WeChatFollower__c follower) {
            this.followerId = follower.Id;
            this.firstName = follower.FirstName__c;
            this.lastName = follower.Lastname__c;
            this.email = follower.Email__c;
            this.mobile = follower.Mobile__c;
            this.companyName = follower.CompanyName__c;
            this.emailVerificationCode = follower.EmailVerificationCode__c;
        }
        /*
         * Constructor
         */
        public Follower(){}

        public String followerId { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String email { get; set; }
        public String mobile { get; set; }
        public String companyName { get; set; }
        public String emailVerificationCode { get; set; }
    }
}