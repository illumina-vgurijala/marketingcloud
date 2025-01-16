trigger AgreementLineStatusUpdateTrigger on Agreement_Line_Status_Update__e (after insert) {
    ilib_SObjectDomain.triggerHandler(AgreementLineStatusUpdates.class);
}