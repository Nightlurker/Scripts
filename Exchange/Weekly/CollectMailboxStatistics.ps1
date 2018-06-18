# 2. Run the following command to check store usage on database basis:
#        Get-StoreUsageStatistics -Database <DatabaseIdParameter>
# 3. Run the following command to check store usage on all databases:
#        Get-MailboxDatabase | Get-StoreUsageStatistics
# 4. Run the following command to check mailbox statistics on mailbox basis and server basis
#        Get-MailboxStatistics -Identity <Domain\User>
#        Get-MailboxStatistics -Server <ServerName>
# 5. Run the following command to check mailbox statistics for all mailboxes
#        Get-MailboxServer | Get-MailboxStatistics