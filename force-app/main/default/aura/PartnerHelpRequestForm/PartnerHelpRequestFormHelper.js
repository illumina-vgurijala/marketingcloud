({
	initComponent : function(component, event, helper) {
        helper.callServer(component,"c.fetchUserDetails",function(response){
            component.set("v.partnerRequest",{
                'First_Name__c' : response.FirstName,
				'Last_Name__c' : response.LastName,
                'City__c' : response.City,
                'Email__c' : response.Email,
                'Phone__c' : response.Phone,
                'How_Can_We_Help__c' : ''
            })
        })
	}
})