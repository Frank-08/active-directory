param(
    [Parameter(Mandatory=$true)] $JSONFile,
[switch]$undo
)

function CreateADGroup () {
    param( [Parameter(Mandatory=$true)] $groupObject )

    $group_name = $groupObject.name
    try {
        New-ADGroup -name $group_name -GroupScope Global
    }
    catch  [Microsoft.ActiveDirectory.Management.Commands.NewADGroup]{
       Write-Output "Group $group_name already exists!"
    }
    
}

function RemoveADGroup () {
    param( [Parameter(Mandatory=$true)] $groupObject )
    $group_name = $groupObject.name
        Remove-ADGroup -Identity $group_name -Confirm:$false
}


function CreateADUser() {
    param( [Parameter(Mandatory=$true)] $userObject )
    
    #Pull info from JSON
    $name = $userObject.name
    $password = $userObject.password
    $domain = "319b.local"
    #$group_name = $userObject.groups
    
    #create FirstInitial lastname
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).tolower()
    $samAccountName = $username
    $principalname = $username

    # Boom! create account
    New-ADUser -name "$name" -givenname $firstname -surname $lastname -SamAccountName $samAccountName -userPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -passthru | Enable-ADAccount

    Write-Output "User $name Created"

    #add user to group
    foreach($group_name in $userObject.groups) {
        try {
            get-ADGroup -Identity "$group_name"
            Add-ADGroupMember -Identity $group_name -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Output "No AD Group by that name!"
        }
    }
    #Write-Output $userObject
}


function RemoveADUser() {
    param( [Parameter(Mandatory=$true)] $userObject )

    #Pull info from JSON
    $name = $userObject.name
    #$group_name = $userObject.groups
    
    #create FirstInitial lastname
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).tolower()
    # $samAccountName = $username
    # $principalname = $username

    Remove-ADUser -Identity $username -Confirm:$false

}


function WeekenPasswordPolicy(){
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg  
    (Get-Content c:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\Windows\Tasks\secpol.cfg -confirm:$false
}


#MAIN

$json  = (Get-Content $JSONFile | ConvertFrom-Json )

$Global:Domain = $json.domain

if ( -not $undo) {
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $false -MinPasswordLength 1 -Identity $Global:Domain

foreach ($group in $json.groups) {
    CreateADGroup $group
}

foreach ($user in $json.users) {
    CreateADUser $user
}

}else {
    Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 7 -Identity $Global:Domain
    
    foreach ($user in $json.users) {
        RemoveADUser $user
    }
    
    foreach ($group in $json.groups) {
        RemoveADGroup $group
    }
}


