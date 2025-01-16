({
    ACCOUNT: 'Account',
    CCT_ACCOUNT_RELATIONSHIPNAME: 'Competitor_Data__r',
    CCT_OPPORTUNITY_RELATIONSHIPNAME: 'Competitive_Complementary_Technologies1__r',

    decodeAddressContext : function(myPageRef) {
        let base64Context = myPageRef.state.inContextOfRef;

        if (base64Context && base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }

        let addressableContext = JSON.parse(window.atob(base64Context));

        return addressableContext;
    },

    navigatePreviousPage : function(cmp) {
        const navService = cmp.find("navService");

        const pageReference = cmp.get("v.pageReference");

        const previousPage = this.decodeAddressContext(pageReference);

        navService.navigate(previousPage);
    },

    navigateToRecord : function(cmp, recordId) {
        const recordPage = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };

        const navService = cmp.find("navService");
        navService.navigate(recordPage);
    },

    navigateToCCTViewList : function(cmp, parentId, parentObjectName) {
        const viewlistPage = {
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: parentId,
                objectApiName: parentObjectName,
                relationshipApiName: this.getRelationshipName(parentObjectName),
                actionName: 'view'
            }
        };

        const navService = cmp.find("navService");
        navService.navigate(viewlistPage);
    },

    /**
     * Return Reation Name field depending of Context origin either Account or Opportunity
     * @returns 
     */
    getRelationshipName : function(parentObjectName) {
        return this.ACCOUNT === parentObjectName ? 
            this.CCT_ACCOUNT_RELATIONSHIPNAME : this.CCT_OPPORTUNITY_RELATIONSHIPNAME

    },

    isFromParentDetailPage : function(cmp) {
        const currentPageContext = cmp.get("v.pageReference");
        return currentPageContext && currentPageContext.type === 'standard__objectPage';
    },

    closeSubTab: function(cmp) {

        const workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo()
            .then(function(response) {
                const focusedTabId = response.tabId;
                console.log('focusedTabId:' +  focusedTabId);
                workspaceAPI.closeTab({tabId: focusedTabId});
        })
    },

    delayedRefresh : function(milliseconds){
        let ms = milliseconds || 500;
        window.setTimeout($A.getCallback(function(){
            $A.get('e.force:refreshView').fire();
        }),ms);
    },
})