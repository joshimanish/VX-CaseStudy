@RestResource(urlMapping='/leaveApplication/*')
global with sharing class LeaveApplicationService {

    @HttpGet
    global static List<Leave_Application__c> getLeaveApplications() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String email = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        System.debug('Received email from URL: ' + email);

        try {
            User user = [SELECT Id FROM User WHERE Email = :email LIMIT 1];
            if (user == null) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('User not found');
                return null;
            }

            Date today = Date.today();
            Date startOfYear = Date.newInstance(today.year(), 1, 1);
            Date endOfYear = Date.newInstance(today.year(), 12, 31);

            List<Leave_Application__c> leaveApplications = [
                                                        SELECT Id, Start_Date__c, End_Date__c, Type_of_Leave__c, Status__c
                                                        FROM Leave_Application__c
                                                        WHERE Employee__c = :user.Id 
                										AND Start_Date__c >= :startOfYear 
                										AND End_Date__c <= :endOfYear];

            res.statusCode = 200;
            return leaveApplications;
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error : ' + e.getMessage());
            return null;
        }
    }
}