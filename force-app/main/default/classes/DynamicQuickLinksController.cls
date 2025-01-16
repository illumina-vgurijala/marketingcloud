/**
*    @author Prakhar Kumar
*    @date   2019-08-14
*    @description    DCP-28546: Partner PortalContent Selector
*    ------------------------------------------------------------- 
*                    
*/
public with sharing class DynamicQuickLinksController {
        // Fetches Records from  Partner portal Content where Active=true and Region ='' and Video URL =''
        @AuraEnabled(cacheable=true)
		
		/*
         * Constructor
         */
        public static List<DynamicQuickLinksWrapperClass> getDynamicQuickLinks(){
            List <DynamicQuickLinksWrapperClass> dynamicQuickLinksWrapperList = new List <DynamicQuickLinksWrapperClass>();        
            List<Partner_Portal_Content__c> lstPartnerPortal = new PartnerPortalContentSelector().selectActiveQuickLinks();                    
           
            for(Partner_Portal_Content__c pPListVar: lstPartnerPortal){
             DynamicQuickLinksWrapperClass instanceDynamicQuickLinksWrapperClass = new DynamicQuickLinksWrapperClass
             ( pPListVar.Active__c, pPListVar.Quick_Links_URL__c, pPListVar.Region__c, pPListVar.Video_URL__c, pPListVar.Quick_Links_Label__c );
             dynamicQuickLinksWrapperList .add(instanceDynamicQuickLinksWrapperClass);                   
            }
            system.debug('dynamicQuickLinksWrapperList ====='+dynamicQuickLinksWrapperList); 
            return dynamicQuickLinksWrapperList ;
        }
        
        // Fetches Records from  Partner portal Content where Active=true and Region ='' AND Video URL !=NULL
        @AuraEnabled(cacheable=true)

		/*
         * return - List<DynamicQuickLinksWrapperClass>
		 * description - getActiveVideoLink method
         */
        public static List<DynamicQuickLinksWrapperClass> getActiveVideoLink(){
            List <DynamicQuickLinksWrapperClass> dynamicQuickLinksWrapperList = new List <DynamicQuickLinksWrapperClass>();        
            List<Partner_Portal_Content__c> lstPartnerPortalVideo = new PartnerPortalContentSelector().selectActiveVideoLink();                    
           
            for(Partner_Portal_Content__c pPListVideoVar: lstPartnerPortalVideo){
             DynamicQuickLinksWrapperClass instanceDynamicQuickLinksWrapperClass = new DynamicQuickLinksWrapperClass
             ( pPListVideoVar.Active__c, pPListVideoVar.Quick_Links_URL__c, pPListVideoVar.Region__c, pPListVideoVar.Video_URL__c, pPListVideoVar.Quick_Links_Label__c );
             dynamicQuickLinksWrapperList .add(instanceDynamicQuickLinksWrapperClass);                   
            }
            system.debug('dynamicQuickLinksWrapperList ====='+dynamicQuickLinksWrapperList); 
            return dynamicQuickLinksWrapperList ;
        }
        
		/*
		 * description - DynamicQuickLinksWrapperClass method
         */         
        public class DynamicQuickLinksWrapperClass{
            @AuraEnabled 
            public Boolean Active{get;set;}
            @AuraEnabled 
            public String QuickLinkURL{get;set;}
            @AuraEnabled 
            public String Region{get;set;}
            @AuraEnabled 
            public String VideoURL{get;set;}
            @AuraEnabled 
            public String QuickLinksLabel{get;set;}

		/* 
        * @description: wrapper class constructor, used to intantiate required information related to  Quick Link
        * @params: Boolean,String,String,String,String
        */                      
            public DynamicQuickLinksWrapperClass(Boolean Active,String QuickLinkURL,String Region,String VideoURL,String QuickLinksLabel){
                this.Active=Active;
                this.QuickLinkURL=QuickLinkURL;
                this.Region=Region;
                this.VideoURL=VideoURL;
                this.QuickLinksLabel=QuickLinksLabel;
            }
                
        }

        /**
    *  @author Vinay
    *  @description Fetching URL's for Help in ICPP
    *  
    *  @return List of records in Partner_Portal_Content__c  
    **/
        @AuraEnabled(cacheable=true)
        public static List<Partner_Portal_Content__c> fetchMethod()
        {
             try{
                
                List <Partner_Portal_Content__c> temp=new PartnerPortalContentSelectorHelp().selectActiveHelpLinks();
                System.debug(temp);
                return temp;
                
            }catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }

        }
    }
