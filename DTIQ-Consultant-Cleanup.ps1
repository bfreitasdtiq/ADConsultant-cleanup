<#	
	.NOTES
	===========================================================================
	 Created on:   	04/05/2021 5:22 PM
     Updated on:	05/04/2021
	 Created by:   	Brysen Freitas
	 Organization: 	DTIQ
	 Filename:     	DTIQ-Consultant-cleanup
	===========================================================================
	.DESCRIPTION
		Used to clean up old inactive contractors accounts on AD OU OU=Consultants,OU=Users and Groups,OU=Administrative OU,DC=dttla,DC=com


#New-EventLog -LogName DTIQ-RemoteMan -Source DTIQ
#sc create "DTIQ-Consultant-cleanup" Displayname= "DTIQ-Consultant-cleanup" binpath= "C:\DTIQ\DTIQ-Consultant-cleanup.exe" start= auto 
#>


Import-Module ActiveDirectory
#Loop
do
{
#JSON CONFIG READ
$Settingsconclean = Get-Content -Path 'C:\dtiq\settings\DLD-Consulatant-cleanup.json' | ConvertFrom-Json

$inactiveDays = $Settingsconclean.inactivedays
$neverLoggedInDays = $Settingsconclean.inactivedays
$disableDaysInactive = (Get-Date).AddDays(-($inactiveDays))
$disableDaysNeverLoggedIn = (Get-Date).AddDays(-($neverLoggedInDays))

# Identify and disable users who have not logged in in x days

$disableUsers1 = Get-ADUser -SearchBase "OU=Consultants,OU=Users and Groups,OU=Administrative OU,DC=dttla,DC=com" -Filter { Enabled -eq $TRUE } -Properties lastLogonDate, whenCreated, distinguishedName | Where-Object { ($_.lastLogonDate -lt $disableDaysInactive) -and ($_.lastLogonDate -ne $NULL) }

$disableUsers1 | ForEach-Object {
	Disable-ADAccount $_
	Write-EventLog -log DTIQ-Remoteman -source DTIQ -EntryType Information -eventID 4001 -Message "Attempted to disable user $_ because the last login is in active"
}

# Identify and disable users who were created x days ago and never logged in.

$disableUsers2 = Get-ADUser -SearchBase "OU=Consultants,OU=Users and Groups,OU=Administrative OU,DC=dttla,DC=com" -Filter { Enabled -eq $TRUE } -Properties lastLogonDate, whenCreated, distinguishedName | Where-Object { ($_.whenCreated -lt $disableDaysNeverLoggedIn) -and (-not ($_.lastLogonDate -ne $NULL)) }

$disableUsers2 | ForEach-Object {
		Disable-ADAccount $_
		Write-EventLog -log DTIQ-Remoteman -source DTIQ -EntryType Information -eventID 4002 -Message "Attempted to disable user $_ because user has never logged in is inactive."
	}
	Start-Sleep -Seconds 86400
}
until ($infinity)
