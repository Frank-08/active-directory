param([Parameter(Mandatory=$true)] $JSONFile)

function CreateADGroup () {
    param( [Parameter(Mandatory=$true)] $groupObject )

    $name - $groupObject.name
    New-ADGroup -name $group_name -GroupScope Global
}
function CreateADUser() {
    param( [Parameter(Mandatory=$true)] $userObject )
    
    #Pull info from JSON
    $name = $userObject.name
    $password = $userObject.password
    $domain = 319b.local
    
    
    #create FirstInitial lastname
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname.tolower())
    $samAccountName = $username
    $principalname = $username

    # Boom! create account
    New-ADUser -name "$name" -givenname $firstname -surname $lastname -SamAccoutName $samAccountName -userPrincipalName $principalname@$Global:Domain -accoutpasssword (ConvertTo-SecureString $password -AsPlainText -Force) -passthru | Enable-account

    #add user to group
    foreach($group in $userObject.groups) {
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

$json  = (Get-Content $JSONFile | ConvertFrom-Json )

$Global:Domain = $json.domain

foreach ($group in $json.groups) {
    CreateADUser $group
}

foreach ($user in $json.users) {
    CreateADUser $user
}
#echo $json.users