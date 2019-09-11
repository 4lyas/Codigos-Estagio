-- Gera um Script SQL [FACT]

$outputFile = "XX"

$files = Get-ChildItem "XX"
 
Write-Output "use XX`nGO" | Out-File $outputFile

foreach ($f in $files){
    
    $outfile = $f.FullName
    $base = $f.name
    $baseFull = $f.FullName
    $basereplace= $f.Name -Replace '\.','_'
    
    Write-Output ":setvar $basereplace ""$baseFull""`nGO"  | Out-File $outputFile -Append
    Write-Output "Print '$basereplace = `$($basereplace)'`nGO" | Out-File $outputFile -Append

    # Recuperar os diretorios filhos
    $filhos = Get-ChildItem $outfile -Recurse
    foreach ($i in $filhos){
   
        if ($i.Mode -ne "d----"){
            $item= $i.FullName -replace " ","_"
            Rename-Item $i.FullName -NewName $item
            $endpath = $item.Replace($baseFull,"")
            $endsql = Split-Path $item -leaf
            Write-Output "Print 'Executando $endsql'`nGO"  | Out-File $outputFile -Append
            Write-Output ":r `$($basereplace)$endpath`nGO" | Out-File $outputFile -Append
             
                 
        }
    }
}

    





