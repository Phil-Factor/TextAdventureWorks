#set the directory in which your database should go. 
$TextFilePath='PyPathToTextAdventureworks' #the full path of the text database
if (!(Test-Path $TextFilePath)) #check that the directory exists!
    {
    Write-Error "Can't find '$($TextFilePath)'.  Sorry, can't proceed because of this"
    exit
    }

try {
$Query = New-Object system.data.odbc.odbccommand #Represents an SQL statement to execute against the data source.
$Connection = New-Object system.data.odbc.odbcconnection #Represents a connection to a data source. 
$Connection.ConnectionString='Driver={Microsoft Access Text Driver (*.txt, *.csv)};DBQ='+$TextFilePath+'' 
$Query.Connection = $connection #assign the connection to the query
$Connection.Open() #open the connection
#now let's assign a SQL Statement to the open command 
$Query.CommandText = @'
SELECT p1.ProductModelID
FROM [Production_Product#csv] AS p1
GROUP BY p1.ProductModelID
HAVING MAX(p1.ListPrice) >= ALL
 (SELECT AVG(p2.ListPrice)
 FROM [Production_Product#csv] AS p2
 WHERE p1.ProductModelID = p2.ProductModelID) 

'@

 
}
catch
{
    $ex = $_.Exception
    Write-Error "$ex"
    exit
}

try { 
#now we execute the query and bring the data back 
$Reader = $Query.ExecuteReader([System.Data.CommandBehavior]::SequentialAccess) #get the datareader and just get the result in one gulp
}
catch
{
    $ex = $_.Exception
    Write-Error "whilst executing the query '$($Query.CommandText)' $ex.Message Sorry, but we can't proceed because of this!"
    $Reader.Close()
    $Connection.Close()
    Exit;
}
#lets now save it as an array of objects and display it 
Try
{
$Counter = $Reader.FieldCount #get it just once
$result=@() #initialise the empty array of rows
   while ($Reader.Read()) {
            $Tuple = New-Object -TypeName 'System.Management.Automation.PSObject'
            foreach ($i in (0..($Counter - 1))) {
              Add-Member `
                -InputObject $Tuple `
                -MemberType NoteProperty `
                -Name $Reader.GetName($i) `
                -Value $Reader.GetValue($i).ToString()
                }
		$Result+=$Tuple
 		}
  $result | Format-Table 
  }
catch
{
    $ex = $_.Exception
    Write-Error "whilst reading the data from the datatable. $ex.Message"
}
$Reader.Close()
$Connection.Close()