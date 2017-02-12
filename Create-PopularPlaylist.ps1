
##TO DO
##Make into module
##Create parameter that accepts a filepath for a list of artists
##Create parameter that accepts a number for number of songs per artist to include in playlist
##Fix user access token retrieval to be less hacky

#Change this variable to your Spotify clientID/API token
$clientid = <Spotify API client ID here>

#Chnage this variable to a file path containing a list of artists
#For example: C:\Temp\artistlist.txt
#Comment out this line to be prompted for a single artist
$ArtistList = <File Path to list of Artists here>

#Request URI to a rave gif using my token to grab your access token (it will be shown in the URL)
$AuthUri = "https://accounts.spotify.com/en/authorize?" +
           "client_id=$clientid" +                                                                                    
           "&redirect_uri=https://media.giphy.com/media/9YlhdI9SSP0Qw/giphy.gif" +         
           "&scope=playlist-modify-public playlist-modify-private playlist-read-private playlist-read-collaborative" +
           "&response_type=token"

#Create a form based browser object to navigate to the rave gif
Add-Type -AssemblyName System.Windows.Forms
$FormProperties = @{
    Size = New-Object System.Drawing.Size(850, 675)
    StartPosition = "CenterScreen"
}
$Form = New-Object System.Windows.Forms.Form -Property $FormProperties
$BrowserProperties = @{
    Dock = "Fill"
}
$Browser = New-Object System.Windows.Forms.WebBrowser -Property $BrowserProperties
$Form.Controls.Add($Browser)
$Browser.Navigate($AuthUri)
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()

#RegEx to grab your access token from the URI generated by accessing the rave gif
if ($Browser.url.Fragment -match "access_token=(.*)&token") 
    {
        $AccessToken = $Matches[1]
    }

$UserUri = "https://api.spotify.com/v1/me"
$BearerToken = "Bearer $AccessToken"
$HeaderValue = @{Authorization = $BearerToken}
$UserAccount = (Invoke-RestMethod -Uri $UserUri -Method Get -ContentType application\json -Headers $HeaderValue).href


#Build the Playlist, get the playlist ID
$PlaylistUri = $UserAccount + "/playlists"
$PlaylistName = Read-Host "Give the playlist a name:"
if (!$ArtistList)
    {
        $ArtistList = Read-Host "Enter an artist name:"
    }
if (!$ArtistList)
    {
        $ArtistPrompt = Read-Host "PLEASE enter an artist name:"
    }
if (!$PlaylistName)
    {
        $PlayListName = Read-Host "Name the playlist. Now. This is not an option:"
    }
$NewPlaylist = @{
    name = $PlayListName
    public = "true"
} | ConvertTo-Json

$PlaylistID = Invoke-RestMethod -Uri $PlaylistUri -Method Post -ContentType application/json -Headers $HeaderValue -Body $NewplayList

$AllArtistIDs = @()
foreach ($Artist in $ArtistList)
    {
        $Artist = $Artist.Replace(" ","+")
        $ArtistUri = "https://api.spotify.com/v1/search?q=" + $Artist + "&type=artist&limit=1"
        $ArtistID = (Invoke-RestMethod -Uri $ArtistUri).artists.items.id
        $AllArtistIDs += $ArtistID
    }


$Songs = @()
foreach ($ArtistID in $AllArtistIDs)
    {
        $TopTracksUri = "https://api.spotify.com/v1/artists/" + $ArtistID + "/top-tracks?country=US"
        $TopTracks = (Invoke-RestMethod -Uri $TopTracksUri -ContentType Application/json).tracks.uri
        if($TopTracks -ne $null)
        {
            $Songs += $AllCombinedTopTracks
            $AllCombinedTopTracks = $TopTracks -join ','
            $AddTrackUri = $UserAccount + "/playlists/" + $PlaylistID.id + "/tracks?position=0&uris=$AllCombinedTopTracks"
            Invoke-RestMethod -Uri $AddTrackUri -Method Post -ContentType application/json -Headers $HeaderValue
            Start-Sleep 1
        }
    }


$Final = Write-Host "All done! Check your Spotify playlists!"
