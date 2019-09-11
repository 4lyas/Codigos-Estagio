# Faz a interface com o banco de dados via SQLClient .net
# Parametros Necessarios, SERVIDOR, BANCO DE DADOS E QUERY...

[CmdletBinding()] 
param( 
    [Parameter(Position=1, Mandatory=$true)]  [string] $servidor,
    [Parameter(Position=2, Mandatory=$true)]  [string] $baseDeDados,
    [Parameter(Position=3, Mandatory=$true)]  [string] $query
 )  
 [boolean] $sucesso_conexao = $False

function Invoke-SQL {
    param(
        [string] $dataSource =  $(throw "Please specify a server."),
        [string] $database = "master",
        [string] $sqlCommand = $(throw "Please specify a query."),
        [string] $user = "",
        [string] $password = " ",
        [boolean] $status_conexao = $False
      )

    $ConnectionString = "Data Source=$dataSource;Initial Catalog=$database;User id=$user;Password=$password"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $connection.Open()
    if ($connection.ServerVersion -ne $null){
    $status_conexao = $True}
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    return $status_conexao   
}

#Invoke-SQL -dataSource $OutdataSource -database $Outdatabase -sqlCommand $OutsqlCommand

if ((Invoke-SQL -dataSource $servidor -database $baseDeDados -sqlCommand $query) -eq $true -and $Error[0] -eq $null){
$sucesso_conexao = $true
Write-Host 0}
else {
$sucesso_conexao = $false
Write-Host 1}


$Error.Clear()

 

