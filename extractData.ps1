
$server = "http://localhost:7474/db/data/transaction/commit"
$pass = ConvertTo-SecureString "YOURLEETPASS" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ('neo4j', $pass)


function doReq($query) {
    $response = Invoke-WebRequest -Uri $server -Method POST -Body $query -credential $creds -ContentType "application/json"
    return $response.RawContent
}

function countReachableHighTargets($user) {
    $query=' { "statements" : [ { "statement" : " MATCH (m:User {objectid: \"'+$user+'\"}),(n {highvalue:true}),p=shortestPath((m)-[r*1..]->(n)) WHERE NONE (r IN relationships(p) WHERE type(r)= \"GetChanges\") AND NONE (r in relationships(p) WHERE type(r)=\"GetChangesAll\") AND NOT m=n RETURN p "} ]}'	
    $results = doReq($query)
    $count = 0
    foreach($result in $results.split('"')) {
        if($result -like "row") {
            $count++
        }  
    }
    return $count
}

function getEnabledUsers($domain) {
    $query=' { "statements" : [ { "statement" : " MATCH (n:User) WHERE n.enabled=true AND n.domain=\"'+$domain+'\" RETURN n.objectid "} ]}'	
    $results = doReq($query)
    $results
}

# just to speed up things, we are reading users directly from file
$users = get-content "$PSScriptRoot\export.csv"
$total = $users.split("\n").Count
foreach($user in $users.split("\n")) {
    write-host "[#] {$total} Getting info for $user" -ForegroundColor Gray
    $count = 0
    $count = countReachableHighTargets($user)
    add-content "$PSScriptRoot\output-hightargets.csv" "$user;$count" 
    write-host "[!] $user - $count" -f Green
    $total--
}