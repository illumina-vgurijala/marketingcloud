({
    acceptppmValue : function(component, event, helper) {
        helper.acceptppmValue(component, event);
    },
    validate : function(component, event, helper) {
        let args=event.getParam("arguments");
        if(args) {
            let strPpmVal=args.strPpmVal;
            let strProposalId=args.strProposalId;
            return helper.validate(component, strProposalId, strPpmVal);
        } else {
            return null;
        }
    }
})