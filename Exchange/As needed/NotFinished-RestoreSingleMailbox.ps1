# 2. If a recovery database does not already exist, you can create one by running the following Exchange Management Shell command:
#    New-MailboxDatabase -Recovery -Name <RDB Name> -Server <Server Name> -EdbFilePath "C:\Recovery\RDB\<Databasename>.EDB" -LogFolderPath "C:\Recovery\RDB"
# 3. To mount the recovery database, run the following Exchange Management Shell command:
#    mount-database -identity <ServerName>\<Database Name>
# 4. To recover the mailbox from the restore database,verify that the user mailbox is listed by running the following command:
#    Get-MailboxStatistics –Database “RecoveryDatabaseName”
# 5. Make sure that the database and log files containing the recovered data are restored or copied into the RDB folder structure that was created when the RDB was created.
# 6. Make sure that the database is in a clean shutdown state. Because an RDB is an alternate restore location for all databases, all restored databases will be in a dirty shutdown state. You can use Eseutil /R to put the database in a clean shutdown state.
# 7. To recover the mailbox of an existing user to an existing mailbox, run the following Exchange Management Shell command:
#    New-MailboxRestoreRequest -SourceDatabase <DatabaseIdParameter> -SourceStoreMailbox <StoreMailboxIdParameter> -TargetMailbox <MailboxOrMailUserIdParameter> 
#    e.g. New-MaiboxRestoreRequest -SourceDatabase DB1 -SourceStoreMailbox "Scott Schnoll" -TargetMailbox scott@contoso.com 
