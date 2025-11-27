global class AfterSandboxRefresh implements SandboxPostCopy {

    global void runApexClass(SandboxContext context) {
        List<Account> templateAccounts = [
            SELECT Name, BillingCity FROM Account WHERE Name LIKE 'Demo%'
        ];

        List<Account> newAccs = new List<Account>();
        for (Account a : templateAccounts) {
            newAccs.add(new Account(Name = a.Name, BillingCity = a.BillingCity));
        }

        insert newAccs;
    }
}