public with sharing class LeaveApplicationController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getLeaveTypes() {
        List<Leave_Type__mdt> leaveTypes = [SELECT Leave_Type__c FROM Leave_Type__mdt];
        List<String> types = new List<String>();
        for (Leave_Type__mdt type : leaveTypes) {
            types.add(type.Leave_Type__c);
        }
        return types;
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getVacationBalance() {
        User currentUser = [SELECT Vacation_Balance__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return currentUser.Vacation_Balance__c;
    }

    @AuraEnabled
    public static void createLeaveApplication(String employeeId, Date startDate, Date endDate, String typeOfLeave, String reason) {
        User currentUser = [SELECT ManagerId FROM User WHERE Id = :employeeId LIMIT 1];
        
        Leave_Application__c leaveApp = new Leave_Application__c();
        leaveApp.Employee__c = employeeId;
        leaveApp.Manager__c = currentUser.ManagerId;
        leaveApp.Start_Date__c = startDate;
        leaveApp.End_Date__c = endDate;
        leaveApp.Type_of_Leave__c = typeOfLeave;
        leaveApp.Status__c = 'Draft';
        insert leaveApp;
    }
}