[CmdletBinding()] 
param( 
    [Parameter(Position=1,  Mandatory=$true)]  [string]$num_ticket
 ) 
."C:\Automacao\Ps\lib\Invoke-SqlPlus.ps1"
function Invoke-ORACLE {
    param(
        [Parameter(Position=1, Mandatory=$true)] [string] $dataSource,
        [Parameter(Position=2, Mandatory=$false)] [string]$Username, 
        [Parameter(Position=3, Mandatory=$false)] [string]$Password, 
        [Parameter(Position=4, Mandatory=$true)] [string] $sqlCommand
      )

    if ($Username.Length -eq 0) {
        $Username = $psParams.oraUser
        $pwd = Get-Content $psParams.oraPwdFile | ConvertTo-SecureString
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))
    }

    try {
        [Reflection.Assembly]::LoadFile('C:\oracle\fullclientbase_12\fullclienthome_12\ODP.NET\bin\2.x\Oracle.DataAccess.dll') | Out-Null    

        $connectionString = "User ID=$Username;Password=$Password;Data Source=$dataSource;Persist Security Info=True"

        $connection = new-object Oracle.DataAccess.Client.OracleConnection($connectionString)
        $connection.Open()

        $command = new-object Oracle.DataAccess.Client.OracleCommand($sqlCommand,$connection)

        $adapter = New-Object Oracle.DataAccess.Client.OracleDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null

        $dataSet.Tables[0]
    } catch {
        Throw $_.Exception.Message

    } finally {
        $adapter.Dispose()
        $command.Dispose()
    
        $connection.Close()
    }
}

."C:\Automacao\Ps\lib\Invoke-encrypt.ps1"

function criaUsuarioBD($DbInstance, $userName, $Password) {
    # Cria e concede os acessos ao usuario de conexao, quando necessario
    try {
        $usr = $psParams.oraUserAuto
        $pwd = decrypt $usr

        $QueryUser = "set feedback off;
        set timing off;
        set define on;
        @c:\Automacao\Ps\sql\cria-usuario-$userName.sql $Password "
        
        $Output = Invoke-SqlPlus -DbInstance $DbInstance -Schema $usr -Query $QueryUser -EchoOff -Username $usr -Password $pwd
    }
    catch [Exception]{
        Write-Host "Aviso: Erro encontrado ao tentar validar o usuario de execucao do script no banco de dados $DbInstance, se a execucao apresentar erro entre em contato com a xxxx."
    }
}

$Erro = @()

$QueryOracle =

 "SELECT d.name, o.owner, o.object_name
FROM dba_objects o, v`$database  d
WHERE o.object_type = 'VIEW' AND o.status = 'INVALID' 
AND o.owner like 'xx%' 
AND o.owner <> 'xxxxx' 
AND d.name like '%xxxx'

UNION

SELECT d.name, o.owner, o.object_name
FROM dba_objects o, v`$database  d
WHERE o.object_type = 'VIEW' AND o.status = 'INVALID' 
AND o.owner like 'x%'
AND d.name like '%xxx'  
ORDER BY 1,2,3"

try {

    $Username = $psParams.oraUserExpdp
    $Password = decrypt $Username

    # Recupera view inválidas de todas as instancias
    try {
        $instancias = @("Dxxxx","Pxxxxx","Hxxxxx","Txxxxx","Dxxxx","Pxxxxx","Hxxxxxx","Txxxxxx")

        foreach ($i in $instancias) {

            # Cria o usuario do banco de dados
            try {
                criaUsuarioBD $i $Username $Password
            } catch {
                Throw "Nao foi possivel recuperar/criar o usuario da automacao ($i)."
            }

            $Result = Invoke-Oracle $i $Username $Password $QueryOracle
            $ResultTotal += $Result 
        }
    } catch {
        Throw "Nao foi possivel recuperar as views invalidas."
    }

    #TODO: Recompilar views
    try{
        foreach ($row in $ResultTotal){    
            $MensagemError = ''
            $QueryOracleRow =  "ALTER VIEW $($row.owner).$($row.object_name) COMPILE";
            try {
                $Result = Invoke-ORACLE $row.name $Username $Password $QueryOracleRow   
            } catch {
                Write-Host "Nao foi possivel recompilar a view $($row.owner).$($row.object_name)"
            }
        }
    } catch {
        Throw "Nao foi possivel recompilar views."
      }

    #Recuperar o texto ERRO das views que AINDA estao invalidas
    try{
        foreach ($row in $ResultTotal){
    
            $MensagemError = ''
            $QueryOracleRow =  "select e.text from DBA_ERRORS e, DBA_OBJECTS o where e.owner = '$($row.owner)' AND e.NAME = '$($row.object_name)' and e.owner = o.owner and e.name = o.object_name and o.status = 'INVALID' ";
            
            try {
                $Result = Invoke-ORACLE $row.name $Username $Password $QueryOracleRow
            } catch {
                Throw "Nao possivel recuperar o texto de erro da view $($row.owner).$($row.object_name)"
            }
   
            $MensagemError = $Result.text
        
            $irheader = [ordered] @{
                'Banco'=$row.name 
                'Owner'= $row.owner 
                'View' = $row.object_name 
                'Motivo' = $MensagemError} 
        
        
            $Erro+= New-Object -type PSObject -prop $irheader
        
        }
    } catch {
        Write-host $_.Exception.Message
        Throw "Nao foi possivel recuperar o texto do erro da view invalida."
      }
    # Enviar email com Banco, Proprietario, View, Motivo
    try { 
        $conteudo = $Erro | Sort-Object -Property 'Banco' | Format-Table -Property @{e='Banco'; width = 9},@{e='Owner'; width = 8}, @{e='View'; width = 31}, @{e='Motivo'; width = 100}  | Out-String -Width 250
        Send-MailMessage -From xxxxxxx -Body $conteudo -Subject "Views Invalidas em cada Instancia" -To xxxxxx -SmtpServer xxxxxx -Attachments $Erro
        $conteudo
    } catch {
        Throw "Nao foi possivel enviar o email com as views invalidas e o motivo."
      }
} catch {
    Write-Host "`n"
    Write-host $_.Exception.Message
    Write-Host "`nErro ao listar/recompilar views."
    Exit 1
}

       