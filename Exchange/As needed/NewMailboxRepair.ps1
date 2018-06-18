#2. Run following Command to detects and repairs all corruption types for all mailboxes on mailbox database :-
#New-MailboxRepairRequest -Database "DB Name" -CorruptionType ProvisionedFolder,SearchFolder,AggregateCounts,Folderview
#Example - New-MailboxRepairRequest -Database MBX-DB01 -CorruptionType ProvisionedFolder,SearchFolder,AggregateCounts,Folderview

#Run following Command to detects and repairs all corruption types for single mailbox :-
#New-MailboxRepairRequest -Mailbox "Mailbox Name" -CorruptionType ProvisionedFolder,SearchFolder,AggregateCounts,Folderview
# Example - New-MailboxRepairRequest -Mailbox ayla -CorruptionType ProvisionedFolder,SearchFolder,AggregateCounts,Folderview 