param(
    [Parameter(Mandatory=$true)] $JSONFile,
[int]$UserCount,
[int]$GroupCount,
[int]$LocalAdminCount
)

$group_names = [System.Collections.ArrayList](Get-Content "data/group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data/first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data/last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data/passwords.txt")

$groups = @()
$users = @()


#IF not stated when called default is here
if ($UserCount -eq 0 ){
    $UserCount = 5
}

if ($GroupCount -eq 0 ){
    $GroupCount = 1
}

if ($LocalAdminCount -ne 0){
    $local_admin_indexes = @()
    while(($local_admin_indexes | Measure-Object ).Count -lt $LocalAdminCount){
        $random_index = (Get-Random -InputObject (0..($UserCount-1)) | Where-Object { $local_admin_indexes -notcontains $_ })
        $local_admin_indexes += @( $random_index )
    }
}

echo $local_admin_indexes
exit

#GROUPS
    for ( $i =0; $i -lt $GroupCount; $i++ ){
    $new_group = (Get-Random -InputObject $group_names)
    $group = @{ "name" = "$new_group"}
    $groups += $group
    $group_names.Remove($new_group)
    }

#Users

    for ( $i =0; $i -lt $UserCount; $i++ ){
    $first_name = (Get-Random -InputObject $first_names)
    $last_name = (Get-Random -InputObject $last_names)
    $password = (Get-Random -InputObject $passwords)
    $new_user = @{
        "name" = "$first_name $last_name"
        "password" = "$password"
        "groups" = @((Get-Random -InputObject $groups).name)
    }
    $users += $new_user

  #Remove used values
    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
    }

@{
    "domain"= "319b.local"
   "groups"= $groups
    "users" = $users
    } | ConvertTo-Json | Out-File $JSONOut